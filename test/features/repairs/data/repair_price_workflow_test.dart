import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_repair/database/app_database.dart';
import 'package:nova_repair/features/repairs/data/datasources/repair_code_sequence_local_data_source.dart';
import 'package:nova_repair/features/repairs/data/datasources/repair_local_data_source.dart';
import 'package:nova_repair/features/repairs/data/repositories/drift_repair_repository.dart';
import 'package:nova_repair/features/repairs/domain/customer_price_decision.dart';
import 'package:nova_repair/features/repairs/domain/entities/change_repair_status_input.dart';
import 'package:nova_repair/features/repairs/domain/entities/clear_repair_price_input.dart';
import 'package:nova_repair/features/repairs/domain/entities/create_repair_input.dart';
import 'package:nova_repair/features/repairs/domain/entities/propose_repair_price_input.dart';
import 'package:nova_repair/features/repairs/domain/entities/record_customer_price_decision_input.dart';
import 'package:nova_repair/features/repairs/domain/entities/repair.dart';
import 'package:nova_repair/features/repairs/domain/errors/repair_price_workflow_exception.dart';
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

  test(
    'valid proposal stores integer price and sets decision pending',
    () async {
      final repair = await repairInStatus(
        repository,
        RepairStatus.diagnosing,
        () => currentTime,
        (value) => currentTime = value,
      );
      final originalUpdatedAt = repair.updatedAt;
      currentTime = DateTime.utc(2026, 1, 1, 12);

      final updated = await repository.proposePrice(
        ProposeRepairPriceInput(repairId: repair.id!, priceAmount: 5000),
      );

      expect(updated.priceAmount, 5000);
      expect(updated.customerPriceDecision, CustomerPriceDecision.pending);
      expect(updated.updatedAt, currentTime);
      expect(updated.updatedAt.isUtc, isTrue);
      expect(updated.createdAt, repair.createdAt);
      expect(updated.receivedAt, repair.receivedAt);
      expect(updated.readyAt, repair.readyAt);
      expect(updated.deliveredAt, repair.deliveredAt);
      expect(updated.updatedAt, isNot(originalUpdatedAt));
    },
  );

  test('negative price is rejected', () {
    expect(
      () => ProposeRepairPriceInput(repairId: 1, priceAmount: -1),
      throwsArgumentError,
    );
  });

  test(
    'proposal succeeds only in diagnosing or waiting for approval',
    () async {
      final diagnosing = await repairInStatus(
        repository,
        RepairStatus.diagnosing,
        () => currentTime,
        (value) => currentTime = value,
      );
      final waiting = await repairInStatus(
        repository,
        RepairStatus.waitingForCustomerApproval,
        () => currentTime,
        (value) => currentTime = value,
      );

      await repository.proposePrice(
        ProposeRepairPriceInput(repairId: diagnosing.id!, priceAmount: 3000),
      );
      await repository.proposePrice(
        ProposeRepairPriceInput(repairId: waiting.id!, priceAmount: 4000),
      );

      for (final status in [
        RepairStatus.received,
        RepairStatus.waitingForPart,
        RepairStatus.repairing,
        RepairStatus.readyForPickup,
        RepairStatus.delivered,
        RepairStatus.cancelled,
      ]) {
        final repair = await repairInStatus(
          repository,
          status,
          () => currentTime,
          (value) => currentTime = value,
        );

        expect(
          () => repository.proposePrice(
            ProposeRepairPriceInput(repairId: repair.id!, priceAmount: 6000),
          ),
          throwsA(isA<InvalidRepairPriceWorkflowStateException>()),
          reason: 'status ${status.name}',
        );
      }
    },
  );

  test('changing an approved or rejected price resets decision', () async {
    final approved = await repairWithDecision(
      repository,
      CustomerPriceDecision.approved,
      () => currentTime,
      (value) => currentTime = value,
      priceAmount: 5000,
    );
    final rejected = await repairWithDecision(
      repository,
      CustomerPriceDecision.rejected,
      () => currentTime,
      (value) => currentTime = value,
      priceAmount: 7000,
    );

    currentTime = DateTime.utc(2026, 1, 2, 9);
    final changedApproved = await repository.proposePrice(
      ProposeRepairPriceInput(repairId: approved.id!, priceAmount: 6500),
    );
    currentTime = DateTime.utc(2026, 1, 2, 10);
    final changedRejected = await repository.proposePrice(
      ProposeRepairPriceInput(repairId: rejected.id!, priceAmount: 8500),
    );

    expect(changedApproved.priceAmount, 6500);
    expect(
      changedApproved.customerPriceDecision,
      CustomerPriceDecision.pending,
    );
    expect(changedRejected.priceAmount, 8500);
    expect(
      changedRejected.customerPriceDecision,
      CustomerPriceDecision.pending,
    );
  });

  test(
    'same price can request approval again unless already pending',
    () async {
      final approved = await repairWithDecision(
        repository,
        CustomerPriceDecision.approved,
        () => currentTime,
        (value) => currentTime = value,
        priceAmount: 5000,
      );
      currentTime = DateTime.utc(2026, 1, 2, 9);

      final requestedAgain = await repository.proposePrice(
        ProposeRepairPriceInput(repairId: approved.id!, priceAmount: 5000),
      );

      expect(requestedAgain.priceAmount, 5000);
      expect(
        requestedAgain.customerPriceDecision,
        CustomerPriceDecision.pending,
      );

      expect(
        () => repository.proposePrice(
          ProposeRepairPriceInput(repairId: approved.id!, priceAmount: 5000),
        ),
        throwsA(isA<RepairPriceProposalAlreadyPendingException>()),
      );
    },
  );

  test('price changes preserve unrelated fields', () async {
    final repair = await repairInStatus(
      repository,
      RepairStatus.diagnosing,
      () => currentTime,
      (value) => currentTime = value,
      input: CreateRepairInput(
        customerName: 'Amina',
        reportedProblem: 'Does not power on',
        internalNotes: 'Keep charger',
        customerMessage: 'Initial message',
      ),
    );
    currentTime = DateTime.utc(2026, 1, 1, 12);

    final updated = await repository.proposePrice(
      ProposeRepairPriceInput(repairId: repair.id!, priceAmount: 5000),
    );

    expect(updated.repairCode, repair.repairCode);
    expect(updated.customerName, 'Amina');
    expect(updated.status, RepairStatus.diagnosing);
    expect(updated.internalNotes, 'Keep charger');
    expect(updated.customerMessage, 'Initial message');
  });

  test(
    'clearing price resets decision and preserves unrelated fields',
    () async {
      final repair = await repairInStatus(
        repository,
        RepairStatus.diagnosing,
        () => currentTime,
        (value) => currentTime = value,
        input: CreateRepairInput(
          customerName: 'Amina',
          reportedProblem: 'Does not power on',
          internalNotes: 'Internal note',
        ),
      );
      final proposed = await repository.proposePrice(
        ProposeRepairPriceInput(repairId: repair.id!, priceAmount: 5000),
      );
      currentTime = DateTime.utc(2026, 1, 1, 13);

      final cleared = await repository.clearPrice(
        ClearRepairPriceInput(repairId: repair.id!),
      );

      expect(cleared.priceAmount, isNull);
      expect(cleared.customerPriceDecision, CustomerPriceDecision.notRequested);
      expect(cleared.updatedAt, currentTime);
      expect(cleared.updatedAt, isNot(proposed.updatedAt));
      expect(cleared.customerName, 'Amina');
      expect(cleared.internalNotes, 'Internal note');
      expect(cleared.status, RepairStatus.diagnosing);
    },
  );

  test('clearing price is blocked in non-editable statuses', () async {
    final repair = await repairInStatus(
      repository,
      RepairStatus.repairing,
      () => currentTime,
      (value) => currentTime = value,
    );

    expect(
      () => repository.clearPrice(ClearRepairPriceInput(repairId: repair.id!)),
      throwsA(isA<InvalidRepairPriceWorkflowStateException>()),
    );
  });

  test('pending proposal can be approved without changing status', () async {
    final repair = await pendingApprovalRepair(
      repository,
      () => currentTime,
      (value) => currentTime = value,
      priceAmount: 5000,
    );
    currentTime = DateTime.utc(2026, 1, 2, 9);

    final approved = await repository.recordCustomerPriceDecision(
      RecordCustomerPriceDecisionInput(
        repairId: repair.id!,
        decision: CustomerPriceDecision.approved,
      ),
    );

    expect(approved.customerPriceDecision, CustomerPriceDecision.approved);
    expect(approved.priceAmount, 5000);
    expect(approved.status, RepairStatus.waitingForCustomerApproval);
    expect(approved.updatedAt, currentTime);
    expect(approved.updatedAt.isUtc, isTrue);
  });

  test('pending proposal can be rejected without changing status', () async {
    final repair = await pendingApprovalRepair(
      repository,
      () => currentTime,
      (value) => currentTime = value,
      priceAmount: 5000,
    );
    currentTime = DateTime.utc(2026, 1, 2, 9);

    final rejected = await repository.recordCustomerPriceDecision(
      RecordCustomerPriceDecisionInput(
        repairId: repair.id!,
        decision: CustomerPriceDecision.rejected,
      ),
    );

    expect(rejected.customerPriceDecision, CustomerPriceDecision.rejected);
    expect(rejected.priceAmount, 5000);
    expect(rejected.status, RepairStatus.waitingForCustomerApproval);
  });

  test(
    'customer decision requires a pending proposal and approval status',
    () async {
      final noPrice = await repairInStatus(
        repository,
        RepairStatus.waitingForCustomerApproval,
        () => currentTime,
        (value) => currentTime = value,
      );
      final withInitialPriceButNotRequested = await repairInStatus(
        repository,
        RepairStatus.waitingForCustomerApproval,
        () => currentTime,
        (value) => currentTime = value,
        input: CreateRepairInput(
          reportedProblem: 'Does not power on',
          priceAmount: 5000,
        ),
      );
      final diagnosing = await repairInStatus(
        repository,
        RepairStatus.diagnosing,
        () => currentTime,
        (value) => currentTime = value,
      );
      await repository.proposePrice(
        ProposeRepairPriceInput(repairId: diagnosing.id!, priceAmount: 5000),
      );

      expect(
        () => repository.recordCustomerPriceDecision(
          RecordCustomerPriceDecisionInput(
            repairId: noPrice.id!,
            decision: CustomerPriceDecision.approved,
          ),
        ),
        throwsA(isA<RepairPriceProposalNotPresentException>()),
      );
      expect(
        () => repository.recordCustomerPriceDecision(
          RecordCustomerPriceDecisionInput(
            repairId: noPrice.id!,
            decision: CustomerPriceDecision.rejected,
          ),
        ),
        throwsA(isA<RepairPriceProposalNotPresentException>()),
      );
      expect(
        () => repository.recordCustomerPriceDecision(
          RecordCustomerPriceDecisionInput(
            repairId: withInitialPriceButNotRequested.id!,
            decision: CustomerPriceDecision.approved,
          ),
        ),
        throwsA(isA<InvalidCustomerPriceDecisionTransitionException>()),
      );
      expect(
        () => repository.recordCustomerPriceDecision(
          RecordCustomerPriceDecisionInput(
            repairId: withInitialPriceButNotRequested.id!,
            decision: CustomerPriceDecision.rejected,
          ),
        ),
        throwsA(isA<InvalidCustomerPriceDecisionTransitionException>()),
      );
      expect(
        () => repository.recordCustomerPriceDecision(
          RecordCustomerPriceDecisionInput(
            repairId: diagnosing.id!,
            decision: CustomerPriceDecision.approved,
          ),
        ),
        throwsA(isA<InvalidRepairPriceWorkflowStateException>()),
      );
    },
  );

  test('approved and rejected decisions cannot directly change', () async {
    final approved = await repairWithDecision(
      repository,
      CustomerPriceDecision.approved,
      () => currentTime,
      (value) => currentTime = value,
    );
    final rejected = await repairWithDecision(
      repository,
      CustomerPriceDecision.rejected,
      () => currentTime,
      (value) => currentTime = value,
    );

    expect(
      () => repository.recordCustomerPriceDecision(
        RecordCustomerPriceDecisionInput(
          repairId: approved.id!,
          decision: CustomerPriceDecision.rejected,
        ),
      ),
      throwsA(isA<InvalidCustomerPriceDecisionTransitionException>()),
    );
    expect(
      () => repository.recordCustomerPriceDecision(
        RecordCustomerPriceDecisionInput(
          repairId: rejected.id!,
          decision: CustomerPriceDecision.approved,
        ),
      ),
      throwsA(isA<InvalidCustomerPriceDecisionTransitionException>()),
    );
  });

  test('customer decision input rejects non-response states', () {
    expect(
      () => RecordCustomerPriceDecisionInput(
        repairId: 1,
        decision: CustomerPriceDecision.pending,
      ),
      throwsArgumentError,
    );
    expect(
      () => RecordCustomerPriceDecisionInput(
        repairId: 1,
        decision: CustomerPriceDecision.notRequested,
      ),
      throwsArgumentError,
    );
  });

  test('invalid decision operation is atomic', () async {
    final approved = await repairWithDecision(
      repository,
      CustomerPriceDecision.approved,
      () => currentTime,
      (value) => currentTime = value,
      priceAmount: 5000,
    );
    final before = (await repository.getRepairById(approved.id!))!;
    currentTime = DateTime.utc(2026, 1, 3, 9);

    expect(
      () => repository.recordCustomerPriceDecision(
        RecordCustomerPriceDecisionInput(
          repairId: approved.id!,
          decision: CustomerPriceDecision.rejected,
        ),
      ),
      throwsA(isA<InvalidCustomerPriceDecisionTransitionException>()),
    );

    final after = await repository.getRepairById(approved.id!);
    expect(after?.priceAmount, before.priceAmount);
    expect(after?.customerPriceDecision, before.customerPriceDecision);
    expect(after?.updatedAt, before.updatedAt);
    expect(after?.status, before.status);
  });

  test('missing repair fails clearly', () async {
    expect(
      () => repository.proposePrice(
        ProposeRepairPriceInput(repairId: 999, priceAmount: 5000),
      ),
      throwsA(isA<RepairNotFoundException>()),
    );
    expect(
      () => repository.clearPrice(const ClearRepairPriceInput(repairId: 999)),
      throwsA(isA<RepairNotFoundException>()),
    );
    expect(
      () => repository.recordCustomerPriceDecision(
        RecordCustomerPriceDecisionInput(
          repairId: 999,
          decision: CustomerPriceDecision.approved,
        ),
      ),
      throwsA(isA<RepairNotFoundException>()),
    );
  });

  test('realistic price approval flow keeps status separate', () async {
    final repair = await repository.createRepair(
      CreateRepairInput(reportedProblem: 'Does not power on'),
    );
    final originalCode = repair.repairCode;

    currentTime = DateTime.utc(2026, 1, 1, 10);
    final diagnosing = await repository.changeStatus(
      ChangeRepairStatusInput(
        repairId: repair.id!,
        targetStatus: RepairStatus.diagnosing,
      ),
    );
    currentTime = DateTime.utc(2026, 1, 1, 11);
    final proposed = await repository.proposePrice(
      ProposeRepairPriceInput(repairId: repair.id!, priceAmount: 5000),
    );
    currentTime = DateTime.utc(2026, 1, 1, 12);
    final waiting = await repository.changeStatus(
      ChangeRepairStatusInput(
        repairId: repair.id!,
        targetStatus: RepairStatus.waitingForCustomerApproval,
      ),
    );
    currentTime = DateTime.utc(2026, 1, 1, 13);
    final approved = await repository.recordCustomerPriceDecision(
      RecordCustomerPriceDecisionInput(
        repairId: repair.id!,
        decision: CustomerPriceDecision.approved,
      ),
    );

    expect(diagnosing.status, RepairStatus.diagnosing);
    expect(proposed.customerPriceDecision, CustomerPriceDecision.pending);
    expect(waiting.status, RepairStatus.waitingForCustomerApproval);
    expect(approved.repairCode, originalCode);
    expect(approved.status, RepairStatus.waitingForCustomerApproval);
    expect(approved.customerPriceDecision, CustomerPriceDecision.approved);
    expect(approved.priceAmount, 5000);
    expect(await repository.getActiveRepairCount(), 1);
    final counts = await repository.getStatusCounts();
    expect(counts[RepairStatus.waitingForCustomerApproval], 1);
    expect(counts[RepairStatus.repairing], 0);
  });
}

