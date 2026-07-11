import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_repair/app/theme/app_theme.dart';
import 'package:nova_repair/app/widgets/table/app_table_shell.dart';
import 'package:nova_repair/database/app_database.dart';
import 'package:nova_repair/database/database_provider.dart';
import 'package:nova_repair/features/repairs/data/datasources/repair_code_sequence_local_data_source.dart';
import 'package:nova_repair/features/repairs/data/datasources/repair_local_data_source.dart';
import 'package:nova_repair/features/repairs/data/repositories/drift_repair_repository.dart';
import 'package:nova_repair/features/repairs/domain/entities/change_repair_status_input.dart';
import 'package:nova_repair/features/repairs/domain/entities/clear_repair_price_input.dart';
import 'package:nova_repair/features/repairs/domain/entities/create_repair_input.dart';
import 'package:nova_repair/features/repairs/domain/entities/create_warranty_return_input.dart';
import 'package:nova_repair/features/repairs/domain/entities/propose_repair_price_input.dart';
import 'package:nova_repair/features/repairs/domain/entities/record_customer_price_decision_input.dart';
import 'package:nova_repair/features/repairs/domain/entities/repair.dart';
import 'package:nova_repair/features/repairs/domain/entities/repair_attention_counts.dart';
import 'package:nova_repair/features/repairs/domain/entities/repair_search_query.dart';
import 'package:nova_repair/features/repairs/domain/entities/update_repair_input.dart';
import 'package:nova_repair/features/repairs/domain/repair_status.dart';
import 'package:nova_repair/features/repairs/domain/repositories/repair_repository.dart';
import 'package:nova_repair/features/repairs/presentation/repairs_list_controller.dart';
import 'package:nova_repair/features/repairs/presentation/repairs_list_state.dart';
import 'package:nova_repair/features/repairs/repair_providers.dart';
import 'package:nova_repair/features/repairs/repairs_page.dart';
import 'package:nova_repair/features/settings/data/datasources/shop_settings_local_data_source.dart';

