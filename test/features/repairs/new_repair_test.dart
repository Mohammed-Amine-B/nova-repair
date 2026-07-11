import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_repair/app/app.dart';
import 'package:nova_repair/app/theme/app_theme.dart';
import 'package:nova_repair/database/app_database.dart';
import 'package:nova_repair/database/database_provider.dart';
import 'package:nova_repair/features/common_problems/application/increment_common_problem_usage_use_case.dart';
import 'package:nova_repair/features/common_problems/common_problem_providers.dart';
import 'package:nova_repair/features/common_problems/data/datasources/common_problem_local_data_source.dart';
import 'package:nova_repair/features/common_problems/data/repositories/drift_common_problem_repository.dart';
import 'package:nova_repair/features/common_problems/domain/entities/common_problem.dart';
import 'package:nova_repair/features/common_problems/domain/entities/create_common_problem_input.dart';
import 'package:nova_repair/features/common_problems/domain/entities/update_common_problem_input.dart';
import 'package:nova_repair/features/common_problems/domain/repositories/common_problem_repository.dart';
import 'package:nova_repair/features/repairs/application/create_repair_use_case.dart';
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
import 'package:nova_repair/features/repairs/new_repair_page.dart';
import 'package:nova_repair/features/repairs/presentation/new_repair_controller.dart';
import 'package:nova_repair/features/repairs/presentation/new_repair_state.dart';
import 'package:nova_repair/features/repairs/repair_providers.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  ProviderContainer container() {
    return ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(database)],
    );
  }

  Widget newRepairApp({
    VoidCallback? onCancel,
    ValueChanged<Repair>? onRepairCreated,
    ValueChanged<Repair>? onRepairCreatedForPrint,
    bool failCommonProblemUsageIncrement = false,
  }) {
    return ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
        if (failCommonProblemUsageIncrement)
          incrementCommonProblemUsageUseCaseProvider.overrideWithValue(
            IncrementCommonProblemUsageUseCase(
              const _ThrowingCommonProblemRepository(),
            ),
          ),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: NewRepairPage(
            onCancel: onCancel ?? () {},
            onRepairCreated: onRepairCreated ?? (_) {},
            onRepairCreatedForPrint: onRepairCreatedForPrint ?? (_) {},
          ),
        ),
      ),
    );
  }

  group('NewRepairController', () {
    test('rejects blank required fields and invalid price text', () async {
      final testContainer = container();
      addTearDown(testContainer.dispose);

      final repair = await testContainer
          .read(newRepairControllerProvider.notifier)
          .submit(
            action: NewRepairSubmitAction.save,
            customerName: '',
            customerPhone: '',
            deviceType: ' ',
            brand: '',
            model: '',
            reportedProblem: '',
            receivedAccessories: '',
            deviceAccessInfo: '',
            priceText: '6500.5',
            internalNotes: '',
            customerMessage: '',
          );

      final state = testContainer.read(newRepairControllerProvider);
      expect(repair, isNull);
      expect(state.deviceTypeError, 'Device type is required.');
      expect(state.reportedProblemError, 'Reported problem is required.');
      expect(state.priceError, 'Enter a whole DZD amount.');
      expect(state.isSubmitting, isFalse);
    });

    test('creates repair through safe use case with generated code', () async {
      final testContainer = container();
      addTearDown(testContainer.dispose);

      final repair = await testContainer
          .read(newRepairControllerProvider.notifier)
          .submit(
            action: NewRepairSubmitAction.save,
            customerName: ' Lina ',
            customerPhone: ' 0552 ',
            deviceType: ' Laptop ',
            brand: ' Lenovo ',
            model: ' ThinkPad ',
            reportedProblem: ' No power ',
            receivedAccessories: ' Charger ',
            deviceAccessInfo: ' 1234 ',
            priceText: '6500',
            internalNotes: ' Private ',
            customerMessage: ' Visible later ',
          );

      expect(repair, isNotNull);
      expect(repair!.repairCode, 'REP-0001');
      expect(repair.id, isNotNull);
      expect(repair.status, RepairStatus.received);
      expect(repair.customerPriceDecision, CustomerPriceDecision.notRequested);
      expect(repair.deviceType, 'Laptop');
      expect(repair.reportedProblem, 'No power');
      expect(repair.priceAmount, 6500);
      expect(
        testContainer.read(newRepairControllerProvider).createdRepair,
        repair,
      );
    });

    test('keeps form state recoverable after creation failure', () async {
      final testContainer = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          createRepairUseCaseProvider.overrideWithValue(
            CreateRepairUseCase(_ThrowingRepairRepository()),
          ),
        ],
      );
      addTearDown(testContainer.dispose);

      final repair = await testContainer
          .read(newRepairControllerProvider.notifier)
          .submit(
            action: NewRepairSubmitAction.save,
            customerName: '',
            customerPhone: '',
            deviceType: 'Laptop',
            brand: '',
            model: '',
            reportedProblem: 'No power',
            receivedAccessories: '',
            deviceAccessInfo: '',
            priceText: '',
            internalNotes: '',
            customerMessage: '',
          );

      final state = testContainer.read(newRepairControllerProvider);
      expect(repair, isNull);
      expect(state.isSubmitting, isFalse);
      expect(
        state.submissionError,
        'Repair could not be saved. Please try again.',
      );
    });
  });

  group('NewRepairPage UI', () {
    testWidgets('renders approved form structure and actions', (tester) async {
      _setDesktopSurface(tester);

      await tester.pumpWidget(newRepairApp());
      await tester.pumpAndSettle();

      expect(find.text('New Repair'), findsOneWidget);
      expect(find.text('Create a new repair job'), findsOneWidget);
      expect(find.text('Customer Information'), findsOneWidget);
      expect(find.text('Device Information'), findsOneWidget);
      expect(find.text('Reported Problem'), findsWidgets);
      expect(find.text('Notes'), findsOneWidget);
      expect(find.text('Initial Status'), findsOneWidget);
      expect(find.text('Received'), findsOneWidget);
      expect(find.text('Received Accessories'), findsWidgets);
      expect(find.text('Device Access'), findsOneWidget);
      expect(find.text('PIN / Password / Access Note'), findsOneWidget);
      expect(find.text('Price'), findsOneWidget);
      expect(find.text('Proposed Repair Price'), findsOneWidget);
      expect(find.text('DA'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Save Repair'), findsOneWidget);
      expect(find.text('Save & Print'), findsOneWidget);
      expect(find.byType(DropdownButtonFormField<dynamic>), findsNothing);
    });

    testWidgets('shows immediate validation and keeps entered values', (
      tester,
    ) async {
      _setDesktopSurface(tester);

      await tester.pumpWidget(newRepairApp());
      await tester.pumpAndSettle();

      await tester.enterText(_field('new-repair-customer-name'), 'Amina');
      await tester.tap(find.text('Save Repair'));
      await tester.pumpAndSettle();

      expect(find.text('Device type is required.'), findsOneWidget);
      expect(find.text('Reported problem is required.'), findsOneWidget);
      expect(find.text('Amina'), findsOneWidget);
    });

    testWidgets('Save Repair creates a repair and calls normal callback', (
      tester,
    ) async {
      _setDesktopSurface(tester);
      Repair? savedRepair;
      Repair? printRepair;

      await tester.pumpWidget(
        newRepairApp(
          onRepairCreated: (repair) => savedRepair = repair,
          onRepairCreatedForPrint: (repair) => printRepair = repair,
        ),
      );
      await tester.pumpAndSettle();

      await _fillRequiredFields(tester);
      await tester.enterText(_field('new-repair-price'), '5000');
      await tester.tap(find.text('Save Repair'));
      await tester.pumpAndSettle();

      expect(savedRepair?.repairCode, 'REP-0001');
      expect(savedRepair?.status, RepairStatus.received);
      expect(
        savedRepair?.customerPriceDecision,
        CustomerPriceDecision.notRequested,
      );
      expect(savedRepair?.priceAmount, 5000);
      expect(printRepair, isNull);
    });

    testWidgets(
      'selecting common problem chip inserts text and increments once',
      (tester) async {
        _setDesktopSurface(tester);
        final commonProblems = _commonProblemRepository(database);
        final problem = await commonProblems.createCommonProblem(
          CreateCommonProblemInput(title: 'Does not charge'),
        );
        Repair? savedRepair;

        await tester.pumpWidget(
          newRepairApp(onRepairCreated: (repair) => savedRepair = repair),
        );
        await tester.pumpAndSettle();

        await _tapVisible(
          tester,
          find.byKey(Key('common-problem-chip-${problem.id}')),
        );
        await tester.pumpAndSettle();
        await _tapVisible(
          tester,
          find.byKey(Key('common-problem-chip-${problem.id}')),
        );
        await tester.pumpAndSettle();

        expect(
          _textFieldValue('new-repair-reported-problem', tester),
          'Does not charge',
        );
        expect(
          (await commonProblems.getCommonProblemById(problem.id!))?.usageCount,
          1,
        );

        await tester.enterText(_field('new-repair-device-type'), 'Laptop');
        await tester.tap(find.text('Save Repair'));
        await tester.pumpAndSettle();

        expect(savedRepair?.reportedProblem, 'Does not charge');
      },
    );

    testWidgets(
      'manual text is preserved and search selections append one per line',
      (tester) async {
        _setDesktopSurface(tester);
        final commonProblems = _commonProblemRepository(database);
        final charging = await commonProblems.createCommonProblem(
          CreateCommonProblemInput(title: 'Does not charge'),
        );
        final overheating = await commonProblems.createCommonProblem(
          CreateCommonProblemInput(title: 'Overheating'),
        );

        await tester.pumpWidget(newRepairApp());
        await tester.pumpAndSettle();

        await tester.enterText(
          _field('new-repair-reported-problem'),
          'Customer says it started yesterday',
        );
        await _tapVisible(
          tester,
          find.byKey(Key('common-problem-chip-${charging.id}')),
        );
        await tester.pumpAndSettle();
        await tester.enterText(_field('common-problem-picker-search'), 'heat');
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(Key('common-problem-search-result-${overheating.id}')),
        );
        await tester.pumpAndSettle();

        expect(
          _textFieldValue('new-repair-reported-problem', tester),
          'Customer says it started yesterday\nDoes not charge\nOverheating',
        );
        expect(_textFieldValue('common-problem-picker-search', tester), '');
      },
    );

    testWidgets('usage increment failure does not insert text', (tester) async {
      _setDesktopSurface(tester);
      final commonProblems = _commonProblemRepository(database);
      final problem = await commonProblems.createCommonProblem(
        CreateCommonProblemInput(title: 'Does not charge'),
      );

      await tester.pumpWidget(
        newRepairApp(failCommonProblemUsageIncrement: true),
      );
      await tester.pumpAndSettle();

      await _tapVisible(
        tester,
        find.byKey(Key('common-problem-chip-${problem.id}')),
      );
      await tester.pumpAndSettle();

      expect(_textFieldValue('new-repair-reported-problem', tester), '');
      expect(
        find.text('The problem could not be added. Please try again.'),
        findsOneWidget,
      );
      expect(
        (await commonProblems.getCommonProblemById(problem.id!))?.usageCount,
        0,
      );
    });

    testWidgets('Save & Print creates a repair and calls print callback', (
      tester,
    ) async {
      _setDesktopSurface(tester);
      Repair? savedRepair;
      Repair? printRepair;

      await tester.pumpWidget(
        newRepairApp(
          onRepairCreated: (repair) => savedRepair = repair,
          onRepairCreatedForPrint: (repair) => printRepair = repair,
        ),
      );
      await tester.pumpAndSettle();

      await _fillRequiredFields(tester);
      await tester.tap(find.text('Save & Print'));
      await tester.pumpAndSettle();

      expect(savedRepair, isNull);
      expect(printRepair?.repairCode, 'REP-0001');
      expect(printRepair?.status, RepairStatus.received);
    });

    testWidgets('submission failure shows inline error and preserves values', (
      tester,
    ) async {
      _setDesktopSurface(tester);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(database),
            createRepairUseCaseProvider.overrideWithValue(
              CreateRepairUseCase(_ThrowingRepairRepository()),
            ),
          ],
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

      await _fillRequiredFields(tester);
      await tester.tap(find.text('Save Repair'));
      await tester.pumpAndSettle();

      expect(
        find.text('Repair could not be saved. Please try again.'),
        findsOneWidget,
      );
      expect(find.text('Laptop'), findsOneWidget);
      expect(find.text('No power'), findsOneWidget);
    });
  });

  group('AppShell New Repair navigation', () {
    testWidgets('opens New Repair from Repairs and cancel returns to list', (
      tester,
    ) async {
      _setDesktopSurface(tester);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWithValue(database)],
          child: const NovaRepairApp(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Repairs'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('New Repair'));
      await tester.pumpAndSettle();

      expect(find.text('Create a new repair job'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Manage and track all repair jobs'), findsOneWidget);
    });

    testWidgets('saving returns to Repairs List with created repair visible', (
      tester,
    ) async {
      _setDesktopSurface(tester);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWithValue(database)],
          child: const NovaRepairApp(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Repairs'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('New Repair'));
      await tester.pumpAndSettle();

      await _fillRequiredFields(tester);
      await tester.enterText(_field('new-repair-customer-name'), 'Lina');
      await tester.tap(find.text('Save Repair'));
      await tester.pumpAndSettle();

      expect(find.text('Manage and track all repair jobs'), findsOneWidget);
      expect(find.text('REP-0001'), findsOneWidget);
      expect(find.text('Lina'), findsOneWidget);
    });
  });
}

Finder _field(String key) {
  return find.descendant(
    of: find.byKey(Key(key)),
    matching: find.byType(TextField),
  );
}

String _textFieldValue(String key, WidgetTester tester) {
  final editable = tester.widget<EditableText>(
    find.descendant(
      of: find.byKey(Key(key)),
      matching: find.byType(EditableText),
    ),
  );
  return editable.controller.text;
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
}

Future<void> _fillRequiredFields(WidgetTester tester) async {
  await tester.enterText(_field('new-repair-device-type'), 'Laptop');
  await tester.enterText(_field('new-repair-reported-problem'), 'No power');
}

DriftCommonProblemRepository _commonProblemRepository(AppDatabase database) {
  return DriftCommonProblemRepository(
    database,
    CommonProblemLocalDataSource(database),
  );
}

void _setDesktopSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1440, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

class _ThrowingRepairRepository implements RepairRepository {
  @override
  Future<Repair> createRepair(CreateRepairInput input) {
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
  Future<Repair?> getRepairByCode(String repairCode) {
    throw UnimplementedError();
  }

  @override
  Future<Repair?> getRepairById(int id) {
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

  @override
  Future<List<Repair>> searchRepairs(RepairSearchQuery query) {
    throw UnimplementedError();
  }
}

class _ThrowingCommonProblemRepository implements CommonProblemRepository {
  const _ThrowingCommonProblemRepository();

  @override
  Future<CommonProblem> createCommonProblem(CreateCommonProblemInput input) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteCommonProblem(int id) {
    throw UnimplementedError();
  }

  @override
  Future<CommonProblem?> getCommonProblemById(int id) {
    throw UnimplementedError();
  }

  @override
  Future<CommonProblem> incrementUsage(int id) {
    throw StateError('boom');
  }

  @override
  Future<List<CommonProblem>> listCommonProblems() {
    throw UnimplementedError();
  }

  @override
  Future<List<CommonProblem>> searchCommonProblems(String query) {
    throw UnimplementedError();
  }

  @override
  Future<CommonProblem> updateCommonProblemTitle(
    UpdateCommonProblemInput input,
  ) {
    throw UnimplementedError();
  }
}
