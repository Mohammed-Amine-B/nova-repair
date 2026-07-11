import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_repair/database/app_database.dart';
import 'package:nova_repair/features/repairs/data/datasources/repair_code_sequence_local_data_source.dart';
import 'package:nova_repair/features/repairs/data/datasources/repair_local_data_source.dart';
import 'package:nova_repair/features/repairs/data/repositories/drift_repair_repository.dart';
import 'package:nova_repair/features/repairs/domain/customer_price_decision.dart';
import 'package:nova_repair/features/repairs/domain/entities/create_repair_input.dart';
import 'package:nova_repair/features/repairs/domain/repair_status.dart';
import 'package:nova_repair/features/settings/data/datasources/shop_settings_local_data_source.dart';
import 'package:nova_repair/features/settings/data/repositories/drift_shop_settings_repository.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

void main() {
  group('Repair creation workflow', () {
    late AppDatabase database;
    late DriftRepairRepository repairRepository;
    late DriftShopSettingsRepository settingsRepository;
    late DateTime currentTime;

    setUp(() {
      currentTime = DateTime.utc(2026, 1, 1, 9);
      database = AppDatabase(_inMemoryDatabase());
      final repairLocalDataSource = RepairLocalDataSource(database);
      final settingsLocalDataSource = ShopSettingsLocalDataSource(database);

      repairRepository = DriftRepairRepository(
        database,
        repairLocalDataSource,
        RepairCodeSequenceLocalDataSource(database),
        settingsLocalDataSource,
        now: () => currentTime,
      );
      settingsRepository = DriftShopSettingsRepository(
        settingsLocalDataSource,
        now: () => currentTime,
      );
    });

    tearDown(() async {
      await database.close();
    });

    test('fresh sequence starts with REP-0001 then REP-0002', () async {
      final first = await repairRepository.createRepair(
        CreateRepairInput(reportedProblem: 'Does not power on'),
      );
      final second = await repairRepository.createRepair(
        CreateRepairInput(reportedProblem: 'Screen is cracked'),
      );

      expect(first.repairCode, 'REP-0001');
      expect(second.repairCode, 'REP-0002');
      expect(first.id, isNot(second.id));
    });

    test(
      'generated repair uses current settings and default repair states',
      () async {
        final defaults = await settingsRepository.getSettings();
        await settingsRepository.saveSettings(
          defaults.copyWith(
            repairCodePrefix: ' fix ',
            repairCodeNumberWidth: 5,
          ),
        );

        final repair = await repairRepository.createRepair(
          CreateRepairInput(
            customerName: ' Amina ',
            customerPhone: ' 0555000000 ',
            deviceType: ' Laptop ',
            brand: ' Lenovo ',
            model: ' T14 ',
            reportedProblem: ' Does not power on ',
            receivedAccessories: ' Charger ',
            deviceAccessInfo: ' 1234 ',
            priceAmount: 12500,
            internalNotes: ' Internal note ',
            customerMessage: ' Customer message ',
            receivedAt: DateTime.utc(2025, 12, 31, 8),
          ),
        );

        expect(repair.repairCode, 'FIX-00001');
        expect(repair.status, RepairStatus.received);
        expect(
          repair.customerPriceDecision,
          CustomerPriceDecision.notRequested,
        );
        expect(repair.customerName, 'Amina');
        expect(repair.customerPhone, '0555000000');
        expect(repair.deviceType, 'Laptop');
        expect(repair.brand, 'Lenovo');
        expect(repair.model, 'T14');
        expect(repair.reportedProblem, 'Does not power on');
        expect(repair.receivedAccessories, 'Charger');
        expect(repair.deviceAccessInfo, '1234');
        expect(repair.priceAmount, 12500);
        expect(repair.internalNotes, 'Internal note');
        expect(repair.customerMessage, 'Customer message');
        expect(repair.createdAt, currentTime);
        expect(repair.updatedAt, currentTime);
        expect(repair.receivedAt, DateTime.utc(2025, 12, 31, 8));
        expect(repair.createdAt.isUtc, isTrue);
        expect(repair.updatedAt.isUtc, isTrue);
        expect(repair.receivedAt.isUtc, isTrue);
      },
    );

    test('prefix changes do not reset the global sequence', () async {
      await repairRepository.createRepair(
        CreateRepairInput(reportedProblem: 'First'),
      );
      await repairRepository.createRepair(
        CreateRepairInput(reportedProblem: 'Second'),
      );

      final settings = await settingsRepository.getSettings();
      await settingsRepository.saveSettings(
        settings.copyWith(repairCodePrefix: 'FIX'),
      );

      final third = await repairRepository.createRepair(
        CreateRepairInput(reportedProblem: 'Third'),
      );

      expect(third.repairCode, 'FIX-0003');
    });

    test('number width changes do not reset the global sequence', () async {
      await repairRepository.createRepair(
        CreateRepairInput(reportedProblem: 'First'),
      );

      final settings = await settingsRepository.getSettings();
      await settingsRepository.saveSettings(
        settings.copyWith(repairCodeNumberWidth: 5),
      );

      final second = await repairRepository.createRepair(
        CreateRepairInput(reportedProblem: 'Second'),
      );

      expect(second.repairCode, 'REP-00002');
    });

    test(
      'width is minimum padding and does not truncate long sequence numbers',
      () async {
        await database
            .into(database.repairCodeSequenceTable)
            .insert(
              RepairCodeSequenceTableCompanion.insert(
                id: const Value(1),
                lastUsedSequence: 9999,
              ),
            );

        final repair = await repairRepository.createRepair(
          CreateRepairInput(reportedProblem: 'Large sequence'),
        );

        expect(repair.repairCode, 'REP-10000');
      },
    );

    test('sequence persists across database reopen', () async {
      final tempDirectory = await Directory.systemTemp.createTemp(
        'nova_repair_sequence_reopen_test_',
      );
      addTearDown(() => tempDirectory.delete(recursive: true));

      final file = File('${tempDirectory.path}/reopen.sqlite');
      await database.close();
      database = AppDatabase(_fileDatabase(file));
      repairRepository = _repairRepository(database, () => currentTime);

      final first = await repairRepository.createRepair(
        CreateRepairInput(reportedProblem: 'First'),
      );
      await database.close();

      database = AppDatabase(_fileDatabase(file));
      repairRepository = _repairRepository(database, () => currentTime);

      final second = await repairRepository.createRepair(
        CreateRepairInput(reportedProblem: 'Second'),
      );

      expect(first.repairCode, 'REP-0001');
      expect(second.repairCode, 'REP-0002');
    });

    test('existing compatible code conflicts are skipped safely', () async {
      await database
          .into(database.repairs)
          .insert(
            RepairsCompanion.insert(
              repairCode: 'REP-0002',
              reportedProblem: 'Existing manual repair',
              status: RepairStatus.received.databaseValue,
              createdAt: currentTime,
              updatedAt: currentTime,
              receivedAt: currentTime,
            ),
          );
      await database
          .into(database.repairCodeSequenceTable)
          .insert(
            RepairCodeSequenceTableCompanion.insert(
              id: const Value(1),
              lastUsedSequence: 1,
            ),
          );

      final repair = await repairRepository.createRepair(
        CreateRepairInput(reportedProblem: 'Next repair'),
      );

      expect(repair.repairCode, 'REP-0003');
    });
  });

  test('upgrades version 3 to 4 and initializes future codes safely', () async {
    final tempDirectory = await Directory.systemTemp.createTemp(
      'nova_repair_v3_to_v4_migration_test_',
    );
    addTearDown(() => tempDirectory.delete(recursive: true));

    final file = File('${tempDirectory.path}/migration.sqlite');
    final versionThreeDatabase = sqlite3.sqlite3.open(file.path);
    _createVersionThreeSchema(versionThreeDatabase);
    versionThreeDatabase.execute(
      "INSERT INTO shop_settings "
      "(id, shop_name, repair_code_prefix, repair_code_number_width, created_at, updated_at) "
      "VALUES (1, 'Configured Shop', 'REP', 4, 0, 0)",
    );
    versionThreeDatabase.execute(
      "INSERT INTO repairs "
      "(repair_code, reported_problem, status, customer_price_decision, created_at, updated_at, received_at) "
      "VALUES ('REP-0001', 'First existing repair', 'received', 'not_requested', 0, 0, 0)",
    );
    versionThreeDatabase.execute(
      "INSERT INTO repairs "
      "(repair_code, reported_problem, status, customer_price_decision, created_at, updated_at, received_at) "
      "VALUES ('REP-0007', 'Later existing repair', 'received', 'not_requested', 0, 0, 0)",
    );
    versionThreeDatabase.execute('PRAGMA user_version = 3');
    versionThreeDatabase.close();

    final database = AppDatabase(_fileDatabase(file));
    addTearDown(database.close);
    final repository = _repairRepository(
      database,
      () => DateTime.utc(2026, 1, 1, 9),
    );

    final sequenceTable = await database
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'repair_code_sequence'",
        )
        .getSingleOrNull();
    final existingRepair = await database
        .customSelect("SELECT id FROM repairs WHERE repair_code = 'REP-0007'")
        .getSingleOrNull();
    final settings = await database
        .customSelect("SELECT shop_name FROM shop_settings WHERE id = 1")
        .getSingleOrNull();
    final created = await repository.createRepair(
      CreateRepairInput(reportedProblem: 'New repair after migration'),
    );
    final userVersion = await database
        .customSelect('PRAGMA user_version')
        .getSingle();

    expect(sequenceTable, isNotNull);
    expect(existingRepair, isNotNull);
    expect(settings?.read<String>('shop_name'), 'Configured Shop');
    expect(created.repairCode, 'REP-0008');
    expect(userVersion.read<int>('user_version'), 7);
  });
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

