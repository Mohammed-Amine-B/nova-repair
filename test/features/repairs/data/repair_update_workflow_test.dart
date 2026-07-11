import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_repair/database/app_database.dart';
import 'package:nova_repair/database/database_provider.dart';
import 'package:nova_repair/features/repairs/data/datasources/repair_code_sequence_local_data_source.dart';
import 'package:nova_repair/features/repairs/data/datasources/repair_local_data_source.dart';
import 'package:nova_repair/features/repairs/data/repositories/drift_repair_repository.dart';
import 'package:nova_repair/features/repairs/domain/customer_price_decision.dart';
import 'package:nova_repair/features/repairs/domain/entities/change_repair_status_input.dart';
import 'package:nova_repair/features/repairs/domain/entities/create_repair_input.dart';
import 'package:nova_repair/features/repairs/domain/entities/create_warranty_return_input.dart';
import 'package:nova_repair/features/repairs/domain/entities/propose_repair_price_input.dart';
import 'package:nova_repair/features/repairs/domain/entities/repair.dart';
import 'package:nova_repair/features/repairs/domain/entities/update_repair_input.dart';
import 'package:nova_repair/features/repairs/domain/errors/repair_status_workflow_exception.dart';
import 'package:nova_repair/features/repairs/domain/errors/repair_update_workflow_exception.dart';
import 'package:nova_repair/features/repairs/domain/repair_status.dart';
import 'package:nova_repair/features/repairs/repair_providers.dart';
import 'package:nova_repair/features/settings/data/datasources/shop_settings_local_data_source.dart';

