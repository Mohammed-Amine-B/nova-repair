import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_repair/database/app_database.dart';
import 'package:nova_repair/features/repairs/data/datasources/repair_code_sequence_local_data_source.dart';
import 'package:nova_repair/features/repairs/data/datasources/repair_local_data_source.dart';
import 'package:nova_repair/features/repairs/data/repositories/drift_repair_repository.dart';
import 'package:nova_repair/features/repairs/domain/customer_price_decision.dart';
import 'package:nova_repair/features/repairs/domain/entities/change_repair_status_input.dart';
import 'package:nova_repair/features/repairs/domain/entities/create_repair_input.dart';
import 'package:nova_repair/features/repairs/domain/entities/create_warranty_return_input.dart';
import 'package:nova_repair/features/repairs/domain/entities/propose_repair_price_input.dart';
import 'package:nova_repair/features/repairs/domain/entities/record_customer_price_decision_input.dart';
import 'package:nova_repair/features/repairs/domain/entities/repair.dart';
import 'package:nova_repair/features/repairs/domain/errors/warranty_return_workflow_exception.dart';
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

  test('delivered original repair can create a warranty return', () async {
    final original = await deliveredOriginalRepair(
      repository,
      () => currentTime,
      (value) => currentTime = value,
    );
    final originalBefore = (await repository.getRepairById(original.id!))!;
    currentTime = DateTime.utc(2026, 1, 4, 9);

    final warrantyReturn = await repository.createWarrantyReturn(
      CreateWarrantyReturnInput(
        originalRepairId: original.id!,
        reportedProblem:
            ' Device shuts down unexpectedly after previous repair ',
        receivedAccessories: ' Charger ',
        deviceAccessInfo: ' 1234 ',
        internalNotes: ' Check replaced part ',
        customerMessage: ' Received for warranty inspection ',
        receivedAt: DateTime.utc(2026, 1, 4, 8),
      ),
    );

    expect(warrantyReturn.repairCode, isNot(original.repairCode));
    expect(warrantyReturn.repairCode, 'REP-0002');
    expect(warrantyReturn.parentRepairId, original.id);
    expect(warrantyReturn.status, RepairStatus.received);
    expect(warrantyReturn.priceAmount, isNull);
    expect(
      warrantyReturn.customerPriceDecision,
      CustomerPriceDecision.notRequested,
    );
    expect(warrantyReturn.customerName, original.customerName);
    expect(warrantyReturn.customerPhone, original.customerPhone);
    expect(warrantyReturn.deviceType, original.deviceType);
    expect(warrantyReturn.brand, original.brand);
    expect(warrantyReturn.model, original.model);
    expect(
      warrantyReturn.reportedProblem,
      'Device shuts down unexpectedly after previous repair',
    );
    expect(warrantyReturn.receivedAccessories, 'Charger');
    expect(warrantyReturn.deviceAccessInfo, '1234');
    expect(warrantyReturn.internalNotes, 'Check replaced part');
    expect(warrantyReturn.customerMessage, 'Received for warranty inspection');
    expect(warrantyReturn.createdAt, currentTime);
    expect(warrantyReturn.updatedAt, currentTime);
    expect(warrantyReturn.receivedAt, DateTime.utc(2026, 1, 4, 8));
    expect(warrantyReturn.readyAt, isNull);
    expect(warrantyReturn.deliveredAt, isNull);

    final originalAfter = await repository.getRepairById(original.id!);
    expect(originalAfter?.repairCode, originalBefore.repairCode);
    expect(originalAfter?.status, originalBefore.status);
    expect(originalAfter?.priceAmount, originalBefore.priceAmount);
    expect(
      originalAfter?.customerPriceDecision,
      originalBefore.customerPriceDecision,
    );
    expect(originalAfter?.internalNotes, originalBefore.internalNotes);
    expect(originalAfter?.customerMessage, originalBefore.customerMessage);
    expect(originalAfter?.createdAt, originalBefore.createdAt);
    expect(originalAfter?.updatedAt, originalBefore.updatedAt);
    expect(originalAfter?.receivedAt, originalBefore.receivedAt);
    expect(originalAfter?.readyAt, originalBefore.readyAt);
    expect(originalAfter?.deliveredAt, originalBefore.deliveredAt);
  });

  test('normal repair creation always creates no warranty parent', () async {
    final repair = await repository.createRepair(
      CreateRepairInput(reportedProblem: 'Does not power on'),
    );

    expect(repair.parentRepairId, isNull);
  });

  test('warranty return creation fails from invalid parent statuses', () async {
    for (final status in [
      RepairStatus.received,
      RepairStatus.diagnosing,
      RepairStatus.waitingForCustomerApproval,
      RepairStatus.waitingForPart,
      RepairStatus.repairing,
      RepairStatus.readyForPickup,
      RepairStatus.cancelled,
    ]) {
      final parent = await repairInStatus(
        repository,
        status,
        () => currentTime,
        (value) => currentTime = value,
      );

      expect(
        () => repository.createWarrantyReturn(
          CreateWarrantyReturnInput(
            originalRepairId: parent.id!,
            reportedProblem: 'Returned problem',
          ),
        ),
        throwsA(isA<RepairNotEligibleForWarrantyReturnException>()),
        reason: 'status ${status.name}',
      );
    }
  });

  test('missing parent creates no row and does not consume sequence', () async {
    expect(
      () => repository.createWarrantyReturn(
        CreateWarrantyReturnInput(
          originalRepairId: 999,
          reportedProblem: 'Returned problem',
        ),
      ),
      throwsA(isA<WarrantyParentRepairNotFoundException>()),
    );

    final count = await database
        .customSelect('SELECT COUNT(*) AS count FROM repairs')
        .getSingle();
    final sequence = await database
        .customSelect(
          'SELECT last_used_sequence FROM repair_code_sequence WHERE id = 1',
        )
        .getSingleOrNull();
    final normal = await repository.createRepair(
      CreateRepairInput(reportedProblem: 'Normal repair'),
    );

    expect(count.read<int>('count'), 0);
    expect(sequence, isNull);
    expect(normal.repairCode, 'REP-0001');
  });

  test(
    'warranty return cannot become parent of another warranty return',
    () async {
      final original = await deliveredOriginalRepair(
        repository,
        () => currentTime,
        (value) => currentTime = value,
      );
      final firstReturn = await repository.createWarrantyReturn(
        CreateWarrantyReturnInput(
          originalRepairId: original.id!,
          reportedProblem: 'Returned problem',
        ),
      );
      final deliveredReturn = await moveToStatus(
        repository,
        firstReturn,
        RepairStatus.delivered,
        () => currentTime,
        (value) => currentTime = value,
      );
      final originalBefore = (await repository.getRepairById(original.id!))!;
      final returnBefore = (await repository.getRepairById(firstReturn.id!))!;

      expect(
        () => repository.createWarrantyReturn(
          CreateWarrantyReturnInput(
            originalRepairId: deliveredReturn.id!,
            reportedProblem: 'Returned again',
          ),
        ),
        throwsA(isA<WarrantyReturnFromWarrantyReturnNotAllowedException>()),
      );

      final count = await database
          .customSelect('SELECT COUNT(*) AS count FROM repairs')
          .getSingle();
      final nextNormal = await repository.createRepair(
        CreateRepairInput(reportedProblem: 'Next normal repair'),
      );
      final originalAfter = await repository.getRepairById(original.id!);
      final returnAfter = await repository.getRepairById(firstReturn.id!);

      expect(count.read<int>('count'), 2);
      expect(nextNormal.repairCode, 'REP-0003');
      expect(originalAfter?.updatedAt, originalBefore.updatedAt);
      expect(originalAfter?.status, originalBefore.status);
      expect(returnAfter?.updatedAt, returnBefore.updatedAt);
      expect(returnAfter?.status, returnBefore.status);
    },
  );

  test('warranty return uses the next global repair sequence', () async {
    final first = await repository.createRepair(
      CreateRepairInput(reportedProblem: 'First repair'),
    );
    final second = await repository.createRepair(
      CreateRepairInput(reportedProblem: 'Second repair'),
    );
    final deliveredFirst = await moveToStatus(
      repository,
      first,
      RepairStatus.delivered,
      () => currentTime,
      (value) => currentTime = value,
    );

    final warrantyReturn = await repository.createWarrantyReturn(
      CreateWarrantyReturnInput(
        originalRepairId: deliveredFirst.id!,
        reportedProblem: 'Returned problem',
      ),
    );

    expect(first.repairCode, 'REP-0001');
    expect(second.repairCode, 'REP-0002');
    expect(warrantyReturn.repairCode, 'REP-0003');
  });

  test(
    'direct warranty return query returns newest direct children only',
    () async {
      final original = await deliveredOriginalRepair(
        repository,
        () => currentTime,
        (value) => currentTime = value,
      );
      final unrelatedOriginal = await deliveredOriginalRepair(
        repository,
        () => currentTime,
        (value) => currentTime = value,
      );

      currentTime = DateTime.utc(2026, 1, 5, 9);
      final older = await repository.createWarrantyReturn(
        CreateWarrantyReturnInput(
          originalRepairId: original.id!,
          reportedProblem: 'Older return',
          receivedAt: DateTime.utc(2026, 1, 5, 9),
        ),
      );
      currentTime = DateTime.utc(2026, 1, 6, 9);
      final newer = await repository.createWarrantyReturn(
        CreateWarrantyReturnInput(
          originalRepairId: original.id!,
          reportedProblem: 'Newer return',
          receivedAt: DateTime.utc(2026, 1, 6, 9),
        ),
      );
      await repository.createWarrantyReturn(
        CreateWarrantyReturnInput(
          originalRepairId: unrelatedOriginal.id!,
          reportedProblem: 'Unrelated return',
          receivedAt: DateTime.utc(2026, 1, 7, 9),
        ),
      );

      final returns = await repository.getWarrantyReturnsForRepair(
        original.id!,
      );
      final empty = await repository.getWarrantyReturnsForRepair(999);

      expect([for (final repair in returns) repair.id], [newer.id, older.id]);
      expect(empty, isEmpty);
    },
  );

  test('blank warranty reported problem is rejected', () {
    expect(
      () => CreateWarrantyReturnInput(
        originalRepairId: 1,
        reportedProblem: '   ',
      ),
      throwsArgumentError,
    );
  });
}

