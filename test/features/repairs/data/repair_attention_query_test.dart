import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_repair/database/app_database.dart';
import 'package:nova_repair/features/repairs/data/datasources/repair_code_sequence_local_data_source.dart';
import 'package:nova_repair/features/repairs/data/datasources/repair_local_data_source.dart';
import 'package:nova_repair/features/repairs/data/repositories/drift_repair_repository.dart';
import 'package:nova_repair/features/repairs/domain/entities/change_repair_status_input.dart';
import 'package:nova_repair/features/repairs/domain/entities/create_repair_input.dart';
import 'package:nova_repair/features/repairs/domain/entities/create_warranty_return_input.dart';
import 'package:nova_repair/features/repairs/domain/entities/repair.dart';
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

  test(
    'ready for pickup query returns only ready repairs in waiting order',
    () async {
      final readyNew = await insertRepair(
        database,
        repository,
        repairCode: 'REP-0001',
        status: RepairStatus.readyForPickup,
        readyAt: DateTime.utc(2026, 1, 4),
      );
      await insertRepair(
        database,
        repository,
        repairCode: 'REP-0002',
        status: RepairStatus.delivered,
        readyAt: DateTime.utc(2026, 1, 1),
      );
      await insertRepair(
        database,
        repository,
        repairCode: 'REP-0003',
        status: RepairStatus.cancelled,
        readyAt: DateTime.utc(2026, 1, 1),
      );
      final missingReadyAt = await insertRepair(
        database,
        repository,
        repairCode: 'REP-0004',
        status: RepairStatus.readyForPickup,
      );
      final readyOld = await insertRepair(
        database,
        repository,
        repairCode: 'REP-0005',
        status: RepairStatus.readyForPickup,
        readyAt: DateTime.utc(2026, 1, 2),
      );
      final readySameTime = await insertRepair(
        database,
        repository,
        repairCode: 'REP-0006',
        status: RepairStatus.readyForPickup,
        readyAt: DateTime.utc(2026, 1, 2),
      );

      final repairs = await repository.getReadyForPickupRepairs(
        limit: 10,
        offset: 0,
      );
      final page = await repository.getReadyForPickupRepairs(
        limit: 2,
        offset: 1,
      );

      expect(
        [for (final repair in repairs) repair.id],
        [missingReadyAt.id, readyOld.id, readySameTime.id, readyNew.id],
      );
      expect(
        [for (final repair in page) repair.id],
        [readyOld.id, readySameTime.id],
      );
    },
  );

  test('ready query validates pagination and returns empty results', () async {
    expect(
      await repository.getReadyForPickupRepairs(limit: 10, offset: 0),
      isEmpty,
    );
    expect(
      () => repository.getReadyForPickupRepairs(limit: 0, offset: 0),
      throwsArgumentError,
    );
    expect(
      () => repository.getReadyForPickupRepairs(limit: 10, offset: -1),
      throwsArgumentError,
    );
  });

  test(
    'ready too long uses strict cutoff and includes missing readyAt',
    () async {
      final cutoff = DateTime.utc(2026, 1, 5);
      final older = await insertRepair(
        database,
        repository,
        repairCode: 'REP-0001',
        status: RepairStatus.readyForPickup,
        readyAt: DateTime.utc(2026, 1, 4, 23, 59),
      );
      await insertRepair(
        database,
        repository,
        repairCode: 'REP-0002',
        status: RepairStatus.readyForPickup,
        readyAt: cutoff,
      );
      await insertRepair(
        database,
        repository,
        repairCode: 'REP-0003',
        status: RepairStatus.readyForPickup,
        readyAt: DateTime.utc(2026, 1, 5, 0, 1),
      );
      await insertRepair(
        database,
        repository,
        repairCode: 'REP-0004',
        status: RepairStatus.repairing,
        readyAt: DateTime.utc(2026, 1, 1),
      );
      final missingReadyAt = await insertRepair(
        database,
        repository,
        repairCode: 'REP-0005',
        status: RepairStatus.readyForPickup,
      );

      final repairs = await repository.getReadyTooLongRepairs(
        readyBefore: cutoff,
        limit: 10,
        offset: 0,
      );

      expect(
        [for (final repair in repairs) repair.id],
        [missingReadyAt.id, older.id],
      );
    },
  );

  test(
    'delayed active query includes active statuses and excludes final statuses',
    () async {
      final cutoff = DateTime.utc(2026, 1, 10);
      final activeRepairs = <Repair>[];

      for (final status in RepairSearchActiveStatuses.values) {
        activeRepairs.add(
          await insertRepair(
            database,
            repository,
            repairCode: 'REP-${activeRepairs.length + 1}'.padRight(8, '0'),
            status: status,
            receivedAt: DateTime.utc(2026, 1, activeRepairs.length + 1),
            readyAt: status == RepairStatus.readyForPickup
                ? DateTime.utc(2026, 1, 7)
                : null,
          ),
        );
      }

      await insertRepair(
        database,
        repository,
        repairCode: 'REP-0100',
        status: RepairStatus.delivered,
        receivedAt: DateTime.utc(2026, 1, 1),
      );
      await insertRepair(
        database,
        repository,
        repairCode: 'REP-0101',
        status: RepairStatus.cancelled,
        receivedAt: DateTime.utc(2026, 1, 1),
      );
      await insertRepair(
        database,
        repository,
        repairCode: 'REP-0102',
        status: RepairStatus.received,
        receivedAt: cutoff,
      );
      await insertRepair(
        database,
        repository,
        repairCode: 'REP-0103',
        status: RepairStatus.received,
        receivedAt: DateTime.utc(2026, 1, 10, 0, 1),
      );

      final repairs = await repository.getDelayedActiveRepairs(
        receivedBefore: cutoff,
        limit: 10,
        offset: 0,
      );
      final page = await repository.getDelayedActiveRepairs(
        receivedBefore: cutoff,
        limit: 2,
        offset: 2,
      );

      expect([
        for (final repair in repairs) repair.status,
      ], RepairSearchActiveStatuses.values);
      expect(
        [for (final repair in page) repair.id],
        [activeRepairs[2].id, activeRepairs[3].id],
      );
    },
  );

  test(
    'delayed active query validates pagination and returns empty results',
    () async {
      expect(
        await repository.getDelayedActiveRepairs(
          receivedBefore: DateTime.utc(2026, 1, 1),
          limit: 10,
          offset: 0,
        ),
        isEmpty,
      );
      expect(
        () => repository.getDelayedActiveRepairs(
          receivedBefore: DateTime.utc(2026, 1, 1),
          limit: -1,
          offset: 0,
        ),
        throwsArgumentError,
      );
      expect(
        () => repository.getDelayedActiveRepairs(
          receivedBefore: DateTime.utc(2026, 1, 1),
          limit: 10,
          offset: -1,
        ),
        throwsArgumentError,
      );
    },
  );

  test('attention counts handle zero and matching repairs', () async {
    expect(
      await repository.getAttentionCounts(
        readyBefore: DateTime.utc(2026, 1, 5),
        delayedBefore: DateTime.utc(2026, 1, 10),
      ),
      hasAttentionCounts(waiting: 0, readyTooLong: 0, delayedActive: 0),
    );

    await insertRepair(
      database,
      repository,
      repairCode: 'REP-0001',
      status: RepairStatus.waitingForCustomerApproval,
      receivedAt: DateTime.utc(2026, 1, 1),
    );
    await insertRepair(
      database,
      repository,
      repairCode: 'REP-0002',
      status: RepairStatus.waitingForCustomerApproval,
      receivedAt: DateTime.utc(2026, 1, 12),
    );
    await insertRepair(
      database,
      repository,
      repairCode: 'REP-0003',
      status: RepairStatus.readyForPickup,
      receivedAt: DateTime.utc(2026, 1, 2),
      readyAt: DateTime.utc(2026, 1, 4),
    );
    await insertRepair(
      database,
      repository,
      repairCode: 'REP-0004',
      status: RepairStatus.readyForPickup,
      receivedAt: DateTime.utc(2026, 1, 3),
    );
    await insertRepair(
      database,
      repository,
      repairCode: 'REP-0005',
      status: RepairStatus.repairing,
      receivedAt: DateTime.utc(2026, 1, 4),
    );
    await insertRepair(
      database,
      repository,
      repairCode: 'REP-0006',
      status: RepairStatus.delivered,
      receivedAt: DateTime.utc(2026, 1, 1),
      readyAt: DateTime.utc(2026, 1, 4),
    );

    final counts = await repository.getAttentionCounts(
      readyBefore: DateTime.utc(2026, 1, 5),
      delayedBefore: DateTime.utc(2026, 1, 10),
    );

    expect(
      counts,
      hasAttentionCounts(waiting: 2, readyTooLong: 2, delayedActive: 4),
    );
  });

  test('status changes update ready and delayed derived results', () async {
    final repair = await repository.createRepair(
      CreateRepairInput(
        reportedProblem: 'Does not power on',
        receivedAt: DateTime.utc(2025, 12, 20),
      ),
    );
    final delayedBefore = DateTime.utc(2026, 1, 1);

    expect(
      [
        for (final repair in await repository.getDelayedActiveRepairs(
          receivedBefore: delayedBefore,
          limit: 10,
          offset: 0,
        ))
          repair.id,
      ],
      [repair.id],
    );

    final ready = await moveToStatus(
      repository,
      repair,
      RepairStatus.readyForPickup,
      () => currentTime,
      (value) => currentTime = value,
    );

    expect(
      [
        for (final repair in await repository.getReadyForPickupRepairs(
          limit: 10,
          offset: 0,
        ))
          repair.id,
      ],
      [repair.id],
    );
    expect(
      await repository.getAttentionCounts(
        readyBefore: ready.readyAt!.add(const Duration(minutes: 1)),
        delayedBefore: delayedBefore,
      ),
      hasAttentionCounts(waiting: 0, readyTooLong: 1, delayedActive: 1),
    );

    final delivered = await moveToStatus(
      repository,
      ready,
      RepairStatus.delivered,
      () => currentTime,
      (value) => currentTime = value,
      currentStatus: RepairStatus.readyForPickup,
    );

    expect(delivered.status, RepairStatus.delivered);
    expect(
      await repository.getReadyForPickupRepairs(limit: 10, offset: 0),
      isEmpty,
    );
    expect(
      await repository.getDelayedActiveRepairs(
        receivedBefore: delayedBefore,
        limit: 10,
        offset: 0,
      ),
      isEmpty,
    );
  });

  test(
    'warranty returns behave like normal repairs in attention queries',
    () async {
      final original = await repository.createRepair(
        CreateRepairInput(
          reportedProblem: 'Screen replacement',
          receivedAt: DateTime.utc(2025, 12, 1),
        ),
      );
      final deliveredOriginal = await moveToStatus(
        repository,
        original,
        RepairStatus.delivered,
        () => currentTime,
        (value) => currentTime = value,
      );
      currentTime = currentTime.add(const Duration(hours: 1));

      final warrantyReturn = await repository.createWarrantyReturn(
        CreateWarrantyReturnInput(
          originalRepairId: deliveredOriginal.id!,
          reportedProblem: 'Screen flickers again',
          receivedAt: DateTime.utc(2025, 12, 15),
        ),
      );

      expect(
        [
          for (final repair in await repository.getDelayedActiveRepairs(
            receivedBefore: DateTime.utc(2026, 1, 1),
            limit: 10,
            offset: 0,
          ))
            repair.id,
        ],
        [warrantyReturn.id],
      );

      await moveToStatus(
        repository,
        warrantyReturn,
        RepairStatus.readyForPickup,
        () => currentTime,
        (value) => currentTime = value,
      );

      expect(
        [
          for (final repair in await repository.getReadyForPickupRepairs(
            limit: 10,
            offset: 0,
          ))
            repair.id,
        ],
        [warrantyReturn.id],
      );
    },
  );
}