void main() {
  late AppDatabase database;
  late DriftRepairRepository repository;
  late DateTime currentTime;

  setUp(() {
    currentTime = DateTime.utc(2026, 7, 5, 9);
    database = AppDatabase(NativeDatabase.memory());
    repository = _repository(database, () => currentTime);
  });

  tearDown(() async {
    await database.close();
  });

  test('updates all normal editable repair details', () async {
    final repair = await repository.createRepair(
      CreateRepairInput(
        deviceType: 'Laptop',
        reportedProblem: 'Original problem',
      ),
    );
    currentTime = DateTime.utc(2026, 7, 5, 10);

    final updated = await repository.updateRepairDetails(
      UpdateRepairInput(
        repairId: repair.id!,
        customerName: '  Amina  ',
        customerPhone: ' 0550 111 222 ',
        deviceType: ' Desktop ',
        brand: ' Dell ',
        model: ' OptiPlex  ',
        reportedProblem: ' Does not boot ',
        receivedAccessories: ' Power cable ',
        deviceAccessInfo: ' PIN 1234 ',
        internalNotes: ' Check SSD first ',
        customerMessage: ' Diagnosis in progress ',
      ),
    );

    expect(updated.customerName, 'Amina');
    expect(updated.customerPhone, '0550 111 222');
    expect(updated.deviceType, 'Desktop');
    expect(updated.brand, 'Dell');
    expect(updated.model, 'OptiPlex');
    expect(updated.reportedProblem, 'Does not boot');
    expect(updated.receivedAccessories, 'Power cable');
    expect(updated.deviceAccessInfo, 'PIN 1234');
    expect(updated.internalNotes, 'Check SSD first');
    expect(updated.customerMessage, 'Diagnosis in progress');
    expect(updated.updatedAt, currentTime);
    expect(updated.updatedAt.isUtc, isTrue);
  });

  test('validates required update fields', () {
    expect(
      () => UpdateRepairInput(
        repairId: 1,
        deviceType: '',
        reportedProblem: 'Problem',
      ),
      throwsA(
        isA<InvalidRepairUpdateInputException>().having(
          (error) => error.fieldName,
          'fieldName',
          'deviceType',
        ),
      ),
    );
    expect(
      () => UpdateRepairInput(
        repairId: 1,
        deviceType: '   ',
        reportedProblem: 'Problem',
      ),
      throwsA(isA<InvalidRepairUpdateInputException>()),
    );
    expect(
      () => UpdateRepairInput(
        repairId: 1,
        deviceType: 'Laptop',
        reportedProblem: '',
      ),
      throwsA(
        isA<InvalidRepairUpdateInputException>().having(
          (error) => error.fieldName,
          'fieldName',
          'reportedProblem',
        ),
      ),
    );
    expect(
      () => UpdateRepairInput(
        repairId: 1,
        deviceType: 'Laptop',
        reportedProblem: '   ',
      ),
      throwsA(isA<InvalidRepairUpdateInputException>()),
    );
  });

  test('blank optional fields become null', () async {
    final repair = await repository.createRepair(
      CreateRepairInput(
        customerName: 'Existing',
        customerPhone: '0550',
        deviceType: 'Laptop',
        brand: 'HP',
        model: 'Pavilion',
        reportedProblem: 'Original problem',
        receivedAccessories: 'Charger',
        deviceAccessInfo: 'Password',
        internalNotes: 'Internal',
        customerMessage: 'Visible',
      ),
    );

    final updated = await repository.updateRepairDetails(
      UpdateRepairInput(
        repairId: repair.id!,
        customerName: ' ',
        customerPhone: '',
        deviceType: 'Laptop',
        brand: '   ',
        model: '',
        reportedProblem: 'Updated problem',
        receivedAccessories: ' ',
        deviceAccessInfo: '',
        internalNotes: ' ',
        customerMessage: '',
      ),
    );

    expect(updated.customerName, isNull);
    expect(updated.customerPhone, isNull);
    expect(updated.brand, isNull);
    expect(updated.model, isNull);
    expect(updated.receivedAccessories, isNull);
    expect(updated.deviceAccessInfo, isNull);
    expect(updated.internalNotes, isNull);
    expect(updated.customerMessage, isNull);
  });

  test('protected workflow fields remain unchanged', () async {
    final repair = await _repairWithPriceAndDeliveredStatus(repository, (
      value,
    ) {
      currentTime = value;
    });
    final original = await repository.getRepairById(repair.id!);
    currentTime = DateTime.utc(2026, 7, 8, 16);

    final updated = await repository.updateRepairDetails(
      UpdateRepairInput(
        repairId: repair.id!,
        customerName: 'Updated customer',
        deviceType: 'Updated device',
        reportedProblem: 'Updated problem',
      ),
    );

    expect(updated.repairCode, original!.repairCode);
    expect(updated.status, original.status);
    expect(updated.customerPriceDecision, original.customerPriceDecision);
    expect(updated.priceAmount, original.priceAmount);
    expect(updated.parentRepairId, original.parentRepairId);
    expect(updated.receivedAt, original.receivedAt);
    expect(updated.readyAt, original.readyAt);
    expect(updated.deliveredAt, original.deliveredAt);
    expect(updated.createdAt, original.createdAt);
    expect(updated.updatedAt, currentTime);
  });

  test('price workflow state is preserved by normal detail update', () async {
    final repair = await repository.createRepair(
      CreateRepairInput(deviceType: 'Laptop', reportedProblem: 'Problem'),
    );
    currentTime = DateTime.utc(2026, 7, 5, 10);
    final diagnosing = await repository.changeStatus(
      ChangeRepairStatusInput(
        repairId: repair.id!,
        targetStatus: RepairStatus.diagnosing,
      ),
    );
    final priced = await repository.proposePrice(
      ProposeRepairPriceInput(repairId: diagnosing.id!, priceAmount: 6500),
    );

    final updated = await repository.updateRepairDetails(
      UpdateRepairInput(
        repairId: priced.id!,
        deviceType: 'Laptop',
        reportedProblem: 'Updated after price proposal',
      ),
    );

    expect(updated.priceAmount, 6500);
    expect(updated.customerPriceDecision, CustomerPriceDecision.pending);
  });

  test('warranty parent relationship is preserved', () async {
    final original = await _deliveredRepair(repository, (value) {
      currentTime = value;
    });
    final warranty = await repository.createWarrantyReturn(
      CreateWarrantyReturnInput(
        originalRepairId: original.id!,
        reportedProblem: 'Returned with same issue',
      ),
    );

    final updated = await repository.updateRepairDetails(
      UpdateRepairInput(
        repairId: warranty.id!,
        deviceType: 'Warranty device',
        reportedProblem: 'Updated warranty problem',
      ),
    );

    expect(updated.parentRepairId, original.id);
  });

  test('updates normal details for delivered and cancelled repairs', () async {
    final delivered = await _deliveredRepair(repository, (value) {
      currentTime = value;
    });
    final cancelledBase = await repository.createRepair(
      CreateRepairInput(deviceType: 'Phone', reportedProblem: 'No display'),
    );
    final cancelled = await repository.changeStatus(
      ChangeRepairStatusInput(
        repairId: cancelledBase.id!,
        targetStatus: RepairStatus.cancelled,
      ),
    );

    final updatedDelivered = await repository.updateRepairDetails(
      UpdateRepairInput(
        repairId: delivered.id!,
        deviceType: 'Delivered device',
        reportedProblem: 'Corrected delivered notes',
      ),
    );
    final updatedCancelled = await repository.updateRepairDetails(
      UpdateRepairInput(
        repairId: cancelled.id!,
        deviceType: 'Cancelled device',
        reportedProblem: 'Corrected cancelled notes',
      ),
    );

    expect(updatedDelivered.status, RepairStatus.delivered);
    expect(updatedDelivered.deviceType, 'Delivered device');
    expect(updatedCancelled.status, RepairStatus.cancelled);
    expect(updatedCancelled.deviceType, 'Cancelled device');
  });

  test('missing repair fails with focused not-found error', () async {
    expect(
      () => repository.updateRepairDetails(
        UpdateRepairInput(
          repairId: 999,
          deviceType: 'Laptop',
          reportedProblem: 'Problem',
        ),
      ),
      throwsA(isA<RepairNotFoundException>()),
    );
  });

  test('invalid input does not modify persisted repair', () async {
    final repair = await repository.createRepair(
      CreateRepairInput(
        customerName: 'Original',
        deviceType: 'Laptop',
        reportedProblem: 'Original problem',
      ),
    );

    expect(
      () => UpdateRepairInput(
        repairId: repair.id!,
        customerName: 'Changed',
        deviceType: ' ',
        reportedProblem: 'Changed problem',
      ),
      throwsA(isA<InvalidRepairUpdateInputException>()),
    );

    final reloaded = await repository.getRepairById(repair.id!);
    expect(reloaded?.customerName, 'Original');
    expect(reloaded?.reportedProblem, 'Original problem');
    expect(reloaded?.updatedAt, repair.updatedAt);
  });

  test('update use case is exposed through Riverpod', () async {
    final repair = await repository.createRepair(
      CreateRepairInput(deviceType: 'Tablet', reportedProblem: 'Broken port'),
    );
    final container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(database)],
    );
    addTearDown(container.dispose);

    final updated = await container
        .read(updateRepairUseCaseProvider)
        .call(
          UpdateRepairInput(
            repairId: repair.id!,
            deviceType: 'Tablet',
            reportedProblem: 'Updated broken port',
          ),
        );

    expect(updated.reportedProblem, 'Updated broken port');
  });
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

