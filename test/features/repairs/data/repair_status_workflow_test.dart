import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_repair/database/app_database.dart';
import 'package:nova_repair/features/repairs/data/datasources/repair_code_sequence_local_data_source.dart';
import 'package:nova_repair/features/repairs/data/datasources/repair_local_data_source.dart';
import 'package:nova_repair/features/repairs/data/repositories/drift_repair_repository.dart';
import 'package:nova_repair/features/repairs/domain/entities/change_repair_status_input.dart';
import 'package:nova_repair/features/repairs/domain/entities/create_repair_input.dart';
import 'package:nova_repair/features/repairs/domain/entities/repair.dart';
import 'package:nova_repair/features/repairs/domain/errors/repair_status_workflow_exception.dart';
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

  test('changes an existing repair status successfully', () async {
    final repair = await repository.createRepair(
      CreateRepairInput(
        customerName: 'Amina',
        reportedProblem: 'Does not power on',
        internalNotes: 'Keep screws together',
        priceAmount: 2500,
      ),
    );
    currentTime = DateTime.utc(2026, 1, 1, 10);

    final updated = await repository.changeStatus(
      ChangeRepairStatusInput(
        repairId: repair.id!,
        targetStatus: RepairStatus.diagnosing,
      ),
    );

    expect(updated.status, RepairStatus.diagnosing);
    expect(updated.updatedAt, currentTime);
    expect(updated.updatedAt.isUtc, isTrue);
    expect(updated.customerName, repair.customerName);
    expect(updated.internalNotes, repair.internalNotes);
    expect(updated.priceAmount, repair.priceAmount);
    expect(updated.customerPriceDecision, repair.customerPriceDecision);
    expect(updated.parentRepairId, repair.parentRepairId);
  });

  test('missing repair fails clearly', () async {
    expect(
      () => repository.changeStatus(
        const ChangeRepairStatusInput(
          repairId: 999,
          targetStatus: RepairStatus.diagnosing,
        ),
      ),
      throwsA(isA<RepairNotFoundException>()),
    );
  });

  test('same-status transition does not persist changes', () async {
    final repair = await repository.createRepair(
      CreateRepairInput(
        reportedProblem: 'Does not power on',
        customerMessage: 'Initial message',
      ),
    );
    currentTime = DateTime.utc(2026, 1, 1, 10);

    expect(
      () => repository.changeStatus(
        ChangeRepairStatusInput(
          repairId: repair.id!,
          targetStatus: RepairStatus.received,
          customerMessage: const OptionalCustomerMessage.replace(
            'Should not save',
          ),
        ),
      ),
      throwsA(isA<InvalidRepairStatusTransitionException>()),
    );

    final reloaded = await repository.getRepairById(repair.id!);

    expect(reloaded?.status, RepairStatus.received);
    expect(reloaded?.updatedAt, repair.updatedAt);
    expect(reloaded?.customerMessage, 'Initial message');
  });

  test('entering ready for pickup sets readyAt', () async {
    final repair = await repairInStatus(
      repository,
      RepairStatus.repairing,
      () => currentTime,
      (value) => currentTime = value,
    );
    currentTime = DateTime.utc(2026, 1, 2, 9);

    final updated = await repository.changeStatus(
      ChangeRepairStatusInput(
        repairId: repair.id!,
        targetStatus: RepairStatus.readyForPickup,
      ),
    );

    expect(updated.status, RepairStatus.readyForPickup);
    expect(updated.readyAt, currentTime);
    expect(updated.readyAt?.isUtc, isTrue);
    expect(updated.updatedAt, currentTime);
  });

  test('leaving ready for pickup preserves readyAt', () async {
    final repair = await repairInStatus(
      repository,
      RepairStatus.readyForPickup,
      () => currentTime,
      (value) => currentTime = value,
    );
    expect(repair.readyAt, isNotNull);
    currentTime = DateTime.utc(2026, 1, 2, 10);

    final updated = await repository.changeStatus(
      ChangeRepairStatusInput(
        repairId: repair.id!,
        targetStatus: RepairStatus.repairing,
      ),
    );

    expect(updated.status, RepairStatus.repairing);
    expect(updated.readyAt, repair.readyAt);
    expect(updated.updatedAt, currentTime);
  });

  test('re-entering ready for pickup updates readyAt to latest time', () async {
    final ready = await repairInStatus(
      repository,
      RepairStatus.readyForPickup,
      () => currentTime,
      (value) => currentTime = value,
    );
    final firstReadyAt = ready.readyAt;

    currentTime = DateTime.utc(2026, 1, 2, 10);
    final repairing = await repository.changeStatus(
      ChangeRepairStatusInput(
        repairId: ready.id!,
        targetStatus: RepairStatus.repairing,
      ),
    );
    expect(repairing.readyAt, firstReadyAt);

    currentTime = DateTime.utc(2026, 1, 2, 11);
    final readyAgain = await repository.changeStatus(
      ChangeRepairStatusInput(
        repairId: ready.id!,
        targetStatus: RepairStatus.readyForPickup,
      ),
    );

    expect(readyAgain.status, RepairStatus.readyForPickup);
    expect(readyAgain.readyAt, currentTime);
    expect(readyAgain.readyAt, isNot(firstReadyAt));
  });

  test('entering delivered sets deliveredAt', () async {
    final repair = await repairInStatus(
      repository,
      RepairStatus.readyForPickup,
      () => currentTime,
      (value) => currentTime = value,
    );
    currentTime = DateTime.utc(2026, 1, 3, 9);

    final updated = await repository.changeStatus(
      ChangeRepairStatusInput(
        repairId: repair.id!,
        targetStatus: RepairStatus.delivered,
      ),
    );

    expect(updated.status, RepairStatus.delivered);
    expect(updated.deliveredAt, currentTime);
    expect(updated.deliveredAt?.isUtc, isTrue);
    expect(updated.updatedAt, currentTime);
  });

  test(
    'delivered repair can reopen to repairing and preserves deliveredAt',
    () async {
      final delivered = await repairInStatus(
        repository,
        RepairStatus.delivered,
        () => currentTime,
        (value) => currentTime = value,
      );
      final deliveredAt = delivered.deliveredAt;
      currentTime = DateTime.utc(2026, 1, 3, 10);

      final reopened = await repository.changeStatus(
        ChangeRepairStatusInput(
          repairId: delivered.id!,
          targetStatus: RepairStatus.repairing,
        ),
      );

      expect(reopened.status, RepairStatus.repairing);
      expect(reopened.deliveredAt, deliveredAt);
      expect(reopened.updatedAt, currentTime);
    },
  );

  test('cancelled repair can reopen to diagnosing', () async {
    final cancelled = await repairInStatus(
      repository,
      RepairStatus.cancelled,
      () => currentTime,
      (value) => currentTime = value,
    );
    currentTime = DateTime.utc(2026, 1, 3, 11);

    final reopened = await repository.changeStatus(
      ChangeRepairStatusInput(
        repairId: cancelled.id!,
        targetStatus: RepairStatus.diagnosing,
      ),
    );

    expect(reopened.status, RepairStatus.diagnosing);
    expect(reopened.updatedAt, currentTime);
  });

  test('redelivery updates deliveredAt to latest time', () async {
    final delivered = await repairInStatus(
      repository,
      RepairStatus.delivered,
      () => currentTime,
      (value) => currentTime = value,
    );
    final firstDeliveredAt = delivered.deliveredAt;

    currentTime = DateTime.utc(2026, 1, 3, 10);
    final repairing = await repository.changeStatus(
      ChangeRepairStatusInput(
        repairId: delivered.id!,
        targetStatus: RepairStatus.repairing,
      ),
    );
    expect(repairing.deliveredAt, firstDeliveredAt);

    currentTime = DateTime.utc(2026, 1, 3, 12);
    final deliveredAgain = await repository.changeStatus(
      ChangeRepairStatusInput(
        repairId: delivered.id!,
        targetStatus: RepairStatus.delivered,
      ),
    );

    expect(deliveredAgain.status, RepairStatus.delivered);
    expect(deliveredAgain.deliveredAt, currentTime);
    expect(deliveredAgain.deliveredAt, isNot(firstDeliveredAt));
  });

  test(
    'customer message can be replaced, trimmed, cleared, or preserved',
    () async {
      final repair = await repository.createRepair(
        CreateRepairInput(
          reportedProblem: 'Does not power on',
          customerMessage: 'Initial message',
        ),
      );

      currentTime = DateTime.utc(2026, 1, 1, 10);
      final diagnosing = await repository.changeStatus(
        ChangeRepairStatusInput(
          repairId: repair.id!,
          targetStatus: RepairStatus.diagnosing,
          customerMessage: const OptionalCustomerMessage.replace(
            '  Checking the device  ',
          ),
        ),
      );
      expect(diagnosing.customerMessage, 'Checking the device');

      currentTime = DateTime.utc(2026, 1, 1, 11);
      final waitingForPart = await repository.changeStatus(
        ChangeRepairStatusInput(
          repairId: repair.id!,
          targetStatus: RepairStatus.waitingForPart,
        ),
      );
      expect(waitingForPart.customerMessage, 'Checking the device');

      currentTime = DateTime.utc(2026, 1, 1, 12);
      final repairing = await repository.changeStatus(
        ChangeRepairStatusInput(
          repairId: repair.id!,
          targetStatus: RepairStatus.repairing,
          customerMessage: const OptionalCustomerMessage.replace('   '),
        ),
      );
      expect(repairing.customerMessage, isNull);
    },
  );

  test('query counts reflect status changes', () async {
    final repair = await repairInStatus(
      repository,
      RepairStatus.repairing,
      () => currentTime,
      (value) => currentTime = value,
    );
    expect(await repository.getActiveRepairCount(), 1);

    currentTime = DateTime.utc(2026, 1, 2, 9);
    await repository.changeStatus(
      ChangeRepairStatusInput(
        repairId: repair.id!,
        targetStatus: RepairStatus.readyForPickup,
      ),
    );
    expect(await repository.getActiveRepairCount(), 1);

    currentTime = DateTime.utc(2026, 1, 2, 10);
    await repository.changeStatus(
      ChangeRepairStatusInput(
        repairId: repair.id!,
        targetStatus: RepairStatus.delivered,
      ),
    );

    final counts = await repository.getStatusCounts();
    expect(counts[RepairStatus.delivered], 1);
    expect(counts[RepairStatus.readyForPickup], 0);
    expect(await repository.getActiveRepairCount(), 0);
  });

  test(
    'reopened delivered and cancelled repairs become active again',
    () async {
      final delivered = await repairInStatus(
        repository,
        RepairStatus.delivered,
        () => currentTime,
        (value) => currentTime = value,
      );
      final cancelled = await repairInStatus(
        repository,
        RepairStatus.cancelled,
        () => currentTime,
        (value) => currentTime = value,
      );
      expect(await repository.getActiveRepairCount(), 0);

      currentTime = DateTime.utc(2026, 1, 4, 9);
      await repository.changeStatus(
        ChangeRepairStatusInput(
          repairId: delivered.id!,
          targetStatus: RepairStatus.repairing,
        ),
      );
      await repository.changeStatus(
        ChangeRepairStatusInput(
          repairId: cancelled.id!,
          targetStatus: RepairStatus.diagnosing,
        ),
      );

      final counts = await repository.getStatusCounts();
      expect(counts[RepairStatus.repairing], 1);
      expect(counts[RepairStatus.diagnosing], 1);
      expect(counts[RepairStatus.delivered], 0);
      expect(counts[RepairStatus.cancelled], 0);
      expect(await repository.getActiveRepairCount(), 2);
    },
  );
}

Future<Repair> repairInStatus(
  DriftRepairRepository repository,
  RepairStatus targetStatus,
  DateTime Function() currentTime,
  void Function(DateTime value) setCurrentTime,
) async {
  final repair = await repository.createRepair(
    CreateRepairInput(reportedProblem: 'Does not power on'),
  );

  var current = repair;
  for (final status in pathTo(targetStatus)) {
    setCurrentTime(currentTime().add(const Duration(hours: 1)));
    current = await repository.changeStatus(
      ChangeRepairStatusInput(repairId: repair.id!, targetStatus: status),
    );
  }

  return current;
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