Future<Repair> insertRepair(
  AppDatabase database,
  DriftRepairRepository repository, {
  required String repairCode,
  required RepairStatus status,
  DateTime? receivedAt,
  DateTime? readyAt,
}) async {
  final timestamp = DateTime.utc(2026, 1, 1);
  final id = await database
      .into(database.repairs)
      .insert(
        RepairsCompanion.insert(
          repairCode: repairCode,
          reportedProblem: 'Reported problem',
          status: status.databaseValue,
          createdAt: timestamp,
          updatedAt: timestamp,
          receivedAt: (receivedAt ?? timestamp).toUtc(),
          readyAt: Value(readyAt?.toUtc()),
        ),
      );

  return (await repository.getRepairById(id))!;
}

Future<Repair> moveToStatus(
  DriftRepairRepository repository,
  Repair repair,
  RepairStatus targetStatus,
  DateTime Function() currentTime,
  void Function(DateTime value) setCurrentTime, {
  RepairStatus currentStatus = RepairStatus.received,
}) async {
  var current = repair;
  for (final status in pathBetween(currentStatus, targetStatus)) {
    setCurrentTime(currentTime().add(const Duration(hours: 1)));
    current = await repository.changeStatus(
      ChangeRepairStatusInput(repairId: repair.id!, targetStatus: status),
    );
  }

  return current;
}

