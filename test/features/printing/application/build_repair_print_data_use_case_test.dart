import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_repair/database/app_database.dart';
import 'package:nova_repair/features/printing/application/build_repair_print_data_use_case.dart';
import 'package:nova_repair/features/printing/domain/entities/device_label_data.dart';
import 'package:nova_repair/features/printing/domain/entities/customer_ticket_data.dart';
import 'package:nova_repair/features/repairs/data/datasources/repair_code_sequence_local_data_source.dart';
import 'package:nova_repair/features/repairs/data/datasources/repair_local_data_source.dart';
import 'package:nova_repair/features/repairs/data/repositories/drift_repair_repository.dart';
import 'package:nova_repair/features/repairs/domain/customer_price_decision.dart';
import 'package:nova_repair/features/repairs/domain/entities/change_repair_status_input.dart';
import 'package:nova_repair/features/repairs/domain/entities/create_repair_input.dart';
import 'package:nova_repair/features/repairs/domain/entities/create_warranty_return_input.dart';
import 'package:nova_repair/features/repairs/domain/entities/repair.dart';
import 'package:nova_repair/features/repairs/domain/errors/repair_status_workflow_exception.dart';
import 'package:nova_repair/features/repairs/domain/repair_status.dart';
import 'package:nova_repair/features/repairs/domain/services/device_display_name_formatter.dart';
import 'package:nova_repair/features/settings/data/datasources/shop_settings_local_data_source.dart';
import 'package:nova_repair/features/settings/data/repositories/drift_shop_settings_repository.dart';
import 'package:nova_repair/features/settings/domain/entities/shop_settings.dart';

