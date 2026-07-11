import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_repair/app/app_shell.dart';
import 'package:nova_repair/app/theme/app_theme.dart';
import 'package:nova_repair/app/widgets/table/app_table_shell.dart';
import 'package:nova_repair/database/app_database.dart';
import 'package:nova_repair/database/database_provider.dart';
import 'package:nova_repair/features/dashboard/presentation/dashboard_controller.dart';
import 'package:nova_repair/features/repairs/domain/customer_price_decision.dart';
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
import 'package:nova_repair/features/repairs/presentation/repair_details_controller.dart';
import 'package:nova_repair/features/repairs/presentation/repair_details_formatters.dart';
import 'package:nova_repair/features/repairs/presentation/repair_details_state.dart';
import 'package:nova_repair/features/repairs/presentation/repairs_list_controller.dart';
import 'package:nova_repair/features/repairs/repair_details_page.dart';
import 'package:nova_repair/features/repairs/repair_providers.dart';

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

  Widget detailsApp({
    required int repairId,
    VoidCallback? onBackToRepairs,
    ValueChanged<Repair>? onEditRepair,
    ValueChanged<Repair>? onChangeStatus,
    ValueChanged<Repair>? onPrintRepair,
    ValueChanged<Repair>? onCreateWarrantyReturn,
    RepairRepository? repairRepository,
  }) {
    return ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
        if (repairRepository != null)
          repairRepositoryProvider.overrideWithValue(repairRepository),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: RepairDetailsPage(
            repairId: repairId,
            onBackToRepairs: onBackToRepairs ?? () {},
            onEditRepair: onEditRepair ?? (_) {},
            onChangeStatus: onChangeStatus ?? (_) {},
            onPrintRepair: onPrintRepair ?? (_) {},
            onCreateWarrantyReturn: onCreateWarrantyReturn ?? (_) {},
          ),
        ),
      ),
    );
  }

  group('RepairDetailsController', () {
    test('loads repair details with derived timeline newest first', () async {
      final repairId = await _insertRepair(
        database,
        repairCode: 'REP-DETAIL',
        status: RepairStatus.delivered,
        receivedAt: now.subtract(const Duration(days: 4)),
        readyAt: now.subtract(const Duration(days: 1)),
        deliveredAt: now,
      );

      final container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
      );
      addTearDown(container.dispose);

      final state = await container.read(
        repairDetailsControllerProvider(repairId).future,
      );

      expect(state, isNotNull);
      expect(state!.repair.repairCode, 'REP-DETAIL');
      expect(state.timelineEntries.map((entry) => entry.type), [
        RepairTimelineEntryType.delivered,
        RepairTimelineEntryType.readyForPickup,
        RepairTimelineEntryType.received,
      ]);
      expect(state.canCreateWarrantyReturn, isTrue);
    });

    test('loads original repair code for warranty returns', () async {
      final originalId = await _insertRepair(
        database,
        repairCode: 'REP-ORIGINAL',
        status: RepairStatus.delivered,
        receivedAt: now.subtract(const Duration(days: 10)),
      );
      final warrantyId = await _insertRepair(
        database,
        repairCode: 'REP-WARRANTY',
        status: RepairStatus.received,
        parentRepairId: originalId,
        receivedAt: now,
      );

      final container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
      );
      addTearDown(container.dispose);

      final state = await container.read(
        repairDetailsControllerProvider(warrantyId).future,
      );

      expect(state!.originalRepair?.repairCode, 'REP-ORIGINAL');
      expect(state.canCreateWarrantyReturn, isFalse);
    });

    test('returns null when the repair does not exist', () async {
      final container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
      );
      addTearDown(container.dispose);

      final state = await container.read(
        repairDetailsControllerProvider(999).future,
      );

      expect(state, isNull);
    });
  });

  group('RepairDetailsPage', () {
    testWidgets('renders read-only repair details from real data', (
      tester,
    ) async {
      await _setDesktopSurface(tester);
      final repairId = await _insertRepair(
        database,
        repairCode: 'REP-0099',
        customerName: 'Nadia Repair',
        customerPhone: '0550 123 456',
        deviceType: 'Laptop',
        brand: 'Lenovo',
        model: 'ThinkPad T14',
        reportedProblem: 'Does not charge',
        receivedAccessories: 'Charger and bag',
        deviceAccessInfo: 'PIN 1234',
        internalNotes: 'Check charging IC first',
        customerMessage: 'Waiting for technician review',
        status: RepairStatus.waitingForCustomerApproval,
        priceAmount: 6500,
        customerPriceDecision: CustomerPriceDecision.approved,
        receivedAt: now,
      );

      await tester.pumpWidget(detailsApp(repairId: repairId));
      await tester.pumpAndSettle();

      expect(find.text('Repair Details'), findsOneWidget);
      expect(find.text('REP-0099'), findsNWidgets(2));
      expect(find.text('Lenovo ThinkPad T14'), findsOneWidget);
      expect(find.text('Waiting for Customer Approval'), findsWidgets);
      expect(find.text('Nadia Repair'), findsOneWidget);
      expect(find.text('0550 123 456'), findsOneWidget);
      expect(find.text('Does not charge'), findsOneWidget);
      expect(find.text('Charger and bag'), findsOneWidget);
      expect(find.text('PIN 1234'), findsOneWidget);
      expect(find.text('Check charging IC first'), findsOneWidget);
      expect(find.text('Waiting for technician review'), findsOneWidget);
      expect(find.text('6 500 DA'), findsOneWidget);
      expect(find.text('Approved'), findsOneWidget);
      expect(find.text('Repair received'), findsOneWidget);
      expect(find.text('No previous repair linked'), findsOneWidget);
      expect(find.text('Create Warranty Return'), findsOneWidget);
      expect(find.text('REP-0042'), findsNothing);
      expect(find.text('Ahmed Benali'), findsNothing);
      expect(find.text('HP EliteBook 840'), findsNothing);
    });

    testWidgets('renders missing optional values with shared empty markers', (
      tester,
    ) async {
      await _setDesktopSurface(tester);
      final repairId = await _insertRepair(
        database,
        repairCode: 'REP-SPARSE',
        status: RepairStatus.received,
        receivedAt: now,
      );

      await tester.pumpWidget(detailsApp(repairId: repairId));
      await tester.pumpAndSettle();

      expect(find.text('REP-SPARSE'), findsNWidgets(2));
      expect(find.text('Device'), findsOneWidget);
      expect(find.text('—'), findsWidgets);
      expect(find.text('Not Requested'), findsOneWidget);
    });

    testWidgets('shows original repair code for warranty returns', (
      tester,
    ) async {
      await _setDesktopSurface(tester);
      final originalId = await _insertRepair(
        database,
        repairCode: 'REP-BASE',
        status: RepairStatus.delivered,
        receivedAt: now.subtract(const Duration(days: 30)),
      );
      final warrantyId = await _insertRepair(
        database,
        repairCode: 'REP-WR',
        status: RepairStatus.received,
        parentRepairId: originalId,
        receivedAt: now,
      );

      await tester.pumpWidget(detailsApp(repairId: warrantyId));
      await tester.pumpAndSettle();

      expect(find.text('Warranty Return'), findsOneWidget);
      expect(find.text('Original repair: REP-BASE'), findsOneWidget);
      expect(find.text('Create Warranty Return'), findsNothing);
    });

    testWidgets(
      'exposes action callback boundaries without implementing flows',
      (tester) async {
        await _setDesktopSurface(tester);
        final repairId = await _insertRepair(
          database,
          repairCode: 'REP-ACTIONS',
          status: RepairStatus.delivered,
          receivedAt: now,
        );
        final selectedCodes = <String>[];

        await tester.pumpWidget(
          detailsApp(
            repairId: repairId,
            onEditRepair: (repair) =>
                selectedCodes.add('edit:${repair.repairCode}'),
            onChangeStatus: (repair) =>
                selectedCodes.add('status:${repair.repairCode}'),
            onPrintRepair: (repair) =>
                selectedCodes.add('print:${repair.repairCode}'),
            onCreateWarrantyReturn: (repair) =>
                selectedCodes.add('warranty:${repair.repairCode}'),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Edit Repair'));
        await tester.tap(find.text('Change Status'));
        await tester.tap(find.text('Print'));
        await tester.scrollUntilVisible(
          find.text('Create Warranty Return'),
          120,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.text('Create Warranty Return'));

        expect(selectedCodes, [
          'edit:REP-ACTIONS',
          'status:REP-ACTIONS',
          'print:REP-ACTIONS',
          'warranty:REP-ACTIONS',
        ]);
      },
    );

    testWidgets('shows not found state', (tester) async {
      await _setDesktopSurface(tester);

      await tester.pumpWidget(detailsApp(repairId: 404));
      await tester.pumpAndSettle();

      expect(find.text('Repair not found'), findsOneWidget);
      expect(find.text('Back to Repairs'), findsOneWidget);
    });

    testWidgets('shows error state without raw details', (tester) async {
      await _setDesktopSurface(tester);

      await tester.pumpWidget(
        detailsApp(repairId: 1, repairRepository: _ThrowingRepairRepository()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Repair details could not be loaded.'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.textContaining('database boom'), findsNothing);
    });
  });

  group('formatters', () {
    test('formats integer DZD amounts without decimals', () {
      const formatter = DzdPriceFormatter();

      expect(formatter.format(0), '0 DA');
      expect(formatter.format(6500), '6 500 DA');
      expect(formatter.format(1250000), '1 250 000 DA');
    });
  });

  group('AppShell repair details navigation', () {
    testWidgets('opens details from Repairs list and returns to list', (
      tester,
    ) async {
      await _setDesktopSurface(tester);
      await _insertRepair(
        database,
        repairCode: 'REP-LIST-DETAIL',
        customerName: 'List Customer',
        status: RepairStatus.received,
        receivedAt: now,
      );

      await tester.pumpWidget(_shellApp(database: database, now: now));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Repairs'));
      await tester.pumpAndSettle();
      await tester.tap(_rowForText('REP-LIST-DETAIL'));
      await tester.pumpAndSettle();

      expect(find.text('Repair Details'), findsOneWidget);
      expect(find.text('List Customer'), findsOneWidget);

      await tester.tap(find.text('Back to Repairs'));
      await tester.pumpAndSettle();

      expect(find.text('Manage and track all repair jobs'), findsOneWidget);
      expect(find.text('REP-LIST-DETAIL'), findsOneWidget);
    });

    testWidgets('opens details from Dashboard recent repairs', (tester) async {
      await _setDesktopSurface(tester);
      await _insertRepair(
        database,
        repairCode: 'REP-DASH-DETAIL',
        customerName: 'Dashboard Customer',
        status: RepairStatus.received,
        receivedAt: now,
      );

      await tester.pumpWidget(_shellApp(database: database, now: now));
      await tester.pumpAndSettle();

      await tester.tap(_rowForText('REP-DASH-DETAIL'));
      await tester.pumpAndSettle();

      expect(find.text('Repair Details'), findsOneWidget);
      expect(find.text('Dashboard Customer'), findsOneWidget);
    });
  });
}

Widget _shellApp({required AppDatabase database, required DateTime now}) {
  return ProviderScope(
    overrides: [
      appDatabaseProvider.overrideWithValue(database),
      dashboardClockProvider.overrideWithValue(() => now),
      repairsListClockProvider.overrideWithValue(() => now),
    ],
    child: MaterialApp(theme: AppTheme.light(), home: const AppShell()),
  );
}

Finder _rowForText(String text) {
  return find.ancestor(
    of: find.text(text).first,
    matching: find.byType(AppTableRowShell),
  );
}

Future<void> _setDesktopSurface(WidgetTester tester) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1440, 1000);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<int> _insertRepair(
  AppDatabase database, {
  required String repairCode,
  RepairStatus status = RepairStatus.received,
  CustomerPriceDecision customerPriceDecision =
      CustomerPriceDecision.notRequested,
  DateTime? receivedAt,
  DateTime? readyAt,
  DateTime? deliveredAt,
  String? customerName,
  String? customerPhone,
  String? deviceType,
  String? brand,
  String? model,
  String reportedProblem = 'Reported problem',
  String? receivedAccessories,
  String? deviceAccessInfo,
  int? priceAmount,
  String? internalNotes,
  String? customerMessage,
  int? parentRepairId,
}) {
  final baseTime = DateTime.utc(2026, 7, 5, 12);

  return database
      .into(database.repairs)
      .insert(
        RepairsCompanion.insert(
          repairCode: repairCode,
          reportedProblem: reportedProblem,
          status: status.databaseValue,
          customerPriceDecision: Value(customerPriceDecision.databaseValue),
          createdAt: baseTime,
          updatedAt: baseTime.add(const Duration(minutes: 5)),
          receivedAt: receivedAt ?? baseTime,
          customerName: Value(customerName),
          customerPhone: Value(customerPhone),
          deviceType: Value(deviceType),
          brand: Value(brand),
          model: Value(model),
          receivedAccessories: Value(receivedAccessories),
          deviceAccessInfo: Value(deviceAccessInfo),
          priceAmount: Value(priceAmount),
          internalNotes: Value(internalNotes),
          customerMessage: Value(customerMessage),
          parentRepairId: Value(parentRepairId),
          readyAt: Value(readyAt),
          deliveredAt: Value(deliveredAt),
        ),
      );
}

class _ThrowingRepairRepository implements RepairRepository {
  @override
  Future<Repair?> getRepairById(int id) {
    throw StateError('database boom');
  }

  @override
  Future<Repair> changeStatus(ChangeRepairStatusInput input) =>
      throw UnimplementedError();

  @override
  Future<Repair> clearPrice(ClearRepairPriceInput input) =>
      throw UnimplementedError();

  @override
  Future<Repair> createRepair(CreateRepairInput input) =>
      throw UnimplementedError();

  @override
  Future<Repair> createWarrantyReturn(CreateWarrantyReturnInput input) =>
      throw UnimplementedError();

  @override
  Future<Repair> updateRepairDetails(UpdateRepairInput input) =>
      throw UnimplementedError();

  @override
  Future<int> getActiveRepairCount() => throw UnimplementedError();

  @override
  Future<int> getRepairCount() => throw UnimplementedError();

  @override
  Future<DateTime?> getLatestRepairUpdatedAt() => throw UnimplementedError();

  @override
  Future<RepairAttentionCounts> getAttentionCounts({
    required DateTime readyBefore,
    required DateTime delayedBefore,
  }) => throw UnimplementedError();

  @override
  Future<List<Repair>> getDelayedActiveRepairs({
    required DateTime receivedBefore,
    required int limit,
    required int offset,
  }) => throw UnimplementedError();

  @override
  Future<List<Repair>> getReadyForPickupRepairs({
    required int limit,
    required int offset,
  }) => throw UnimplementedError();

  @override
  Future<List<Repair>> getReadyTooLongRepairs({
    required DateTime readyBefore,
    required int limit,
    required int offset,
  }) => throw UnimplementedError();

  @override
  Future<Repair?> getRepairByCode(String repairCode) =>
      throw UnimplementedError();

  @override
  Future<List<Repair>> getRecentRepairs({required int limit}) =>
      throw UnimplementedError();

  @override
  Future<Map<RepairStatus, int>> getStatusCounts() =>
      throw UnimplementedError();

  @override
  Future<List<Repair>> getWarrantyReturnsForRepair(int repairId) =>
      throw UnimplementedError();

  @override
  Future<Repair> proposePrice(ProposeRepairPriceInput input) =>
      throw UnimplementedError();

  @override
  Future<Repair> recordCustomerPriceDecision(
    RecordCustomerPriceDecisionInput input,
  ) => throw UnimplementedError();

  @override
  Future<List<Repair>> searchRepairs(RepairSearchQuery query) =>
      throw UnimplementedError();
}