List<RepairStatus> pathBetween(
  RepairStatus currentStatus,
  RepairStatus targetStatus,
) {
  final path = pathTo(targetStatus);
  if (currentStatus == RepairStatus.received) {
    return path;
  }

  final currentIndex = path.indexOf(currentStatus);
  if (currentIndex == -1) {
    throw ArgumentError(
      'No simple test path from $currentStatus to $targetStatus.',
    );
  }

  return path.sublist(currentIndex + 1);
}

List<RepairStatus> pathTo(RepairStatus targetStatus) {
  return switch (targetStatus) {
    RepairStatus.received => const [],
    RepairStatus.diagnosing => const [RepairStatus.diagnosing],
    RepairStatus.waitingForCustomerApproval => const [
      RepairStatus.diagnosing,
      RepairStatus.waitingForCustomerApproval,
    ],
    RepairStatus.waitingForPart => const [
      RepairStatus.diagnosing,
      RepairStatus.waitingForPart,
    ],
    RepairStatus.repairing => const [
      RepairStatus.diagnosing,
      RepairStatus.repairing,
    ],
    RepairStatus.readyForPickup => const [
      RepairStatus.diagnosing,
      RepairStatus.repairing,
      RepairStatus.readyForPickup,
    ],
    RepairStatus.delivered => const [
      RepairStatus.diagnosing,
      RepairStatus.repairing,
      RepairStatus.readyForPickup,
      RepairStatus.delivered,
    ],
    RepairStatus.cancelled => const [RepairStatus.cancelled],
  };
}

Matcher hasAttentionCounts({
  required int waiting,
  required int readyTooLong,
  required int delayedActive,
}) {
  return isA()
      .having(
        (counts) => counts.waitingForCustomerApproval,
        'waitingForCustomerApproval',
        waiting,
      )
      .having((counts) => counts.readyTooLong, 'readyTooLong', readyTooLong)
      .having((counts) => counts.delayedActive, 'delayedActive', delayedActive);
}

class RepairSearchActiveStatuses {
  static const values = [
    RepairStatus.received,
    RepairStatus.diagnosing,
    RepairStatus.waitingForCustomerApproval,
    RepairStatus.waitingForPart,
    RepairStatus.repairing,
    RepairStatus.readyForPickup,
  ];
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