NativeDatabase _inMemoryDatabase() {
  return NativeDatabase.memory(
    setup: (database) {
      database.execute('PRAGMA foreign_keys = ON');
    },
  );
}

NativeDatabase _fileDatabase(File file) {
  return NativeDatabase(
    file,
    setup: (database) {
      database.execute('PRAGMA foreign_keys = ON');
    },
  );
}

void _createVersionThreeSchema(sqlite3.Database database) {
  database.execute('''
CREATE TABLE repairs (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  repair_code TEXT NOT NULL UNIQUE,
  customer_name TEXT NULL,
  customer_phone TEXT NULL,
  device_type TEXT NULL,
  brand TEXT NULL,
  model TEXT NULL,
  reported_problem TEXT NOT NULL,
  received_accessories TEXT NULL,
  device_access_info TEXT NULL,
  status TEXT NOT NULL,
  price_amount INTEGER NULL CHECK(price_amount >= 0),
  customer_price_decision TEXT NOT NULL DEFAULT 'not_requested',
  internal_notes TEXT NULL,
  customer_message TEXT NULL,
  parent_repair_id INTEGER NULL REFERENCES repairs(id) ON UPDATE RESTRICT ON DELETE RESTRICT,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  received_at INTEGER NOT NULL,
  ready_at INTEGER NULL,
  delivered_at INTEGER NULL
);
''');
  database.execute('''
CREATE TABLE shop_settings (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  shop_name TEXT NOT NULL CHECK(length(trim(shop_name)) > 0),
  phone_number TEXT NULL,
  address TEXT NULL,
  logo_path TEXT NULL,
  repair_code_prefix TEXT NOT NULL CHECK(length(repair_code_prefix) BETWEEN 2 AND 10),
  repair_code_number_width INTEGER NOT NULL CHECK(repair_code_number_width BETWEEN 3 AND 8),
  ticket_footer TEXT NULL,
  warranty_terms TEXT NULL,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  CHECK(id = 1)
);
''');
}
