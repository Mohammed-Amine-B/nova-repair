import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_repair/app/app_shell.dart';
import 'package:nova_repair/app/theme/app_theme.dart';
import 'package:nova_repair/app/widgets/status_badge.dart';
import 'package:nova_repair/app/widgets/table/app_table_shell.dart';
import 'package:nova_repair/database/app_database.dart';
import 'package:nova_repair/database/database_provider.dart';
import 'package:nova_repair/features/dashboard/presentation/dashboard_controller.dart';
import 'package:nova_repair/features/repairs/application/change_repair_status_use_case.dart';
import 'package:nova_repair/features/repairs/change_status_dialog.dart';
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
import 'package:nova_repair/features/repairs/presentation/change_status_dialog_controller.dart';
import 'package:nova_repair/features/repairs/presentation/repair_status_option_presentation.dart';
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

  Widget dialogApp(Repair repair) {
    return ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(database)],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(body: ChangeStatusDialog(repair: repair)),
      ),
    );
  }

  RepairRepository repositoryForTest() {
    final container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(database)],
    );
    addTearDown(container.dispose);
    return container.read(repairRepositoryProvider);
  }

  group('ChangeStatusDialog UI', () {
    testWidgets('renders approved dialog structure and real context', (
      tester,
    ) async {
      _setDesktopSurface(tester);
      final repair = await _insertAndLoadRepair(
        database,
        repairCode: 'REP-REAL',
        status: RepairStatus.repairing,
        brand: 'Dell',
        model: 'Latitude 5420',
        customerMessage: 'Existing customer message',
      );

      await tester.pumpWidget(dialogApp(repair));
      await tester.pumpAndSettle();

      expect(find.text('Change Repair Status'), findsOneWidget);
      expect(find.text('REP-REAL — Dell Latitude 5420'), findsOneWidget);
      expect(find.text('Current Status'.toUpperCase()), findsOneWidget);
      expect(find.text('Repairing'), findsWidgets);
      expect(find.text('Current'.toUpperCase()), findsOneWidget);
      expect(find.text('Customer Message'), findsOneWidget);
      expect(
        find.text('This may later be shown to the customer in repair tracking'),
        findsOneWidget,
      );
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Update Status'), findsOneWidget);
      expect(find.text('REP-0042'), findsNothing);
      expect(find.text('HP EliteBook 840'), findsNothing);

      for (final option in repairStatusOptionPresentations) {
        expect(find.text(option.status.displayLabel), findsWidgets);
        expect(find.text(option.description), findsOneWidget);
      }
    });

    testWidgets('all non-current targets can be selected and current cannot', (
      tester,
    ) async {
      _setDesktopSurface(tester);
      final repair = await _insertAndLoadRepair(
        database,
        repairCode: 'REP-SELECT',
        status: RepairStatus.received,
      );

      await tester.pumpWidget(dialogApp(repair));
      await tester.pumpAndSettle();

      expect(_submitButton(tester).enabled, isFalse);

      await _tapStatusOption(tester, RepairStatus.received);
      await tester.pumpAndSettle();
      expect(_submitButton(tester).enabled, isFalse);
      expect(find.byIcon(Icons.check), findsNothing);

      await _tapStatusOption(tester, RepairStatus.repairing);
      await tester.pumpAndSettle();
      expect(_submitButton(tester).enabled, isTrue);
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('delivered and cancelled repairs can be reopened', (
      tester,
    ) async {
      _setDesktopSurface(tester);
      final delivered = await _insertAndLoadRepair(
        database,
        repairCode: 'REP-DELIVERED',
        status: RepairStatus.delivered,
      );

      await tester.pumpWidget(dialogApp(delivered));
      await tester.pumpAndSettle();
      expect(_submitButton(tester).enabled, isFalse);
      await _tapStatusOption(tester, RepairStatus.repairing);
      await tester.pumpAndSettle();
      expect(_submitButton(tester).enabled, isTrue);

      final cancelled = await _insertAndLoadRepair(
        database,
        repairCode: 'REP-CANCELLED',
        status: RepairStatus.cancelled,
      );
      await tester.pumpWidget(dialogApp(cancelled));
      await tester.pumpAndSettle();
      expect(_submitButton(tester).enabled, isFalse);
      await _tapStatusOption(tester, RepairStatus.diagnosing);
      await tester.pumpAndSettle();
      expect(_submitButton(tester).enabled, isTrue);
    });
  });

  group('Transition availability', () {
    test('uses the shared flexible transition policy', () {
      for (final status in RepairStatus.values) {
        expect(
          _enabledTargets(status),
          RepairStatus.values.where((candidate) => candidate != status).toSet(),
          reason: status.name,
        );
      }
    });
  });

  group('Submission and customer message', () {
    test('duplicate submission is prevented by controller state', () async {
      final repair = Repair(
        id: 1,
        repairCode: 'REP-SLOW',
        reportedProblem: 'Problem',
        status: RepairStatus.received,
        createdAt: now,
        updatedAt: now,
        receivedAt: now,
      );
      final repository = _SlowRepairRepository(
        Repair(
          id: 1,
          repairCode: 'REP-SLOW',
          reportedProblem: 'Problem',
          status: RepairStatus.diagnosing,
          createdAt: now,
          updatedAt: now,
          receivedAt: now,
        ),
      );
      final container = ProviderContainer(
        overrides: [
          changeRepairStatusUseCaseProvider.overrideWithValue(
            ChangeRepairStatusUseCase(repository),
          ),
        ],
      );
      addTearDown(container.dispose);
      final provider = changeStatusDialogControllerProvider(repair);
      final controller = container.read(provider.notifier);

      controller.selectStatus(RepairStatus.diagnosing);
      final firstSubmit = controller.submit();
      final secondSubmit = await controller.submit();

      expect(secondSubmit, isNull);
      expect(repository.calls, 1);

      repository.complete();
      expect(await firstSubmit, isNotNull);
    });

    testWidgets('successful submit closes dialog and stores trimmed message', (
      tester,
    ) async {
      _setDesktopSurface(tester);
      final repair = await _insertAndLoadRepair(
        database,
        repairCode: 'REP-MSG',
        status: RepairStatus.received,
        customerMessage: 'Old message',
      );

      Repair? updatedRepair;
      await tester.pumpWidget(
        _dialogLauncherApp(database, repair, (repair) {
          updatedRepair = repair;
        }),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open dialog'));
      await tester.pumpAndSettle();
      await _tapStatusOption(tester, RepairStatus.diagnosing);
      await tester.enterText(
        _customerMessageField(),
        '  New message for customer  ',
      );
      await tester.tap(find.text('Update Status'));
      await tester.pumpAndSettle();

      expect(find.text('Change Repair Status'), findsNothing);
      expect(updatedRepair?.status, RepairStatus.diagnosing);
      expect(updatedRepair?.customerMessage, 'New message for customer');
    });

    testWidgets('untouched customer message is preserved', (tester) async {
      _setDesktopSurface(tester);
      final repair = await _insertAndLoadRepair(
        database,
        repairCode: 'REP-PRESERVE',
        status: RepairStatus.received,
        customerMessage: 'Keep me',
      );

      await tester.pumpWidget(dialogApp(repair));
      await tester.pumpAndSettle();
      await _tapStatusOption(tester, RepairStatus.diagnosing);
      await tester.tap(find.text('Update Status'));
      await tester.pumpAndSettle();

      final reloaded = await repositoryForTest().getRepairById(repair.id!);
      expect(reloaded?.customerMessage, 'Keep me');
    });

    testWidgets('clearing customer message removes stored value', (
      tester,
    ) async {
      _setDesktopSurface(tester);
      final repair = await _insertAndLoadRepair(
        database,
        repairCode: 'REP-CLEAR-MSG',
        status: RepairStatus.received,
        customerMessage: 'Remove me',
      );

      await tester.pumpWidget(dialogApp(repair));
      await tester.pumpAndSettle();
      await _tapStatusOption(tester, RepairStatus.diagnosing);
      await tester.enterText(_customerMessageField(), '   ');
      await tester.tap(find.text('Update Status'));
      await tester.pumpAndSettle();

      final reloaded = await repositoryForTest().getRepairById(repair.id!);
      expect(reloaded?.customerMessage, isNull);
    });

    testWidgets('failure keeps dialog open with calm inline error', (
      tester,
    ) async {
      _setDesktopSurface(tester);
      final repair = await _insertAndLoadRepair(
        database,
        repairCode: 'REP-STALE',
        status: RepairStatus.received,
      );

      await tester.pumpWidget(dialogApp(repair));
      await tester.pumpAndSettle();
      await _tapStatusOption(tester, RepairStatus.diagnosing);

      await repositoryForTest().changeStatus(
        ChangeRepairStatusInput(
          repairId: repair.id!,
          targetStatus: RepairStatus.diagnosing,
        ),
      );

      await tester.tap(find.text('Update Status'));
      await tester.pumpAndSettle();

      expect(find.text('Change Repair Status'), findsOneWidget);
      expect(find.textContaining('no longer allowed'), findsOneWidget);
      expect(
        find.textContaining('InvalidRepairStatusTransitionException'),
        findsNothing,
      );
    });
  });

  group('Timestamp integration', () {
    testWidgets('repairing to ready for pickup sets readyAt', (tester) async {
      _setDesktopSurface(tester);
      final repair = await _insertAndLoadRepair(
        database,
        repairCode: 'REP-READY',
        status: RepairStatus.repairing,
      );

      await tester.pumpWidget(dialogApp(repair));
      await tester.pumpAndSettle();
      await _tapStatusOption(tester, RepairStatus.readyForPickup);
      await tester.tap(find.text('Update Status'));
      await tester.pumpAndSettle();

      final reloaded = await repositoryForTest().getRepairById(repair.id!);
      expect(reloaded?.status, RepairStatus.readyForPickup);
      expect(reloaded?.readyAt, isNotNull);
    });

    testWidgets('ready for pickup to repairing preserves readyAt', (
      tester,
    ) async {
      _setDesktopSurface(tester);
      final repair = await _insertAndLoadRepair(
        database,
        repairCode: 'REP-BACK-REPAIRING',
        status: RepairStatus.readyForPickup,
        readyAt: now,
      );

      await tester.pumpWidget(dialogApp(repair));
      await tester.pumpAndSettle();
      await _tapStatusOption(tester, RepairStatus.repairing);
      await tester.tap(find.text('Update Status'));
      await tester.pumpAndSettle();

      final reloaded = await repositoryForTest().getRepairById(repair.id!);
      expect(reloaded?.status, RepairStatus.repairing);
      expect(reloaded?.readyAt, now);
    });

    testWidgets('ready for pickup to delivered sets deliveredAt', (
      tester,
    ) async {
      _setDesktopSurface(tester);
      final repair = await _insertAndLoadRepair(
        database,
        repairCode: 'REP-DELIVER',
        status: RepairStatus.readyForPickup,
        readyAt: now,
      );

      await tester.pumpWidget(dialogApp(repair));
      await tester.pumpAndSettle();
      await _tapStatusOption(tester, RepairStatus.delivered);
      await tester.tap(find.text('Update Status'));
      await tester.pumpAndSettle();

      final reloaded = await repositoryForTest().getRepairById(repair.id!);
      expect(reloaded?.status, RepairStatus.delivered);
      expect(reloaded?.deliveredAt, isNotNull);
    });
  });

  group('Refresh integration', () {
    testWidgets('successful change refreshes details, list, and dashboard', (
      tester,
    ) async {
      _setDesktopSurface(tester);
      await _insertAndLoadRepair(
        database,
        repairCode: 'REP-REFRESH',
        status: RepairStatus.repairing,
        brand: 'Acer',
        model: 'Swift',
      );

      await tester.pumpWidget(_shellApp(database: database, now: now));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Repairs'));
      await tester.pumpAndSettle();
      await tester.tap(_rowForText('REP-REFRESH'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Change Status'));
      await tester.pumpAndSettle();
      await _tapStatusOption(tester, RepairStatus.readyForPickup);
      await tester.tap(find.text('Update Status'));
      await tester.pumpAndSettle();

      expect(find.text('Ready for Pickup'), findsWidgets);
      expect(find.text('Ready for pickup'), findsOneWidget);

      await tester.tap(find.text('Back to Repairs'));
      await tester.pumpAndSettle();
      expect(find.text('Ready for Pickup'), findsWidgets);

      await tester.tap(find.text('Dashboard'));
      await tester.pumpAndSettle();
      expect(find.text('Ready for Pickup'), findsWidgets);
      expect(find.text('1'), findsWidgets);
    });

    testWidgets('reopened delivered repair refreshes list and dashboard', (
      tester,
    ) async {
      _setDesktopSurface(tester);
      await _insertAndLoadRepair(
        database,
        repairCode: 'REP-REOPEN',
        status: RepairStatus.delivered,
        brand: 'Lenovo',
        model: 'ThinkPad',
        deliveredAt: now,
      );

      await tester.pumpWidget(_shellApp(database: database, now: now));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Repairs'));
      await tester.pumpAndSettle();
      await tester.tap(_rowForText('REP-REOPEN'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Change Status'));
      await tester.pumpAndSettle();
      await _tapStatusOption(tester, RepairStatus.repairing);
      await tester.tap(find.text('Update Status'));
      await tester.pumpAndSettle();

      expect(find.text('Repairing'), findsWidgets);

      await tester.tap(find.text('Back to Repairs'));
      await tester.pumpAndSettle();
      expect(find.text('Repairing'), findsWidgets);

      await tester.tap(find.text('Dashboard'));
      await tester.pumpAndSettle();
      expect(find.text('Active Repairs'), findsOneWidget);
      expect(find.text('1'), findsWidgets);
    });
  });
}

Set<RepairStatus> _enabledTargets(RepairStatus status) {
  final now = DateTime.utc(2026, 7, 5, 12);
  final repair = Repair(
    id: 1,
    repairCode: 'REP-${status.databaseValue}',
    reportedProblem: 'Problem',
    status: status,
    createdAt: now,
    updatedAt: now,
    receivedAt: now,
  );
  final container = ProviderContainer();
  addTearDown(container.dispose);
  final controller = container.read(
    changeStatusDialogControllerProvider(repair).notifier,
  );

  return {
    for (final candidate in RepairStatus.values)
      if (controller.isSelectable(candidate)) candidate,
  };
}

Widget _dialogLauncherApp(
  AppDatabase database,
  Repair repair,
  ValueChanged<Repair> onChanged,
) {
  return ProviderScope(
    overrides: [appDatabaseProvider.overrideWithValue(database)],
    child: MaterialApp(
      theme: AppTheme.light(),
      home: Builder(
        builder: (context) {
          return Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  final updated = await showChangeStatusDialog(
                    context: context,
                    repair: repair,
                  );
                  if (updated != null) {
                    onChanged(updated);
                  }
                },
                child: const Text('Open dialog'),
              ),
            ),
          );
        },
      ),
    ),
  );
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

Finder _statusOption(RepairStatus status) {
  return find.byKey(Key('status-option-${status.databaseValue}'));
}

Future<void> _tapStatusOption(WidgetTester tester, RepairStatus status) async {
  final finder = _statusOption(status);
  await tester.scrollUntilVisible(
    finder,
    120,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Finder _customerMessageField() {
  return find.descendant(
    of: find.byKey(const Key('change-status-customer-message')),
    matching: find.byType(TextField),
  );
}

ElevatedButton _submitButton(WidgetTester tester) {
  return tester.widget<ElevatedButton>(
    find.ancestor(
      of: find.text('Update Status'),
      matching: find.byType(ElevatedButton),
    ),
  );
}

void _setDesktopSurface(WidgetTester tester) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1440, 1000);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<Repair> _insertAndLoadRepair(
  AppDatabase database, {
  required String repairCode,
  required RepairStatus status,
  String? customerMessage,
  String? brand,
  String? model,
  DateTime? readyAt,
  DateTime? deliveredAt,
}) async {
  final baseTime = DateTime.utc(2026, 7, 5, 12);
  final id = await database
      .into(database.repairs)
      .insert(
        RepairsCompanion.insert(
          repairCode: repairCode,
          reportedProblem: 'Reported problem',
          status: status.databaseValue,
          createdAt: baseTime,
          updatedAt: baseTime,
          receivedAt: baseTime,
          customerMessage: Value(customerMessage),
          brand: Value(brand),
          model: Value(model),
          readyAt: Value(readyAt),
          deliveredAt: Value(deliveredAt),
        ),
      );

  final container = ProviderContainer(
    overrides: [appDatabaseProvider.overrideWithValue(database)],
  );
  addTearDown(container.dispose);

  return (await container.read(repairRepositoryProvider).getRepairById(id))!;
}

class _SlowRepairRepository implements RepairRepository {
  _SlowRepairRepository(this.updatedRepair);

  final Repair updatedRepair;
  final Completer<Repair> _completer = Completer<Repair>();
  int calls = 0;

  void complete() {
    _completer.complete(updatedRepair);
  }

  @override
  Future<Repair> changeStatus(ChangeRepairStatusInput input) {
    calls += 1;
    return _completer.future;
  }

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
  Future<Repair?> getRepairById(int id) => throw UnimplementedError();

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