Future<Repair> deliveredOriginalRepair(
  DriftRepairRepository repository,
  DateTime Function() currentTime,
  void Function(DateTime value) setCurrentTime,
) async {
  final repair = await repository.createRepair(
    CreateRepairInput(
      customerName: 'Amina',
      customerPhone: '0555000000',
      deviceType: 'Laptop',
      brand: 'Lenovo',
      model: 'T14',
      reportedProblem: 'Battery replacement',
      receivedAccessories: 'Bag',
      deviceAccessInfo: 'PIN 1234',
      internalNotes: 'Original internal note',
      customerMessage: 'Original customer message',
    ),
  );

  final diagnosing = await moveToStatus(
    repository,
    repair,
    RepairStatus.diagnosing,
    currentTime,
    setCurrentTime,
  );
  setCurrentTime(currentTime().add(const Duration(hours: 1)));
  await repository.proposePrice(
    ProposeRepairPriceInput(repairId: repair.id!, priceAmount: 5000),
  );
  setCurrentTime(currentTime().add(const Duration(hours: 1)));
  await repository.changeStatus(
    ChangeRepairStatusInput(
      repairId: diagnosing.id!,
      targetStatus: RepairStatus.waitingForCustomerApproval,
    ),
  );
  setCurrentTime(currentTime().add(const Duration(hours: 1)));
  await repository.recordCustomerPriceDecision(
    RecordCustomerPriceDecisionInput(
      repairId: repair.id!,
      decision: CustomerPriceDecision.approved,
    ),
  );

  return moveToStatus(
    repository,
    repair,
    RepairStatus.delivered,
    currentTime,
    setCurrentTime,
    currentStatus: RepairStatus.waitingForCustomerApproval,
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

  return moveToStatus(
    repository,
    repair,
    targetStatus,
    currentTime,
    setCurrentTime,
  );
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
  if (currentStatus == RepairStatus.waitingForCustomerApproval &&
      targetStatus == RepairStatus.delivered) {
    return const [
      RepairStatus.repairing,
      RepairStatus.readyForPickup,
      RepairStatus.delivered,
    ];
  }

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
