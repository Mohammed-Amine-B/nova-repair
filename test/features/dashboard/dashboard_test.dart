import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_repair/app/app.dart';
import 'package:nova_repair/app/theme/app_theme.dart';
import 'package:nova_repair/database/app_database.dart';
import 'package:nova_repair/database/database_provider.dart';
import 'package:nova_repair/features/dashboard/dashboard_page.dart';
import 'package:nova_repair/features/dashboard/presentation/dashboard_controller.dart';
import 'package:nova_repair/features/repairs/data/datasources/repair_code_sequence_local_data_source.dart';
import 'package:nova_repair/features/repairs/data/datasources/repair_local_data_source.dart';
import 'package:nova_repair/features/repairs/data/repositories/drift_repair_repository.dart';
import 'package:nova_repair/features/repairs/domain/entities/change_repair_status_input.dart';
import 'package:nova_repair/features/repairs/domain/entities/create_repair_input.dart';
import 'package:nova_repair/features/repairs/domain/repair_status.dart';
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
        dashboardClockProvider.overrideWithValue(() => now),
      ],
    );
  }

  Widget dashboardApp({VoidCallback? onViewAllRepairs}) {
    return ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
        dashboardClockProvider.overrideWithValue(() => now),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(body: DashboardPage(onViewAllRepairs: onViewAllRepairs)),
      ),
    );
  }

  group('Dashboard state', () {
    test('loads counts, recent repairs, and attention counts', () async {
      await _insertRepair(
        database,
        repairCode: 'REP-1001',
        status: RepairStatus.received,
        receivedAt: now.subtract(const Duration(days: 1)),
      );
      await _insertRepair(
        database,
        repairCode: 'REP-1002',
        status: RepairStatus.waitingForCustomerApproval,
        customerName: 'Amina',
        receivedAt: now.subtract(const Duration(days: 15, hours: 1)),
      );
      await _insertRepair(
        database,
        repairCode: 'REP-1003',
        status: RepairStatus.waitingForPart,
        receivedAt: now.subtract(const Duration(days: 2)),
      );
      await _insertRepair(
        database,
        repairCode: 'REP-1004',
        status: RepairStatus.readyForPickup,
        receivedAt: now.subtract(const Duration(days: 3)),
        readyAt: now.subtract(const Duration(days: 5, minutes: 1)),
      );
      await _insertRepair(
        database,
        repairCode: 'REP-1005',
        status: RepairStatus.delivered,
        receivedAt: now,
      );

      final testContainer = container();
      addTearDown(testContainer.dispose);

      final state = await testContainer.read(
        dashboardControllerProvider.future,
      );

      expect(state.activeRepairCount, 4);
      expect(state.waitingForApprovalCount, 1);
      expect(state.waitingForPartCount, 1);
      expect(state.readyForPickupCount, 1);
      expect(state.recentRepairs, hasLength(5));
      expect(state.recentRepairs.first.repairCode, 'REP-1005');
      expect(state.attentionCounts.waitingForCustomerApproval, 1);
      expect(state.attentionCounts.readyTooLong, 1);
      expect(state.attentionCounts.delayedActive, 1);
    });

    test('uses strict 5-day and 14-day attention cutoffs', () async {
      await _insertRepair(
        database,
        repairCode: 'REP-2001',
        status: RepairStatus.readyForPickup,
        receivedAt: now,
        readyAt: now.subtract(const Duration(days: 5)),
      );
      await _insertRepair(
        database,
        repairCode: 'REP-2002',
        status: RepairStatus.readyForPickup,
        receivedAt: now,
        readyAt: now.subtract(const Duration(days: 5, seconds: 1)),
      );
      await _insertRepair(
        database,
        repairCode: 'REP-2003',
        status: RepairStatus.repairing,
        receivedAt: now.subtract(const Duration(days: 14)),
      );
      await _insertRepair(
        database,
        repairCode: 'REP-2004',
        status: RepairStatus.repairing,
        receivedAt: now.subtract(const Duration(days: 14, seconds: 1)),
      );

      final testContainer = container();
      addTearDown(testContainer.dispose);

      final state = await testContainer.read(
        dashboardControllerProvider.future,
      );

      expect(state.attentionCounts.readyTooLong, 1);
      expect(state.attentionCounts.delayedActive, 1);
    });

    test('empty database produces zero counts and no recent repairs', () async {
      final testContainer = container();
      addTearDown(testContainer.dispose);

      final state = await testContainer.read(
        dashboardControllerProvider.future,
      );

      expect(state.activeRepairCount, 0);
      expect(state.waitingForApprovalCount, 0);
      expect(state.waitingForPartCount, 0);
      expect(state.readyForPickupCount, 0);
      expect(state.recentRepairs, isEmpty);
      expect(state.attentionCounts.waitingForCustomerApproval, 0);
      expect(state.attentionCounts.readyTooLong, 0);
      expect(state.attentionCounts.delayedActive, 0);
    });
  });

  group('Dashboard UI', () {
    testWidgets('renders real counts, recent repairs, and attention panel', (
      tester,
    ) async {
      await _insertRepair(
        database,
        repairCode: 'REP-9001',
        status: RepairStatus.waitingForCustomerApproval,
        customerName: 'Lina',
        brand: 'Lenovo',
        model: 'ThinkPad',
        receivedAt: now.subtract(const Duration(days: 15)),
      );
      await _insertRepair(
        database,
        repairCode: 'REP-9002',
        status: RepairStatus.readyForPickup,
        deviceType: 'Laptop',
        receivedAt: now.subtract(const Duration(days: 3)),
        readyAt: now.subtract(const Duration(days: 6)),
      );

      await tester.pumpWidget(dashboardApp());
      await tester.pumpAndSettle();

      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Overview of your repair activity'), findsOneWidget);
      expect(find.text('Active Repairs'), findsOneWidget);
      expect(find.text('Waiting for Approval'), findsOneWidget);
      expect(find.text('Waiting for Part'), findsOneWidget);
      expect(find.text('Ready for Pickup'), findsWidgets);
      expect(find.text('Recent Repairs'), findsOneWidget);
      expect(find.text('Needs Attention'), findsOneWidget);
      expect(find.text('REP-9001'), findsOneWidget);
      expect(find.text('Lenovo ThinkPad'), findsOneWidget);
      expect(find.text('Waiting for Customer Approval'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
      expect(find.text('REP-0042'), findsNothing);
      expect(find.text('Ahmed Benali'), findsNothing);
      expect(find.text('HP EliteBook 840'), findsNothing);
    });

    testWidgets('renders empty state for a new database', (tester) async {
      await tester.pumpWidget(dashboardApp());
      await tester.pumpAndSettle();

      expect(find.text('No repairs yet'), findsOneWidget);
      expect(find.text('New repairs will appear here.'), findsOneWidget);
      expect(find.text('0'), findsWidgets);
    });

    testWidgets('View all repairs navigates to Repairs destination', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(database),
            dashboardClockProvider.overrideWithValue(() => now),
          ],
          child: const NovaRepairApp(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('View all repairs →'));
      await tester.pumpAndSettle();

      expect(find.text('Manage and track all repair jobs'), findsOneWidget);
      expect(find.text('No repairs yet'), findsOneWidget);
    });

    testWidgets('refresh reflects status changes', (tester) async {
      final repository = _repository(database, () => now);
      final repair = await repository.createRepair(
        CreateRepairInput(reportedProblem: 'No power'),
      );

      await tester.pumpWidget(dashboardApp());
      await tester.pumpAndSettle();

      expect(find.text('Active Repairs'), findsOneWidget);
      expect(find.text('Waiting for Approval'), findsOneWidget);
      expect(find.text('0'), findsWidgets);

      now = now.add(const Duration(hours: 1));
      await repository.changeStatus(
        ChangeRepairStatusInput(
          repairId: repair.id!,
          targetStatus: RepairStatus.diagnosing,
        ),
      );
      now = now.add(const Duration(hours: 1));
      await repository.changeStatus(
        ChangeRepairStatusInput(
          repairId: repair.id!,
          targetStatus: RepairStatus.waitingForCustomerApproval,
        ),
      );

      final element = tester.element(find.byType(DashboardPage));
      final container = ProviderScope.containerOf(element);
      await container
          .read(dashboardControllerProvider.notifier)
          .refreshDashboard();
      await tester.pumpAndSettle();

      expect(find.text('Waiting for Customer Approval'), findsOneWidget);
      expect(find.text('1 repair'), findsWidgets);
    });
  });
}

Future<void> _insertRepair(
  AppDatabase database, {
  required String repairCode,
  required RepairStatus status,
  required DateTime receivedAt,
  String? customerName,
  String? brand,
  String? model,
  String? deviceType,
  DateTime? readyAt,
}) {
  final now = DateTime.utc(2026, 7, 5, 9);

  return database
      .into(database.repairs)
      .insert(
        RepairsCompanion.insert(
          repairCode: repairCode,
          customerName: Value(customerName),
          brand: Value(brand),
          model: Value(model),
          deviceType: Value(deviceType),
          reportedProblem: 'Controlled test repair',
          status: status.databaseValue,
          createdAt: now,
          updatedAt: now,
          receivedAt: receivedAt.toUtc(),
          readyAt: Value(readyAt?.toUtc()),
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