Future<Repair> pendingApprovalRepair(
  DriftRepairRepository repository,
  DateTime Function() currentTime,
  void Function(DateTime value) setCurrentTime, {
  required int priceAmount,
}) async {
  final repair = await repairInStatus(
    repository,
    RepairStatus.diagnosing,
    currentTime,
    setCurrentTime,
  );
  setCurrentTime(currentTime().add(const Duration(hours: 1)));
  await repository.proposePrice(
    ProposeRepairPriceInput(repairId: repair.id!, priceAmount: priceAmount),
  );
  setCurrentTime(currentTime().add(const Duration(hours: 1)));
  return repository.changeStatus(
    ChangeRepairStatusInput(
      repairId: repair.id!,
      targetStatus: RepairStatus.waitingForCustomerApproval,
    ),
  );
}

Future<Repair> repairWithDecision(
  DriftRepairRepository repository,
  CustomerPriceDecision decision,
  DateTime Function() currentTime,
  void Function(DateTime value) setCurrentTime, {
  int priceAmount = 5000,
}) async {
  final repair = await pendingApprovalRepair(
    repository,
    currentTime,
    setCurrentTime,
    priceAmount: priceAmount,
  );
  setCurrentTime(currentTime().add(const Duration(hours: 1)));
  return repository.recordCustomerPriceDecision(
    RecordCustomerPriceDecisionInput(repairId: repair.id!, decision: decision),
  );
}

Future<Repair> repairInStatus(
  DriftRepairRepository repository,
  RepairStatus targetStatus,
  DateTime Function() currentTime,
  void Function(DateTime value) setCurrentTime, {
  CreateRepairInput? input,
}) async {
  final repair = await repository.createRepair(
    input ?? CreateRepairInput(reportedProblem: 'Does not power on'),
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
