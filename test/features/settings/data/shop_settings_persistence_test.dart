import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_repair/database/app_database.dart';
import 'package:nova_repair/features/settings/data/datasources/shop_settings_local_data_source.dart';
import 'package:nova_repair/features/settings/data/repositories/drift_shop_settings_repository.dart';
import 'package:nova_repair/features/settings/domain/entities/shop_settings.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

void main() {
  group('Shop settings persistence', () {
    late AppDatabase database;
    late ShopSettingsLocalDataSource localDataSource;
    late DriftShopSettingsRepository repository;
    late DateTime currentTime;

    setUp(() {
      currentTime = DateTime.utc(2026, 1, 1, 9);
      database = AppDatabase(_inMemoryDatabase());
      localDataSource = ShopSettingsLocalDataSource(database);
      repository = DriftShopSettingsRepository(
        localDataSource,
        now: () => currentTime,
      );
    });

    tearDown(() async {
      await database.close();
    });

    test('default settings are available on a fresh database', () async {
      final settings = await repository.getSettings();

      expect(settings.shopName, ShopSettings.defaultShopName);
      expect(settings.repairCodePrefix, ShopSettings.defaultRepairCodePrefix);
      expect(
        settings.repairCodeNumberWidth,
        ShopSettings.defaultRepairCodeNumberWidth,
      );
      expect(settings.createdAt, currentTime);
      expect(settings.updatedAt, currentTime);
    });

    test('default optional fields persist as null', () async {
      await repository.getSettings();
      final settings = await repository.getSettings();

      expect(settings.phoneNumber, isNull);
      expect(settings.shopSubtitle, isNull);
      expect(settings.address, isNull);
      expect(settings.logoPath, isNull);
      expect(settings.ticketFooter, isNull);
      expect(settings.warrantyTerms, isNull);
      expect(settings.defaultCustomerTicketPrinterId, isNull);
      expect(settings.defaultDeviceLabelPrinterId, isNull);
    });

    test('settings can be updated without creating duplicate rows', () async {
      final defaults = await repository.getSettings();
      currentTime = DateTime.utc(2026, 1, 2, 10);

      final saved = await repository.saveSettings(
        defaults.copyWith(
          shopName: 'Nova Tech Repair',
          shopSubtitle: ' Repair Center ',
          phoneNumber: '0555000000',
          address: 'Algiers',
          logoPath: '/local/logo.png',
          repairCodePrefix: ' fix ',
          repairCodeNumberWidth: 5,
          ticketFooter: 'Thank you for choosing our repair service.',
          warrantyTerms: 'Warranty applies to repaired parts only.',
          defaultCustomerTicketPrinterId: ' customer-ticket-printer ',
          defaultDeviceLabelPrinterId: 'device-label-printer',
        ),
      );

      final rowCount = await database
          .customSelect('SELECT COUNT(*) AS count FROM shop_settings')
          .getSingle();
      final reloaded = await repository.getSettings();

      expect(rowCount.read<int>('count'), 1);
      expect(saved.createdAt, defaults.createdAt);
      expect(saved.updatedAt, currentTime);
      expect(reloaded.shopName, 'Nova Tech Repair');
      expect(reloaded.shopSubtitle, 'Repair Center');
      expect(reloaded.phoneNumber, '0555000000');
      expect(reloaded.address, 'Algiers');
      expect(reloaded.logoPath, '/local/logo.png');
      expect(reloaded.repairCodePrefix, 'FIX');
      expect(reloaded.repairCodeNumberWidth, 5);
      expect(
        reloaded.ticketFooter,
        'Thank you for choosing our repair service.',
      );
      expect(
        reloaded.warrantyTerms,
        'Warranty applies to repaired parts only.',
      );
      expect(
        reloaded.defaultCustomerTicketPrinterId,
        'customer-ticket-printer',
      );
      expect(reloaded.defaultDeviceLabelPrinterId, 'device-label-printer');
      expect(reloaded.createdAt, defaults.createdAt);
      expect(reloaded.updatedAt, currentTime);
    });

    test('blank subtitle and printer identifiers persist as null', () async {
      final defaults = await repository.getSettings();

      await repository.saveSettings(
        defaults.copyWith(
          shopSubtitle: '   ',
          defaultCustomerTicketPrinterId: '   ',
          defaultDeviceLabelPrinterId: '   ',
        ),
      );

      final reloaded = await repository.getSettings();

      expect(reloaded.shopSubtitle, isNull);
      expect(reloaded.defaultCustomerTicketPrinterId, isNull);
      expect(reloaded.defaultDeviceLabelPrinterId, isNull);
    });

    test(
      'full settings replacement can preserve and clear printer IDs',
      () async {
        final defaults = await repository.getSettings();
        final withPrinters = await repository.saveSettings(
          defaults.copyWith(
            shopName: 'Nova Tech Repair',
            defaultCustomerTicketPrinterId: 'ticket-printer-id',
            defaultDeviceLabelPrinterId: 'label-printer-id',
          ),
        );

        final changedShopInfo = await repository.saveSettings(
          withPrinters.copyWith(phoneNumber: '0555000000'),
        );
        expect(
          changedShopInfo.defaultCustomerTicketPrinterId,
          'ticket-printer-id',
        );
        expect(changedShopInfo.defaultDeviceLabelPrinterId, 'label-printer-id');
        expect(changedShopInfo.phoneNumber, '0555000000');

        final changedPrinters = await repository.saveSettings(
          changedShopInfo.copyWith(
            defaultCustomerTicketPrinterId: 'new-ticket-printer-id',
          ),
        );
        expect(changedPrinters.shopName, 'Nova Tech Repair');
        expect(changedPrinters.phoneNumber, '0555000000');
        expect(
          changedPrinters.defaultCustomerTicketPrinterId,
          'new-ticket-printer-id',
        );
        expect(changedPrinters.defaultDeviceLabelPrinterId, 'label-printer-id');

        final clearedPrinters = await repository.saveSettings(
          changedPrinters.copyWith(
            defaultCustomerTicketPrinterId: null,
            defaultDeviceLabelPrinterId: null,
          ),
        );
        expect(clearedPrinters.defaultCustomerTicketPrinterId, isNull);
        expect(clearedPrinters.defaultDeviceLabelPrinterId, isNull);
      },
    );

    test('system default printer preference is represented by null', () async {
      final defaults = await repository.getSettings();

      final saved = await repository.saveSettings(
        defaults.copyWith(
          defaultCustomerTicketPrinterId: null,
          defaultDeviceLabelPrinterId: null,
        ),
      );

      expect(saved.defaultCustomerTicketPrinterId, isNull);
      expect(saved.defaultDeviceLabelPrinterId, isNull);
      expect(saved.defaultCustomerTicketPrinterId, isNot('Default Printer'));
      expect(saved.defaultDeviceLabelPrinterId, isNot('Default Printer'));
    });

    test('singleton primary key rejects a second row', () async {
      await repository.getSettings();

      expect(
        () => database.customInsert(
          "INSERT INTO shop_settings "
          "(id, shop_name, repair_code_prefix, repair_code_number_width, created_at, updated_at) "
          "VALUES (2, 'Other Shop', 'FIX', 4, 0, 0)",
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  test('upgrades a version 2 database and preserves repair data', () async {
    final tempDirectory = await Directory.systemTemp.createTemp(
      'nova_repair_settings_migration_test_',
    );
    addTearDown(() => tempDirectory.delete(recursive: true));

    final file = File('${tempDirectory.path}/migration.sqlite');
    final versionTwoDatabase = sqlite3.sqlite3.open(file.path);
    _createVersionTwoSchema(versionTwoDatabase);
    versionTwoDatabase.execute(
      "INSERT INTO repairs "
      "(repair_code, reported_problem, status, customer_price_decision, created_at, updated_at, received_at) "
      "VALUES ('REP-0042', 'Does not power on', 'received', 'not_requested', 0, 0, 0)",
    );
    versionTwoDatabase.execute('PRAGMA user_version = 2');
    versionTwoDatabase.close();

    final database = AppDatabase(_fileDatabase(file));
    addTearDown(database.close);

    final repository = DriftShopSettingsRepository(
      ShopSettingsLocalDataSource(database),
      now: () => DateTime.utc(2026, 1, 3, 11),
    );
    final settings = await repository.getSettings();

    final repair = await database
        .customSelect(
          "SELECT repair_code FROM repairs WHERE repair_code = 'REP-0042'",
        )
        .getSingleOrNull();
    final settingsTable = await database
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'shop_settings'",
        )
        .getSingleOrNull();
    final userVersion = await database
        .customSelect('PRAGMA user_version')
        .getSingle();

    expect(repair, isNotNull);
    expect(settingsTable, isNotNull);
    expect(settings.shopName, ShopSettings.defaultShopName);
    expect(settings.repairCodePrefix, ShopSettings.defaultRepairCodePrefix);
    expect(
      settings.repairCodeNumberWidth,
      ShopSettings.defaultRepairCodeNumberWidth,
    );
    expect(userVersion.read<int>('user_version'), 7);
  });

  test('upgrades a version 4 database and preserves existing data', () async {
    final tempDirectory = await Directory.systemTemp.createTemp(
      'nova_repair_settings_v5_migration_test_',
    );
    addTearDown(() => tempDirectory.delete(recursive: true));

    final file = File('${tempDirectory.path}/migration.sqlite');
    final versionFourDatabase = sqlite3.sqlite3.open(file.path);
    _createVersionFourSchema(versionFourDatabase);
    versionFourDatabase
      ..execute(
        "INSERT INTO shop_settings "
        "(id, shop_name, phone_number, address, logo_path, repair_code_prefix, "
        "repair_code_number_width, ticket_footer, warranty_terms, created_at, updated_at) "
        "VALUES (1, 'Legacy Shop', '0555000000', 'Algiers', '/logo.png', "
        "'LEG', 5, 'Keep ticket', 'Legacy warranty', 10, 20)",
      )
      ..execute(
        "INSERT INTO repairs "
        "(repair_code, reported_problem, status, customer_price_decision, created_at, updated_at, received_at) "
        "VALUES ('REP-0042', 'Does not power on', 'received', 'not_requested', 0, 0, 0)",
      )
      ..execute(
        'INSERT INTO repair_code_sequence (id, last_used_sequence) VALUES (1, 42)',
      )
      ..execute('PRAGMA user_version = 4');
    versionFourDatabase.close();

    final database = AppDatabase(_fileDatabase(file));
    addTearDown(database.close);

    final repository = DriftShopSettingsRepository(
      ShopSettingsLocalDataSource(database),
      now: () => DateTime.utc(2026, 1, 3, 11),
    );
    final settings = await repository.getSettings();

    final repair = await database
        .customSelect(
          "SELECT repair_code FROM repairs WHERE repair_code = 'REP-0042'",
        )
        .getSingleOrNull();
    final sequence = await database
        .customSelect(
          'SELECT last_used_sequence FROM repair_code_sequence WHERE id = 1',
        )
        .getSingle();
    final userVersion = await database
        .customSelect('PRAGMA user_version')
        .getSingle();

    expect(settings.shopName, 'Legacy Shop');
    expect(settings.phoneNumber, '0555000000');
    expect(settings.address, 'Algiers');
    expect(settings.logoPath, '/logo.png');
    expect(settings.repairCodePrefix, 'LEG');
    expect(settings.repairCodeNumberWidth, 5);
    expect(settings.ticketFooter, 'Keep ticket');
    expect(settings.warrantyTerms, 'Legacy warranty');
    expect(settings.shopSubtitle, isNull);
    expect(settings.defaultCustomerTicketPrinterId, isNull);
    expect(settings.defaultDeviceLabelPrinterId, isNull);
    expect(repair, isNotNull);
    expect(sequence.read<int>('last_used_sequence'), 42);
    expect(userVersion.read<int>('user_version'), 7);
  });
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

void _createVersionTwoSchema(sqlite3.Database database) {
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
}

void _createVersionFourSchema(sqlite3.Database database) {
  _createVersionTwoSchema(database);
  database
    ..execute('''
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
''')
    ..execute('''
CREATE TABLE repair_code_sequence (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  last_used_sequence INTEGER NOT NULL CHECK(last_used_sequence >= 0),
  CHECK(id = 1)
);
''');
}