void main() {
  group('BuildRepairPrintDataUseCase', () {
    late AppDatabase database;
    late DriftRepairRepository repairRepository;
    late DriftShopSettingsRepository settingsRepository;
    late BuildRepairPrintDataUseCase useCase;
    late DateTime currentTime;

    setUp(() {
      currentTime = DateTime.utc(2026, 1, 1, 9);
      database = AppDatabase(_inMemoryDatabase());
      repairRepository = _repairRepository(database, () => currentTime);
      settingsRepository = _settingsRepository(database, () => currentTime);
      useCase = BuildRepairPrintDataUseCase(
        repairRepository,
        settingsRepository,
      );
    });

    tearDown(() async {
      await database.close();
    });

    test('builds customer ticket data from repair and shop settings', () async {
      await _saveCustomSettings(settingsRepository, () => currentTime);
      final repair = await repairRepository.createRepair(
        CreateRepairInput(
          customerName: 'Amina',
          customerPhone: '0555000000',
          deviceType: 'Laptop',
          brand: 'HP',
          model: 'EliteBook 840',
          reportedProblem: 'Does not power on',
          receivedAccessories: 'Charger and bag',
          deviceAccessInfo: 'PIN 1234',
          priceAmount: 4500,
          internalNotes: 'Do not print this internal note',
          customerMessage: 'Do not put this status message on ticket data',
          receivedAt: DateTime.utc(2026, 1, 1, 8, 30),
        ),
      );

      final printData = await useCase(repair.id!);
      final ticket = printData.customerTicket;

      expect(ticket.shopName, 'Nova Tech Repair');
      expect(ticket.shopSubtitle, 'Repair Center');
      expect(ticket.shopPhone, '0555000000');
      expect(ticket.shopAddress, 'Algiers Center');
      expect(ticket.logoPath, '/local/logo.png');
      expect(ticket.repairCode, repair.repairCode);
      expect(ticket.receivedAt, DateTime.utc(2026, 1, 1, 8, 30));
      expect(ticket.receivedAt.isUtc, isTrue);
      expect(ticket.status, RepairStatus.received);
      expect(ticket.customerName, 'Amina');
      expect(ticket.customerPhone, '0555000000');
      expect(ticket.deviceDisplayName, 'HP EliteBook 840');
      expect(ticket.deviceType, 'Laptop');
      expect(ticket.reportedProblem, 'Does not power on');
      expect(ticket.receivedAccessories, 'Charger and bag');
      expect(ticket.priceAmount, 4500);
      expect(ticket.customerPriceDecision, CustomerPriceDecision.notRequested);
      expect(ticket.ticketFooter, 'Thank you for choosing Nova.');
      expect(ticket.warrantyTerms, 'Warranty applies to repaired parts only.');
      expect(ticket.isWarrantyReturn, isFalse);
      expect(ticket.originalRepairCode, isNull);
      expect(_ticketStrings(ticket), isNot(contains('PIN 1234')));
      expect(
        _ticketStrings(ticket),
        isNot(contains('Do not print this internal note')),
      );
      expect(
        _ticketStrings(ticket),
        isNot(contains('Do not put this status message on ticket data')),
      );
    });

    test('builds compact device label data without sensitive fields', () async {
      final repair = await repairRepository.createRepair(
        CreateRepairInput(
          customerName: 'Karim',
          customerPhone: '0666000000',
          deviceType: 'Phone',
          brand: 'Samsung',
          model: 'Galaxy S23',
          reportedProblem: 'Broken screen',
          receivedAccessories: 'Case',
          deviceAccessInfo: 'Pattern: top left',
          priceAmount: 9000,
          internalNotes: 'Internal diagnostic note',
          customerMessage: 'Ready soon',
          receivedAt: DateTime.utc(2026, 1, 2, 10),
        ),
      );

      final label = (await useCase(repair.id!)).deviceLabel;

      expect(label.repairCode, repair.repairCode);
      expect(label.receivedAt, DateTime.utc(2026, 1, 2, 10));
      expect(label.receivedAt.isUtc, isTrue);
      expect(label.deviceDisplayName, 'Samsung Galaxy S23');
      expect(label.customerName, 'Karim');
      expect(label.customerPhone, '0666000000');
      expect(label.reportedProblem, 'Broken screen');
      expect(_labelStrings(label), isNot(contains('Pattern: top left')));
      expect(_labelStrings(label), isNot(contains('Internal diagnostic note')));
      expect(_labelStrings(label), isNot(contains('Ready soon')));
      expect(_labelStrings(label), isNot(contains('9000')));
    });

    test('normal repair is not marked as a warranty return', () async {
      final repair = await repairRepository.createRepair(
        CreateRepairInput(reportedProblem: 'Does not power on'),
      );

      final ticket = (await useCase(repair.id!)).customerTicket;

      expect(ticket.isWarrantyReturn, isFalse);
      expect(ticket.originalRepairCode, isNull);
    });

    test('warranty return includes original repair code', () async {
      final original = await repairRepository.createRepair(
        CreateRepairInput(reportedProblem: 'Battery replacement'),
      );
      final deliveredOriginal = await moveToStatus(
        repairRepository,
        original,
        RepairStatus.delivered,
        () => currentTime,
        (value) => currentTime = value,
      );
      currentTime = currentTime.add(const Duration(hours: 1));
      final warrantyReturn = await repairRepository.createWarrantyReturn(
        CreateWarrantyReturnInput(
          originalRepairId: deliveredOriginal.id!,
          reportedProblem: 'Battery drains again',
        ),
      );

      final ticket = (await useCase(warrantyReturn.id!)).customerTicket;

      expect(ticket.isWarrantyReturn, isTrue);
      expect(ticket.originalRepairCode, original.repairCode);
    });

    test('missing warranty parent does not prevent print data build', () async {
      await database.close();
      database = AppDatabase(NativeDatabase.memory());
      repairRepository = _repairRepository(database, () => currentTime);
      settingsRepository = _settingsRepository(database, () => currentTime);
      useCase = BuildRepairPrintDataUseCase(
        repairRepository,
        settingsRepository,
      );
      final id = await database
          .into(database.repairs)
          .insert(
            RepairsCompanion.insert(
              repairCode: 'REP-9999',
              reportedProblem: 'Legacy warranty return',
              status: RepairStatus.received.databaseValue,
              customerPriceDecision: const Value('not_requested'),
              parentRepairId: const Value(999),
              createdAt: DateTime.utc(2026, 1, 1),
              updatedAt: DateTime.utc(2026, 1, 1),
              receivedAt: DateTime.utc(2026, 1, 1),
            ),
          );

      final ticket = (await useCase(id)).customerTicket;

      expect(ticket.isWarrantyReturn, isTrue);
      expect(ticket.originalRepairCode, isNull);
    });

    test('missing repair fails clearly', () {
      expect(() => useCase(999), throwsA(isA<RepairNotFoundException>()));
    });

    test('default settings are used when shop is not configured', () async {
      final repair = await repairRepository.createRepair(
        CreateRepairInput(reportedProblem: 'Does not power on'),
      );

      final ticket = (await useCase(repair.id!)).customerTicket;

      expect(ticket.shopName, ShopSettings.defaultShopName);
      expect(ticket.shopSubtitle, isNull);
      expect(ticket.shopPhone, isNull);
      expect(ticket.shopAddress, isNull);
      expect(ticket.logoPath, isNull);
      expect(ticket.ticketFooter, isNull);
      expect(ticket.warrantyTerms, isNull);
    });

    test('print data reflects current repair status', () async {
      final repair = await repairRepository.createRepair(
        CreateRepairInput(reportedProblem: 'Does not power on'),
      );

      expect(
        (await useCase(repair.id!)).customerTicket.status,
        RepairStatus.received,
      );

      currentTime = DateTime.utc(2026, 1, 1, 10);
      await repairRepository.changeStatus(
        ChangeRepairStatusInput(
          repairId: repair.id!,
          targetStatus: RepairStatus.diagnosing,
        ),
      );

      expect(
        (await useCase(repair.id!)).customerTicket.status,
        RepairStatus.diagnosing,
      );
    });
  });

  group('DeviceDisplayNameFormatter', () {
    const formatter = DeviceDisplayNameFormatter();

    test('uses brand and model when both exist', () {
      expect(
        formatter.format(brand: 'HP', model: 'EliteBook 840'),
        'HP EliteBook 840',
      );
    });

    test('uses brand and device type when model is missing', () {
      expect(
        formatter.format(brand: 'Lenovo', deviceType: 'Laptop'),
        'Lenovo Laptop',
      );
    });

    test('uses model only when brand is missing', () {
      expect(formatter.format(model: 'Galaxy S23'), 'Galaxy S23');
    });

    test('uses device type only when brand and model are missing', () {
      expect(formatter.format(deviceType: 'Laptop'), 'Laptop');
    });

    test('uses fallback when all device fields are missing', () {
      expect(formatter.format(), 'Device');
    });

    test('avoids duplicate brand prefix in model or device type', () {
      expect(
        formatter.format(brand: 'Samsung', model: 'Samsung Galaxy S23'),
        'Samsung Galaxy S23',
      );
      expect(
        formatter.format(brand: 'HP', deviceType: 'HP Laptop'),
        'HP Laptop',
      );
    });
  });
}

