import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_repair/database/app_database.dart';
import 'package:nova_repair/features/repairs/data/datasources/repair_code_sequence_local_data_source.dart';
import 'package:nova_repair/features/repairs/data/datasources/repair_local_data_source.dart';
import 'package:nova_repair/features/repairs/data/repositories/drift_repair_repository.dart';
import 'package:nova_repair/features/repairs/domain/entities/create_repair_input.dart';
import 'package:nova_repair/features/repairs/domain/repair_status.dart';
import 'package:nova_repair/features/settings/data/datasources/shop_settings_local_data_source.dart';

void main() {
  late AppDatabase database;
  late DriftRepairRepository repository;
  late DateTime currentTime;

  setUp(() {
    currentTime = DateTime.utc(2026, 1, 1, 9);
    database = AppDatabase(_inMemoryDatabase());
    repository = _repository(database, () => currentTime);
  });

  tearDown(() async {
    await database.close();
  });

  group('repair lookup', () {
    test('lookup by ID and visible code succeeds', () async {
      final repair = await repository.createRepair(
        CreateRepairInput(reportedProblem: 'Does not power on'),
      );

      final byId = await repository.getRepairById(repair.id!);
      final byCode = await repository.getRepairByCode('  REP-0001  ');

      expect(byId?.id, repair.id);
      expect(byCode?.id, repair.id);
    });

    test('missing ID and code return null', () async {
      expect(await repository.getRepairById(999), isNull);
      expect(await repository.getRepairByCode('REP-9999'), isNull);
    });
  });

  group('recent repairs', () {
    test('empty database returns empty list', () async {
      expect(await repository.getRecentRepairs(limit: 5), isEmpty);
    });

    test('newest received repair is first with ID tie-breaker', () async {
      final older = await repository.createRepair(
        CreateRepairInput(
          reportedProblem: 'Older',
          receivedAt: DateTime.utc(2026, 1, 1, 8),
        ),
      );
      final sameTimeLowerId = await repository.createRepair(
        CreateRepairInput(
          reportedProblem: 'Same time lower ID',
          receivedAt: DateTime.utc(2026, 1, 2, 8),
        ),
      );
      final sameTimeHigherId = await repository.createRepair(
        CreateRepairInput(
          reportedProblem: 'Same time higher ID',
          receivedAt: DateTime.utc(2026, 1, 2, 8),
        ),
      );

      final repairs = await repository.getRecentRepairs(limit: 3);

      expect(repairs.map((repair) => repair.id), [
        sameTimeHigherId.id,
        sameTimeLowerId.id,
        older.id,
      ]);
    });

    test('limit is applied by the query', () async {
      await repository.createRepair(
        CreateRepairInput(reportedProblem: 'First'),
      );
      await repository.createRepair(
        CreateRepairInput(reportedProblem: 'Second'),
      );
      await repository.createRepair(
        CreateRepairInput(reportedProblem: 'Third'),
      );

      final repairs = await repository.getRecentRepairs(limit: 2);

      expect(repairs, hasLength(2));
      expect(repairs.map((repair) => repair.repairCode), [
        'REP-0003',
        'REP-0002',
      ]);
    });

    test('zero and negative limits are rejected', () async {
      expect(() => repository.getRecentRepairs(limit: 0), throwsArgumentError);
      expect(() => repository.getRecentRepairs(limit: -1), throwsArgumentError);
    });
  });

  group('status counts', () {
    test('grouped counts are correct with missing statuses as zero', () async {
      await insertRepair(
        database,
        currentTime,
        'REP-0001',
        RepairStatus.received,
      );
      await insertRepair(
        database,
        currentTime,
        'REP-0002',
        RepairStatus.received,
      );
      await insertRepair(
        database,
        currentTime,
        'REP-0003',
        RepairStatus.delivered,
      );
      await insertRepair(
        database,
        currentTime,
        'REP-0004',
        RepairStatus.cancelled,
      );

      final counts = await repository.getStatusCounts();

      expect(counts[RepairStatus.received], 2);
      expect(counts[RepairStatus.delivered], 1);
      expect(counts[RepairStatus.cancelled], 1);
      expect(counts[RepairStatus.diagnosing], 0);
      expect(counts[RepairStatus.waitingForCustomerApproval], 0);
      expect(counts[RepairStatus.waitingForPart], 0);
      expect(counts[RepairStatus.repairing], 0);
      expect(counts[RepairStatus.readyForPickup], 0);
    });

    test('invalid stored status values fail safely', () async {
      await database
          .into(database.repairs)
          .insert(
            RepairsCompanion.insert(
              repairCode: 'REP-0001',
              reportedProblem: 'Invalid status',
              status: 'unknown',
              createdAt: currentTime,
              updatedAt: currentTime,
              receivedAt: currentTime,
            ),
          );

      expect(repository.getStatusCounts, throwsFormatException);
    });
  });

  group('active repair count', () {
    test('includes active statuses and excludes final statuses', () async {
      await insertRepair(
        database,
        currentTime,
        'REP-0001',
        RepairStatus.received,
      );
      await insertRepair(
        database,
        currentTime,
        'REP-0002',
        RepairStatus.diagnosing,
      );
      await insertRepair(
        database,
        currentTime,
        'REP-0003',
        RepairStatus.waitingForCustomerApproval,
      );
      await insertRepair(
        database,
        currentTime,
        'REP-0004',
        RepairStatus.waitingForPart,
      );
      await insertRepair(
        database,
        currentTime,
        'REP-0005',
        RepairStatus.repairing,
      );
      await insertRepair(
        database,
        currentTime,
        'REP-0006',
        RepairStatus.readyForPickup,
      );
      await insertRepair(
        database,
        currentTime,
        'REP-0007',
        RepairStatus.delivered,
      );
      await insertRepair(
        database,
        currentTime,
        'REP-0008',
        RepairStatus.cancelled,
      );

      expect(await repository.getActiveRepairCount(), 6);
    });
  });
}

Future<void> insertRepair(
  AppDatabase database,
  DateTime currentTime,
  String repairCode,
  RepairStatus status,
) {
  return database
      .into(database.repairs)
      .insert(
        RepairsCompanion.insert(
          repairCode: repairCode,
          reportedProblem: 'Test repair',
          status: status.databaseValue,
          createdAt: currentTime,
          updatedAt: currentTime,
          receivedAt: currentTime,
        ),
      );
}

DriftRepairRepository _repository(
  AppDatabase database,
  DateTime Function() now,
) {
  return DriftRepairRepository(
    database,
    RepairLocalDataSource(database),
    RepairCodeSequenceLocalDataSource(database),
    ShopSettingsLocalDataSource(database),
    now: now,
  );
}

NativeDatabase _inMemoryDatabase() {
  return NativeDatabase.memory(
    setup: (database) {
      database.execute('PRAGMA foreign_keys = ON');
    },
  );
}