void main() {
  late AppDatabase database;
  late DateTime now;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    now = DateTime.utc(2026, 7, 5, 12);
  });

  tearDown(() async {
    await database.close();
  });

  ProviderContainer container() {
    return ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
        repairsListClockProvider.overrideWithValue(() => now),
      ],
    );
  }

  Widget repairsApp({
    VoidCallback? onNewRepair,
    ValueChanged<Repair>? onRepairSelected,
  }) {
    return ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
        repairsListClockProvider.overrideWithValue(() => now),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: RepairsPage(
            onNewRepair: onNewRepair,
            onRepairSelected: onRepairSelected,
          ),
        ),
      ),
    );
  }

  group('RepairsListController', () {
    test('default query loads repairs newest first', () async {
      await _insertRepair(
        database,
        repairCode: 'REP-OLDER',
        status: RepairStatus.received,
        receivedAt: now.subtract(const Duration(days: 2)),
      );
      await _insertRepair(
        database,
        repairCode: 'REP-NEWER',
        status: RepairStatus.repairing,
        receivedAt: now.subtract(const Duration(hours: 2)),
      );

      final testContainer = container();
      addTearDown(testContainer.dispose);

      final state = await testContainer.read(
        repairsListControllerProvider.future,
      );

      expect(state.repairs.map((repair) => repair.repairCode), [
        'REP-NEWER',
        'REP-OLDER',
      ]);
      expect(state.sort, RepairSearchSort.newestFirst);
      expect(state.offset, 0);
    });

    test('search updates after debounce', () async {
      await _insertRepair(
        database,
        repairCode: 'REP-SEARCH',
        status: RepairStatus.received,
        customerName: 'Amina',
        receivedAt: now,
      );
      await _insertRepair(
        database,
        repairCode: 'REP-OTHER',
        status: RepairStatus.received,
        customerName: 'Yacine',
        receivedAt: now,
      );

      final testContainer = container();
      addTearDown(testContainer.dispose);
      await testContainer.read(repairsListControllerProvider.future);

      testContainer
          .read(repairsListControllerProvider.notifier)
          .updateSearchText('Amina');

      expect(
        testContainer.read(repairsListControllerProvider).asData?.value.repairs,
        hasLength(2),
      );

      await Future<void>.delayed(repairsSearchDebounceDuration * 2);

      final state = testContainer
          .read(repairsListControllerProvider)
          .asData!
          .value;
      expect(state.searchText, 'Amina');
      expect(state.repairs.single.repairCode, 'REP-SEARCH');
    });

    test('quick filters map to backend query behavior', () async {
      await _seedStatusSet(database, now);
      final testContainer = container();
      addTearDown(testContainer.dispose);
      await testContainer.read(repairsListControllerProvider.future);
      final controller = testContainer.read(
        repairsListControllerProvider.notifier,
      );

      await controller.applyQuickFilter(RepairsQuickFilter.active);
      expect(
        testContainer
            .read(repairsListControllerProvider)
            .asData!
            .value
            .repairs
            .every(
              (repair) =>
                  RepairSearchQuery.activeStatuses.contains(repair.status),
            ),
        isTrue,
      );

      await controller.applyQuickFilter(RepairsQuickFilter.waitingForApproval);
      expect(
        _singleStatus(testContainer),
        RepairStatus.waitingForCustomerApproval,
      );

      await controller.applyQuickFilter(RepairsQuickFilter.waitingForPart);
      expect(_singleStatus(testContainer), RepairStatus.waitingForPart);

      await controller.applyQuickFilter(RepairsQuickFilter.readyForPickup);
      expect(_singleStatus(testContainer), RepairStatus.readyForPickup);

      await controller.applyQuickFilter(RepairsQuickFilter.delivered);
      expect(_singleStatus(testContainer), RepairStatus.delivered);
    });

    test('status, date, lifecycle, sort, clear, and pagination work', () async {
      for (var index = 0; index < 21; index++) {
        await _insertRepair(
          database,
          repairCode: 'REP-${index.toString().padLeft(4, '0')}',
          status: index.isEven ? RepairStatus.received : RepairStatus.delivered,
          receivedAt: now.subtract(Duration(days: index)),
        );
      }

      final testContainer = container();
      addTearDown(testContainer.dispose);
      await testContainer.read(repairsListControllerProvider.future);
      final controller = testContainer.read(
        repairsListControllerProvider.notifier,
      );

      await controller.nextPage();
      var state = testContainer
          .read(repairsListControllerProvider)
          .asData!
          .value;
      expect(state.offset, repairsListPageSize);
      expect(state.repairs.single.repairCode, 'REP-0020');

      await controller.previousPage();
      state = testContainer.read(repairsListControllerProvider).asData!.value;
      expect(state.offset, 0);

      await controller.applyStatusFilter(RepairStatus.delivered);
      state = testContainer.read(repairsListControllerProvider).asData!.value;
      expect(state.offset, 0);
      expect(
        state.repairs.every(
          (repair) => repair.status == RepairStatus.delivered,
        ),
        isTrue,
      );

      await controller.applyDatePreset(RepairsDatePreset.today);
      state = testContainer.read(repairsListControllerProvider).asData!.value;
      expect(state.datePreset, RepairsDatePreset.today);
      expect(state.repairs, isEmpty);

      await controller.applyStatusFilter(null);
      await controller.applyDatePreset(RepairsDatePreset.all);
      await controller.applyLifecycleScope(RepairLifecycleScope.finalized);
      state = testContainer.read(repairsListControllerProvider).asData!.value;
      expect(state.lifecycleScope, RepairLifecycleScope.finalized);
      expect(
        state.repairs.every(
          (repair) => repair.status == RepairStatus.delivered,
        ),
        isTrue,
      );

      await controller.applySort(RepairSearchSort.oldestFirst);
      state = testContainer.read(repairsListControllerProvider).asData!.value;
      expect(state.sort, RepairSearchSort.oldestFirst);
      expect(state.repairs.first.repairCode, 'REP-0019');

      await controller.clearFilters();
      state = testContainer.read(repairsListControllerProvider).asData!.value;
      expect(state.hasActiveFilters, isFalse);
      expect(state.offset, 0);
      expect(state.sort, RepairSearchSort.newestFirst);
      expect(state.quickFilter, RepairsQuickFilter.all);
    });
  });

  group('RepairsPage UI', () {
    testWidgets('renders header, filters, quick chips, table, and real rows', (
      tester,
    ) async {
      _setDesktopSurface(tester);
      await _insertRepair(
        database,
        repairCode: 'REP-9001',
        status: RepairStatus.received,
        customerName: 'Lina',
        customerPhone: '0552 11 00 22',
        brand: 'MacBook',
        model: 'Air M2',
        receivedAt: now.subtract(const Duration(days: 16)),
      );
      await _insertRepair(
        database,
        repairCode: 'REP-9002',
        status: RepairStatus.waitingForPart,
        deviceType: 'Printer',
        receivedAt: now.subtract(const Duration(days: 1)),
      );

      var newRepairTapped = false;
      Repair? selectedRepair;
      await tester.pumpWidget(
        repairsApp(
          onNewRepair: () => newRepairTapped = true,
          onRepairSelected: (repair) => selectedRepair = repair,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Repairs'), findsOneWidget);
      expect(find.text('Manage and track all repair jobs'), findsOneWidget);
      expect(find.text('New Repair'), findsOneWidget);
      expect(
        find.text('Search by repair code, customer, phone, or device'),
        findsOneWidget,
      );
      expect(find.text('All Statuses'), findsOneWidget);
      expect(find.text('All Dates'), findsOneWidget);
      expect(find.text('More Filters'), findsOneWidget);
      for (final label in [
        'All',
        'Active',
        'Waiting for Approval',
        'Waiting for Part',
        'Ready for Pickup',
        'Delivered',
      ]) {
        expect(find.text(label), findsWidgets);
      }
      for (final header in [
        'REPAIR CODE',
        'DEVICE',
        'CUSTOMER',
        'PHONE',
        'STATUS',
        'RECEIVED DATE',
        'LAST UPDATED',
      ]) {
        expect(find.text(header), findsOneWidget);
      }
      expect(find.text('REP-9001'), findsOneWidget);
      expect(find.text('MacBook Air M2'), findsOneWidget);
      expect(find.text('Lina'), findsOneWidget);
      expect(find.text('0552 11 00 22'), findsOneWidget);
      expect(find.text('Received'), findsOneWidget);
      expect(find.text('Open 16 days'), findsOneWidget);
      expect(find.text('—'), findsWidgets);
      expect(find.text('REP-0042'), findsNothing);
      expect(find.text('Ahmed Benali'), findsNothing);
      expect(find.text('HP EliteBook 840'), findsNothing);

      await tester.tap(find.text('New Repair'));
      await tester.pump();
      expect(newRepairTapped, isTrue);

      await tester.tap(
        find.ancestor(
          of: find.text('REP-9001'),
          matching: find.byType(AppTableRowShell),
        ),
      );
      await tester.pump();
      expect(selectedRepair?.repairCode, 'REP-9001');
    });

    testWidgets('search, no-results, and clear filters work', (tester) async {
      _setDesktopSurface(tester);
      await _insertRepair(
        database,
        repairCode: 'REP-SEARCH',
        status: RepairStatus.received,
        customerName: 'Amina',
        receivedAt: now,
      );

      await tester.pumpWidget(repairsApp());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'missing');
      await tester.pump(repairsSearchDebounceDuration);
      await tester.pumpAndSettle();

      expect(find.text('No repairs found'), findsOneWidget);
      expect(
        find.text('Try adjusting your search or filters.'),
        findsOneWidget,
      );
      expect(find.text('Clear filters'), findsOneWidget);

      await tester.tap(find.text('Clear filters'));
      await tester.pumpAndSettle();

      expect(find.text('REP-SEARCH'), findsOneWidget);
      expect(find.text('No repairs found'), findsNothing);
    });

    testWidgets('empty database state renders', (tester) async {
      _setDesktopSurface(tester);
      await tester.pumpWidget(repairsApp());
      await tester.pumpAndSettle();

      expect(find.text('No repairs yet'), findsOneWidget);
      expect(
        find.text('Create your first repair to get started.'),
        findsOneWidget,
      );
    });

    testWidgets('error state renders with retry', (tester) async {
      _setDesktopSurface(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(database),
            repairsListClockProvider.overrideWithValue(() => now),
            repairRepositoryProvider.overrideWithValue(
              _ThrowingRepairRepository(),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const Scaffold(body: RepairsPage()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Repairs could not be loaded.'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('pagination next and previous render real pages', (
      tester,
    ) async {
      _setDesktopSurface(tester);
      for (var index = 0; index < 21; index++) {
        await _insertRepair(
          database,
          repairCode: 'PAGE-${index.toString().padLeft(2, '0')}',
          status: RepairStatus.received,
          receivedAt: now.subtract(Duration(minutes: index)),
        );
      }

      await tester.pumpWidget(repairsApp());
      await tester.pumpAndSettle();

      expect(find.text('PAGE-00'), findsOneWidget);
      expect(find.text('PAGE-20'), findsNothing);

      await tester.tap(find.byTooltip('Next page'));
      await tester.pumpAndSettle();

      expect(find.text('Page 2'), findsOneWidget);
      expect(find.text('PAGE-20'), findsOneWidget);

      await tester.tap(find.byTooltip('Previous page'));
      await tester.pumpAndSettle();

      expect(find.text('Page 1'), findsOneWidget);
      expect(find.text('PAGE-00'), findsOneWidget);
    });

    testWidgets('refresh reflects a real status change', (tester) async {
      _setDesktopSurface(tester);
      final repository = _repository(database, () => now);
      final repair = await repository.createRepair(
        CreateRepairInput(reportedProblem: 'No power'),
      );

      await tester.pumpWidget(repairsApp());
      await tester.pumpAndSettle();

      expect(find.text('Received'), findsOneWidget);

      now = now.add(const Duration(hours: 1));
      await repository.changeStatus(
        ChangeRepairStatusInput(
          repairId: repair.id!,
          targetStatus: RepairStatus.diagnosing,
        ),
      );

      final element = tester.element(find.byType(RepairsPage));
      final container = ProviderScope.containerOf(element);
      await container.read(repairsListControllerProvider.notifier).refresh();
      await tester.pumpAndSettle();

      expect(find.text('Diagnosing'), findsOneWidget);
      expect(find.text('Received'), findsNothing);
    });
  });
}

void _setDesktopSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1440, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

RepairStatus _singleStatus(ProviderContainer container) {
  final repairs = container
      .read(repairsListControllerProvider)
      .asData!
      .value
      .repairs;
  expect(repairs, hasLength(1));
  return repairs.single.status;
}

Future<void> _seedStatusSet(AppDatabase database, DateTime now) async {
  for (final entry in {
    'RECEIVED': RepairStatus.received,
    'DIAG': RepairStatus.diagnosing,
    'APPROVAL': RepairStatus.waitingForCustomerApproval,
    'PART': RepairStatus.waitingForPart,
    'READY': RepairStatus.readyForPickup,
    'DELIVERED': RepairStatus.delivered,
    'CANCELLED': RepairStatus.cancelled,
  }.entries) {
    await _insertRepair(
      database,
      repairCode: 'REP-${entry.key}',
      status: entry.value,
      receivedAt: now,
    );
  }
}

Future<void> _insertRepair(
  AppDatabase database, {
  required String repairCode,
  required RepairStatus status,
  required DateTime receivedAt,
  String? customerName,
  String? customerPhone,
  String? brand,
  String? model,
  String? deviceType,
}) {
  final timestamp = DateTime.utc(2026, 7, 5, 9);

  return database
      .into(database.repairs)
      .insert(
        RepairsCompanion.insert(
          repairCode: repairCode,
          customerName: Value(customerName),
          customerPhone: Value(customerPhone),
          brand: Value(brand),
          model: Value(model),
          deviceType: Value(deviceType),
          reportedProblem: 'Controlled test repair',
          status: status.databaseValue,
          createdAt: timestamp,
          updatedAt: timestamp,
          receivedAt: receivedAt.toUtc(),
        ),
      );
}

DriftRepairRepository _repository(
  AppDatabase database,
  DateTime Function() now,
) {
  final repairLocalDataSource = RepairLocalDataSource(database);

  return DriftRepairRepository(
    database,
    repairLocalDataSource,
    RepairCodeSequenceLocalDataSource(database),
    ShopSettingsLocalDataSource(database),
    now: now,
  );
}

class _ThrowingRepairRepository implements RepairRepository {
  @override
  Future<List<Repair>> searchRepairs(RepairSearchQuery query) {
    throw StateError('forced failure');
  }

  @override
  Future<Repair> changeStatus(ChangeRepairStatusInput input) {
    throw UnimplementedError();
  }

  @override
  Future<Repair> clearPrice(ClearRepairPriceInput input) {
    throw UnimplementedError();
  }

  @override
  Future<Repair> createRepair(CreateRepairInput input) {
    throw UnimplementedError();
  }

  @override
  Future<Repair> createWarrantyReturn(CreateWarrantyReturnInput input) {
    throw UnimplementedError();
  }

  @override
  Future<Repair> updateRepairDetails(UpdateRepairInput input) {
    throw UnimplementedError();
  }

  @override
  Future<int> getActiveRepairCount() {
    throw UnimplementedError();
  }

  @override
  Future<int> getRepairCount() {
    throw UnimplementedError();
  }

  @override
  Future<DateTime?> getLatestRepairUpdatedAt() {
    throw UnimplementedError();
  }

  @override
  Future<RepairAttentionCounts> getAttentionCounts({
    required DateTime readyBefore,
    required DateTime delayedBefore,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<Repair>> getDelayedActiveRepairs({
    required DateTime receivedBefore,
    required int limit,
    required int offset,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<Repair>> getReadyForPickupRepairs({
    required int limit,
    required int offset,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<Repair>> getReadyTooLongRepairs({
    required DateTime readyBefore,
    required int limit,
    required int offset,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<Repair>> getRecentRepairs({required int limit}) {
    throw UnimplementedError();
  }

  @override
  Future<Repair?> getRepairByCode(String repairCode) {
    throw UnimplementedError();
  }

  @override
  Future<Repair?> getRepairById(int id) {
    throw UnimplementedError();
  }

  @override
  Future<Map<RepairStatus, int>> getStatusCounts() {
    throw UnimplementedError();
  }

  @override
  Future<List<Repair>> getWarrantyReturnsForRepair(int repairId) {
    throw UnimplementedError();
  }

  @override
  Future<Repair> proposePrice(ProposeRepairPriceInput input) {
    throw UnimplementedError();
  }

  @override
  Future<Repair> recordCustomerPriceDecision(
    RecordCustomerPriceDecisionInput input,
  ) {
    throw UnimplementedError();
  }
}