Future<Repair> _repairWithPriceAndDeliveredStatus(
  DriftRepairRepository repository,
  void Function(DateTime value) setCurrentTime,
) async {
  final repair = await repository.createRepair(
    CreateRepairInput(deviceType: 'Laptop', reportedProblem: 'Problem'),
  );
  setCurrentTime(DateTime.utc(2026, 7, 5, 10));
  final diagnosing = await repository.changeStatus(
    ChangeRepairStatusInput(
      repairId: repair.id!,
      targetStatus: RepairStatus.diagnosing,
    ),
  );
  await repository.proposePrice(
    ProposeRepairPriceInput(repairId: diagnosing.id!, priceAmount: 4200),
  );
  setCurrentTime(DateTime.utc(2026, 7, 5, 11));
  final waitingApproval = await repository.changeStatus(
    ChangeRepairStatusInput(
      repairId: repair.id!,
      targetStatus: RepairStatus.waitingForCustomerApproval,
    ),
  );
  setCurrentTime(DateTime.utc(2026, 7, 5, 12));
  final repairing = await repository.changeStatus(
    ChangeRepairStatusInput(
      repairId: waitingApproval.id!,
      targetStatus: RepairStatus.repairing,
    ),
  );
  setCurrentTime(DateTime.utc(2026, 7, 6, 12));
  final ready = await repository.changeStatus(
    ChangeRepairStatusInput(
      repairId: repairing.id!,
      targetStatus: RepairStatus.readyForPickup,
    ),
  );
  setCurrentTime(DateTime.utc(2026, 7, 7, 12));
  return repository.changeStatus(
    ChangeRepairStatusInput(
      repairId: ready.id!,
      targetStatus: RepairStatus.delivered,
    ),
  );
}

Future<Repair> _deliveredRepair(
  DriftRepairRepository repository,
  void Function(DateTime value) setCurrentTime,
) async {
  final repair = await repository.createRepair(
    CreateRepairInput(deviceType: 'Phone', reportedProblem: 'No power'),
  );
  setCurrentTime(DateTime.utc(2026, 7, 5, 10));
  final diagnosing = await repository.changeStatus(
    ChangeRepairStatusInput(
      repairId: repair.id!,
      targetStatus: RepairStatus.diagnosing,
    ),
  );
  setCurrentTime(DateTime.utc(2026, 7, 5, 11));
  final repairing = await repository.changeStatus(
    ChangeRepairStatusInput(
      repairId: diagnosing.id!,
      targetStatus: RepairStatus.repairing,
    ),
  );
  setCurrentTime(DateTime.utc(2026, 7, 6, 12));
  final ready = await repository.changeStatus(
    ChangeRepairStatusInput(
      repairId: repairing.id!,
      targetStatus: RepairStatus.readyForPickup,
    ),
  );
  setCurrentTime(DateTime.utc(2026, 7, 7, 12));
  return repository.changeStatus(
    ChangeRepairStatusInput(
      repairId: ready.id!,
      targetStatus: RepairStatus.delivered,
    ),
  );
}