Future<void> _saveCustomSettings(
  DriftShopSettingsRepository settingsRepository,
  DateTime Function() currentTime,
) async {
  final defaults = await settingsRepository.getSettings();
  await settingsRepository.saveSettings(
    defaults.copyWith(
      shopName: 'Nova Tech Repair',
      shopSubtitle: 'Repair Center',
      phoneNumber: '0555000000',
      address: 'Algiers Center',
      logoPath: '/local/logo.png',
      ticketFooter: 'Thank you for choosing Nova.',
      warrantyTerms: 'Warranty applies to repaired parts only.',
      updatedAt: currentTime(),
    ),
  );
}

List<String> _ticketStrings(CustomerTicketData ticket) {
  final values = [
    ticket.shopName,
    ticket.repairCode,
    ticket.deviceDisplayName,
    ticket.reportedProblem,
  ];
  void addOptional(String? value) {
    if (value != null) {
      values.add(value);
    }
  }

  addOptional(ticket.shopPhone);
  addOptional(ticket.shopSubtitle);
  addOptional(ticket.shopAddress);
  addOptional(ticket.logoPath);
  addOptional(ticket.ticketFooter);
  addOptional(ticket.warrantyTerms);
  addOptional(ticket.customerName);
  addOptional(ticket.customerPhone);
  addOptional(ticket.receivedAccessories);
  addOptional(ticket.originalRepairCode);

  return values;
}

List<String> _labelStrings(DeviceLabelData label) {
  final values = [
    label.repairCode,
    label.deviceDisplayName,
    label.reportedProblem,
  ];
  void addOptional(String? value) {
    if (value != null) {
      values.add(value);
    }
  }

  addOptional(label.customerName);
  addOptional(label.customerPhone);

  return values;
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

DriftRepairRepository _repairRepository(
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

DriftShopSettingsRepository _settingsRepository(
  AppDatabase database,
  DateTime Function() now,
) {
  return DriftShopSettingsRepository(
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
