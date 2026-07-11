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
import 'package:nova_repair/features/common_problems/data/datasources/common_problem_local_data_source.dart';
import 'package:nova_repair/features/common_problems/data/repositories/drift_common_problem_repository.dart';
import 'package:nova_repair/features/common_problems/domain/entities/create_common_problem_input.dart';
import 'package:nova_repair/features/dashboard/presentation/dashboard_controller.dart';
import 'package:nova_repair/features/repairs/application/propose_repair_price_use_case.dart';
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
import 'package:nova_repair/features/repairs/edit_repair_page.dart';
import 'package:nova_repair/features/repairs/new_repair_page.dart';
import 'package:nova_repair/features/repairs/presentation/edit_repair_controller.dart';
import 'package:nova_repair/features/repairs/presentation/repairs_list_controller.dart';
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

  Widget editRepairApp({
    required int repairId,
    VoidCallback? onCancel,
    VoidCallback? onBackToRepairs,
    ValueChanged<Repair>? onRepairUpdated,
    RepairRepository? repairRepository,
    ProposeRepairPriceUseCase? proposeRepairPriceUseCase,
  }) {
    return ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
        if (repairRepository != null)
          repairRepositoryProvider.overrideWithValue(repairRepository),
        if (proposeRepairPriceUseCase != null)
          proposeRepairPriceUseCaseProvider.overrideWithValue(
            proposeRepairPriceUseCase,
          ),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: EditRepairPage(
            repairId: repairId,
            onCancel: onCancel ?? () {},
            onBackToRepairs: onBackToRepairs ?? () {},
            onRepairUpdated: onRepairUpdated ?? (_) {},
          ),
        ),
      ),
    );
  }

  group('EditRepairController', () {
    test('loads fresh repair by id', () async {
      final repairId = await _insertRepair(
        database,
        repairCode: 'REP-EDIT-LOAD',
        deviceType: 'Laptop',
        reportedProblem: 'No power',
      );

      final container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
      );
      addTearDown(container.dispose);

      final repair = await container.read(
        editRepairLoadProvider(repairId).future,
      );

      expect(repair?.repairCode, 'REP-EDIT-LOAD');
      expect(repair?.deviceType, 'Laptop');
    });

    test('validates required fields and price format', () async {
      final repair = await _loadRepair(
        database,
        await _insertRepair(
          database,
          repairCode: 'REP-VALIDATE',
          status: RepairStatus.diagnosing,
        ),
      );
      final container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
      );
      addTearDown(container.dispose);

      final updated = await container
          .read(editRepairControllerProvider(repair.id!).notifier)
          .submit(
            originalRepair: repair,
            customerName: '',
            customerPhone: '',
            deviceType: ' ',
            brand: '',
            model: '',
            reportedProblem: '',
            receivedAccessories: '',
            deviceAccessInfo: '',
            priceText: '12.5',
            internalNotes: '',
            customerMessage: '',
          );

      final state = container.read(editRepairControllerProvider(repair.id!));
      expect(updated, isNull);
      expect(state.deviceTypeError, 'Device type is required.');
      expect(state.reportedProblemError, 'Reported problem is required.');
      expect(state.priceError, 'Enter a whole DZD amount.');
    });
  });

  group('EditRepairPage', () {
    testWidgets('prefills editable fields and shows current status read-only', (
      tester,
    ) async {
      await _setDesktopSurface(tester);
      final repairId = await _insertRepair(
        database,
        repairCode: 'REP-PREFILL',
        customerName: 'Nadia',
        customerPhone: '0550',
        deviceType: 'Laptop',
        brand: 'Lenovo',
        model: 'T14',
        reportedProblem: 'Does not charge',
        receivedAccessories: 'Charger',
        deviceAccessInfo: 'PIN 1234',
        priceAmount: 6500,
        internalNotes: 'Private',
        customerMessage: 'Visible later',
        status: RepairStatus.repairing,
      );

      await tester.pumpWidget(editRepairApp(repairId: repairId));
      await tester.pumpAndSettle();

      expect(find.text('Edit Repair'), findsOneWidget);
      expect(
        find.text('Update repair information for REP-PREFILL'),
        findsOneWidget,
      );
      expect(find.text('Current Status'), findsOneWidget);
      expect(find.text('Repairing'), findsOneWidget);
      expect(_textFieldValue('edit-repair-customer-name', tester), 'Nadia');
      expect(_textFieldValue('edit-repair-device-type', tester), 'Laptop');
      expect(_textFieldValue('edit-repair-brand', tester), 'Lenovo');
      expect(_textFieldValue('edit-repair-model', tester), 'T14');
      expect(
        _textFieldValue('edit-repair-reported-problem', tester),
        'Does not charge',
      );
      expect(_textFieldValue('edit-repair-price', tester), '6500');
      expect(find.byType(DropdownButtonFormField<dynamic>), findsNothing);
    });

    testWidgets('shows not-found state', (tester) async {
      await _setDesktopSurface(tester);

      await tester.pumpWidget(editRepairApp(repairId: 404));
      await tester.pumpAndSettle();

      expect(find.text('Repair not found'), findsOneWidget);
      expect(find.text('Back to Repairs'), findsOneWidget);
    });

    testWidgets('shows load-error state', (tester) async {
      await _setDesktopSurface(tester);

      await tester.pumpWidget(
        editRepairApp(
          repairId: 1,
          repairRepository: _ThrowingRepairRepository(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Repair could not be loaded'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.textContaining('boom'), findsNothing);
    });

    testWidgets('updates normal details and preserves protected fields', (
      tester,
    ) async {
      await _setDesktopSurface(tester);
      final createdAt = now.subtract(const Duration(days: 2));
      final readyAt = now.subtract(const Duration(hours: 3));
      final repairId = await _insertRepair(
        database,
        repairCode: 'REP-NORMAL',
        customerName: 'Old Name',
        deviceType: 'Laptop',
        reportedProblem: 'Old issue',
        status: RepairStatus.readyForPickup,
        priceAmount: 4500,
        customerPriceDecision: CustomerPriceDecision.approved,
        createdAt: createdAt,
        receivedAt: now.subtract(const Duration(days: 1)),
        readyAt: readyAt,
      );

      await tester.pumpWidget(editRepairApp(repairId: repairId));
      await tester.pumpAndSettle();

      await tester.enterText(_field('edit-repair-customer-name'), 'New Name');
      await tester.enterText(_field('edit-repair-device-type'), 'Desktop');
      await tester.enterText(
        _field('edit-repair-reported-problem'),
        'New issue',
      );
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      final updated = await _loadRepair(database, repairId);
      expect(updated.customerName, 'New Name');
      expect(updated.deviceType, 'Desktop');
      expect(updated.reportedProblem, 'New issue');
      expect(updated.repairCode, 'REP-NORMAL');
      expect(updated.status, RepairStatus.readyForPickup);
      expect(updated.priceAmount, 4500);
      expect(updated.customerPriceDecision, CustomerPriceDecision.approved);
      expect(updated.createdAt.toUtc(), createdAt);
      expect(updated.readyAt?.toUtc(), readyAt);
    });

    testWidgets(
      'existing reported problem loads unchanged without usage increment',
      (tester) async {
        await _setDesktopSurface(tester);
        final commonProblems = _commonProblemRepository(database);
        final problem = await commonProblems.createCommonProblem(
          CreateCommonProblemInput(title: 'Does not charge'),
        );
        final repairId = await _insertRepair(
          database,
          repairCode: 'REP-COMMON-LOAD',
          deviceType: 'Laptop',
          reportedProblem: 'Does not charge',
        );

        await tester.pumpWidget(editRepairApp(repairId: repairId));
        await tester.pumpAndSettle();

        expect(
          _textFieldValue('edit-repair-reported-problem', tester),
          'Does not charge',
        );
        expect(
          (await commonProblems.getCommonProblemById(problem.id!))?.usageCount,
          0,
        );
      },
    );

    testWidgets(
      'selecting common problem appends and save persists final text',
      (tester) async {
        await _setDesktopSurface(tester);
        final commonProblems = _commonProblemRepository(database);
        final problem = await commonProblems.createCommonProblem(
          CreateCommonProblemInput(title: 'Overheating'),
        );
        final repairId = await _insertRepair(
          database,
          repairCode: 'REP-COMMON-EDIT',
          deviceType: 'Laptop',
          reportedProblem: 'Customer says it started yesterday',
        );

        await tester.pumpWidget(editRepairApp(repairId: repairId));
        await tester.pumpAndSettle();
        await _tapVisible(
          tester,
          find.byKey(Key('common-problem-chip-${problem.id}')),
        );
        await tester.pumpAndSettle();

        expect(
          _textFieldValue('edit-repair-reported-problem', tester),
          'Customer says it started yesterday\nOverheating',
        );
        expect(
          (await commonProblems.getCommonProblemById(problem.id!))?.usageCount,
          1,
        );

        await tester.tap(find.text('Save Changes'));
        await tester.pumpAndSettle();
        var updated = await _loadRepair(database, repairId);
        expect(
          updated.reportedProblem,
          'Customer says it started yesterday\nOverheating',
        );

        await commonProblems.deleteCommonProblem(problem.id!);
        updated = await _loadRepair(database, repairId);
        expect(
          updated.reportedProblem,
          'Customer says it started yesterday\nOverheating',
        );
      },
    );

    testWidgets('duplicate existing line prevents insertion and increment', (
      tester,
    ) async {
      await _setDesktopSurface(tester);
      final commonProblems = _commonProblemRepository(database);
      final problem = await commonProblems.createCommonProblem(
        CreateCommonProblemInput(title: 'Does not charge'),
      );
      final repairId = await _insertRepair(
        database,
        repairCode: 'REP-COMMON-DUPLICATE',
        deviceType: 'Laptop',
        reportedProblem: ' does   not charge ',
      );

      await tester.pumpWidget(editRepairApp(repairId: repairId));
      await tester.pumpAndSettle();
      await _tapVisible(
        tester,
        find.byKey(Key('common-problem-chip-${problem.id}')),
      );
      await tester.pumpAndSettle();

      expect(
        _textFieldValue('edit-repair-reported-problem', tester),
        ' does   not charge ',
      );
      expect(
        (await commonProblems.getCommonProblemById(problem.id!))?.usageCount,
        0,
      );
    });

    testWidgets('coordinates add, change, and clear price through workflows', (
      tester,
    ) async {
      await _setDesktopSurface(tester);
      final repairId = await _insertRepair(
        database,
        repairCode: 'REP-PRICE',
        deviceType: 'Laptop',
        status: RepairStatus.diagnosing,
      );

      await tester.pumpWidget(editRepairApp(repairId: repairId));
      await tester.pumpAndSettle();
      await tester.enterText(_field('edit-repair-price'), '5000');
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      var updated = await _loadRepair(database, repairId);
      expect(updated.priceAmount, 5000);
      expect(updated.customerPriceDecision, CustomerPriceDecision.pending);

      await tester.pumpWidget(editRepairApp(repairId: repairId));
      await tester.pumpAndSettle();
      await tester.enterText(_field('edit-repair-price'), '6500');
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      updated = await _loadRepair(database, repairId);
      expect(updated.priceAmount, 6500);
      expect(updated.customerPriceDecision, CustomerPriceDecision.pending);

      await tester.pumpWidget(editRepairApp(repairId: repairId));
      await tester.pumpAndSettle();
      await tester.enterText(_field('edit-repair-price'), '');
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      updated = await _loadRepair(database, repairId);
      expect(updated.priceAmount, isNull);
      expect(updated.customerPriceDecision, CustomerPriceDecision.notRequested);
    });

    testWidgets('keeps price read-only in disallowed statuses', (tester) async {
      await _setDesktopSurface(tester);
      for (final status in [
        RepairStatus.received,
        RepairStatus.repairing,
        RepairStatus.delivered,
      ]) {
        final repairId = await _insertRepair(
          database,
          repairCode: 'REP-${status.name}',
          deviceType: 'Laptop',
          status: status,
          priceAmount: 5000,
        );

        await tester.pumpWidget(editRepairApp(repairId: repairId));
        await tester.pumpAndSettle();

        final priceField = tester.widget<TextField>(
          find.descendant(
            of: _field('edit-repair-price'),
            matching: find.byType(TextField),
          ),
        );
        expect(priceField.readOnly, isTrue);
        expect(
          find.text(
            'Price can only be changed while diagnosing or waiting for customer approval.',
          ),
          findsOneWidget,
        );

        await tester.enterText(_field('edit-repair-customer-name'), 'Edited');
        await tester.tap(find.text('Save Changes'));
        await tester.pumpAndSettle();

        final updated = await _loadRepair(database, repairId);
        expect(updated.customerName, 'Edited');
        expect(updated.priceAmount, 5000);
      }
    });

    testWidgets('reports partial failure after normal update succeeds', (
      tester,
    ) async {
      await _setDesktopSurface(tester);
      final repairId = await _insertRepair(
        database,
        repairCode: 'REP-PARTIAL',
        deviceType: 'Laptop',
        status: RepairStatus.diagnosing,
      );

      await tester.pumpWidget(
        editRepairApp(
          repairId: repairId,
          proposeRepairPriceUseCase: ProposeRepairPriceUseCase(
            _ThrowingPriceRepairRepository(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(_field('edit-repair-customer-name'), 'Updated');
      await tester.enterText(_field('edit-repair-price'), '7000');
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Repair information was updated, but the price could not be changed. Review the current values and try again.',
        ),
        findsOneWidget,
      );
      final updated = await _loadRepair(database, repairId);
      expect(updated.customerName, 'Updated');
      expect(updated.priceAmount, isNull);
    });
  });

  group('Shared form and shell navigation', () {
    testWidgets('New Repair still renders shared form sections and actions', (
      tester,
    ) async {
      await _setDesktopSurface(tester);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWithValue(database)],
          child: MaterialApp(
            theme: AppTheme.light(),
            home: Scaffold(
              body: NewRepairPage(
                onCancel: () {},
                onRepairCreated: (_) {},
                onRepairCreatedForPrint: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Customer Information'), findsOneWidget);
      expect(find.text('Device Information'), findsOneWidget);
      expect(find.text('Initial Status'), findsOneWidget);
      expect(find.text('Save Repair'), findsOneWidget);
      expect(find.text('Save & Print'), findsOneWidget);
    });

    testWidgets(
      'Details edit action opens Edit Repair and saves back to details',
      (tester) async {
        await _setDesktopSurface(tester);
        await _insertRepair(
          database,
          repairCode: 'REP-SHELL',
          customerName: 'Before Shell',
          deviceType: 'Laptop',
          reportedProblem: 'Screen flicker',
        );

        await tester.pumpWidget(_shellApp(database: database, now: now));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Repairs'));
        await tester.pumpAndSettle();
        await tester.tap(_rowForText('REP-SHELL'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Edit Repair'));
        await tester.pumpAndSettle();

        expect(find.text('Edit Repair'), findsOneWidget);
        await tester.enterText(
          _field('edit-repair-customer-name'),
          'After Shell',
        );
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(find.text('Repair Details'), findsOneWidget);
        expect(find.text('Before Shell'), findsOneWidget);

        await tester.tap(find.text('Edit Repair'));
        await tester.pumpAndSettle();
        await tester.enterText(
          _field('edit-repair-customer-name'),
          'After Shell',
        );
        await tester.tap(find.text('Save Changes'));
        await tester.pumpAndSettle();

        expect(find.text('Repair Details'), findsOneWidget);
        expect(find.text('After Shell'), findsOneWidget);

        await tester.tap(find.text('Back to Repairs'));
        await tester.pumpAndSettle();
        expect(find.text('After Shell'), findsOneWidget);
      },
    );
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

Finder _field(String key) => find.byKey(Key(key));

String _textFieldValue(String key, WidgetTester tester) {
  final editable = tester.widget<EditableText>(
    find.descendant(of: _field(key), matching: find.byType(EditableText)),
  );
  return editable.controller.text;
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

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
}

DriftCommonProblemRepository _commonProblemRepository(AppDatabase database) {
  return DriftCommonProblemRepository(
    database,
    CommonProblemLocalDataSource(database),
  );
}

Future<Repair> _loadRepair(AppDatabase database, int repairId) async {
  final row = await (database.select(
    database.repairs,
  )..where((repair) => repair.id.equals(repairId))).getSingle();
  return row.toDomainForTest();
}

Future<int> _insertRepair(
  AppDatabase database, {
  required String repairCode,
  RepairStatus status = RepairStatus.received,
  CustomerPriceDecision customerPriceDecision =
      CustomerPriceDecision.notRequested,
  DateTime? createdAt,
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
          createdAt: createdAt ?? baseTime,
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

extension on RepairRow {
  Repair toDomainForTest() {
    return Repair(
      id: id,
      repairCode: repairCode,
      customerName: customerName,
      customerPhone: customerPhone,
      deviceType: deviceType,
      brand: brand,
      model: model,
      reportedProblem: reportedProblem,
      receivedAccessories: receivedAccessories,
      deviceAccessInfo: deviceAccessInfo,
      status: RepairStatus.fromDatabaseValue(status),
      priceAmount: priceAmount,
      customerPriceDecision: CustomerPriceDecision.fromDatabaseValue(
        customerPriceDecision,
      ),
      internalNotes: internalNotes,
      customerMessage: customerMessage,
      parentRepairId: parentRepairId,
      createdAt: createdAt,
      updatedAt: updatedAt,
      receivedAt: receivedAt,
      readyAt: readyAt,
      deliveredAt: deliveredAt,
    );
  }
}

class _ThrowingRepairRepository implements RepairRepository {
  @override
  Future<Repair?> getRepairById(int id) {
    throw StateError('boom');
  }

  @override
  Future<Repair> proposePrice(ProposeRepairPriceInput input) {
    throw StateError('boom');
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
  Future<Repair> recordCustomerPriceDecision(
    RecordCustomerPriceDecisionInput input,
  ) => throw UnimplementedError();

  @override
  Future<List<Repair>> searchRepairs(RepairSearchQuery query) =>
      throw UnimplementedError();
}

class _ThrowingPriceRepairRepository extends _ThrowingRepairRepository {}
