import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nova_repair/database/app_database.dart';
import 'package:nova_repair/database/database_lifecycle_manager.dart';
import 'package:nova_repair/features/backup/application/local_backup_service.dart';
import 'package:nova_repair/features/backup/domain/entities/backup_metadata.dart';
import 'package:nova_repair/features/backup/domain/errors/backup_exception.dart';
import 'package:nova_repair/features/backup/infrastructure/backup_validator.dart';
import 'package:nova_repair/features/repairs/data/datasources/repair_code_sequence_local_data_source.dart';
import 'package:nova_repair/features/repairs/data/datasources/repair_local_data_source.dart';
import 'package:nova_repair/features/repairs/data/repositories/drift_repair_repository.dart';
import 'package:nova_repair/features/repairs/domain/entities/change_repair_status_input.dart';
import 'package:nova_repair/features/repairs/domain/entities/create_repair_input.dart';
import 'package:nova_repair/features/repairs/domain/entities/propose_repair_price_input.dart';
import 'package:nova_repair/features/repairs/domain/repair_status.dart';
import 'package:nova_repair/features/settings/data/datasources/shop_settings_local_data_source.dart';
import 'package:nova_repair/features/settings/data/repositories/drift_shop_settings_repository.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

void main() {
  late Directory tempDirectory;
  late File databaseFile;
  late DatabaseLifecycleManager lifecycleManager;
  late LocalBackupService backupService;
  late DriftRepairRepository repairRepository;
  late DriftShopSettingsRepository settingsRepository;
  late DateTime currentTime;

  setUp(() async {
    currentTime = DateTime(2026, 7, 5, 14, 30);
    tempDirectory = await Directory.systemTemp.createTemp(
      'nova_repair_backup_test_',
    );
    databaseFile = File('${tempDirectory.path}/nova_repair.sqlite');
    lifecycleManager = _lifecycleManager(databaseFile);
    backupService = LocalBackupService(
      lifecycleManager,
      const BackupValidator(),
      now: () => currentTime,
    );
    repairRepository = _repairRepository(lifecycleManager, () => currentTime);
    settingsRepository = _settingsRepository(
      lifecycleManager,
      () => currentTime,
    );
  });

  tearDown(() async {
    await lifecycleManager.closeCurrentDatabase();
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  test('creates a complete validated backup file with metadata', () async {
    await _seedRealisticData(
      repairRepository,
      settingsRepository,
      () => currentTime,
      (value) => currentTime = value,
    );
    currentTime = DateTime(2026, 7, 5, 14, 30);
    final destination = Directory('${tempDirectory.path}/backups');

    final metadata = await backupService.createBackup(destination.path);
    final backupFile = File(metadata.filePath);

    expect(await backupFile.exists(), isTrue);
    expect(metadata.fileName, 'nova_repair_backup_2026-07-05_143000.sqlite');
    expect(metadata.fileName, isNot(contains(':')));
    expect(metadata.fileName, endsWith('.sqlite'));
    expect(metadata.fileSizeBytes, greaterThan(0));
    expect(metadata.schemaVersion, 7);
    expect(metadata.repairCount, 2);
    expect(metadata.createdAt, DateTime(2026, 7, 5, 14, 30).toUtc());

    final backupDatabase = sqlite3.sqlite3.open(backupFile.path);
    addTearDown(backupDatabase.close);

    expect(
      _intValue(backupDatabase, 'SELECT COUNT(*) AS value FROM repairs'),
      2,
    );
    expect(
      _textValue(
        backupDatabase,
        'SELECT shop_name AS value FROM shop_settings WHERE id = 1',
      ),
      'Nova Backup Shop',
    );
    expect(
      _textValue(
        backupDatabase,
        'SELECT shop_subtitle AS value FROM shop_settings WHERE id = 1',
      ),
      'Repair Center',
    );
    expect(
      _textValue(
        backupDatabase,
        'SELECT default_customer_ticket_printer_id AS value FROM shop_settings WHERE id = 1',
      ),
      'ticket-printer-id',
    );
    expect(
      _textValue(
        backupDatabase,
        'SELECT default_device_label_printer_id AS value FROM shop_settings WHERE id = 1',
      ),
      'label-printer-id',
    );
    expect(
      _intValue(
        backupDatabase,
        'SELECT last_used_sequence AS value FROM repair_code_sequence WHERE id = 1',
      ),
      2,
    );
    expect(
      _intValue(
        backupDatabase,
        'SELECT COUNT(*) AS value FROM common_problems',
      ),
      0,
    );

    expect(
      await lifecycleManager.database
          .customSelect('SELECT COUNT(*) AS value FROM repairs')
          .getSingle()
          .then((row) => row.read<int>('value')),
      2,
    );
  });

  test('backup file naming is deterministic from local creation time', () {
    final fileName = LocalBackupService.buildBackupFileName(
      DateTime(2026, 7, 5, 14, 30),
    );

    expect(fileName, 'nova_repair_backup_2026-07-05_143000.sqlite');
    expect(fileName, isNot(contains(':')));
    expect(fileName, endsWith('.sqlite'));
  });

  test('validation accepts valid backup and rejects invalid files', () async {
    await _seedRealisticData(
      repairRepository,
      settingsRepository,
      () => currentTime,
      (value) => currentTime = value,
    );
    final metadata = await backupService.createBackup(
      '${tempDirectory.path}/backups',
    );

    expect(
      await backupService.validateBackup(metadata.filePath),
      isA<BackupMetadata>().having(
        (value) => value.schemaVersion,
        'schemaVersion',
        7,
      ),
    );

    await expectLater(
      backupService.validateBackup('${tempDirectory.path}/missing.sqlite'),
      throwsA(isA<BackupValidationException>()),
    );

    final emptyFile = File('${tempDirectory.path}/empty.sqlite');
    await emptyFile.writeAsBytes([]);
    await expectLater(
      backupService.validateBackup(emptyFile.path),
      throwsA(isA<BackupValidationException>()),
    );

    final textFile = File('${tempDirectory.path}/not_sqlite.sqlite');
    await textFile.writeAsString('not a sqlite database');
    await expectLater(
      backupService.validateBackup(textFile.path),
      throwsA(isA<BackupException>()),
    );

    final missingTables = File('${tempDirectory.path}/missing_tables.sqlite');
    _createSqliteDatabase(missingTables, (database) {
      database.execute('PRAGMA user_version = 4');
    });
    await expectLater(
      backupService.validateBackup(missingTables.path),
      throwsA(isA<BackupValidationException>()),
    );

    final unsupported = File('${tempDirectory.path}/future.sqlite');
    _createSqliteDatabase(unsupported, (database) {
      database.execute('PRAGMA user_version = 99');
    });
    await expectLater(
      backupService.validateBackup(unsupported.path),
      throwsA(isA<UnsupportedBackupSchemaException>()),
    );
  });

  test('restores backup and returns live database to previous state', () async {
    await _seedRealisticData(
      repairRepository,
      settingsRepository,
      () => currentTime,
      (value) => currentTime = value,
    );
    final backup = await backupService.createBackup(
      '${tempDirectory.path}/backups',
    );

    await repairRepository.createRepair(
      CreateRepairInput(reportedProblem: 'Temporary extra repair'),
    );
    final settings = await settingsRepository.getSettings();
    await settingsRepository.saveSettings(
      settings.copyWith(shopName: 'Changed After Backup'),
    );
    expect(await _liveRepairCount(lifecycleManager), 3);

    await backupService.restoreBackup(backup.filePath);

    expect(await _liveRepairCount(lifecycleManager), 2);
    expect(await _liveShopName(lifecycleManager), 'Nova Backup Shop');
    expect(await _liveSequence(lifecycleManager), 2);
  });

  test('restore from older supported schema migrates to current schema', () async {
    final olderBackup = File('${tempDirectory.path}/version_2.sqlite');
    _createVersionTwoDatabase(olderBackup);

    await backupService.restoreBackup(olderBackup.path);

    final version = await lifecycleManager.database
        .customSelect('PRAGMA user_version')
        .getSingle();
    final repair = await lifecycleManager.database
        .customSelect(
          "SELECT repair_code FROM repairs WHERE repair_code = 'REP-0042'",
        )
        .getSingleOrNull();
    final settingsTable = await lifecycleManager.database
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'shop_settings'",
        )
        .getSingleOrNull();
    final sequenceTable = await lifecycleManager.database
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'repair_code_sequence'",
        )
        .getSingleOrNull();

    final commonProblemsTable = await lifecycleManager.database
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'common_problems'",
        )
        .getSingleOrNull();

    expect(version.read<int>('user_version'), 7);
    expect(repair, isNotNull);
    expect(settingsTable, isNotNull);
    expect(sequenceTable, isNotNull);
    expect(commonProblemsTable, isNotNull);
  });

  test(
    'restore from version 4 backup migrates settings to current schema',
    () async {
      final versionFourBackup = File('${tempDirectory.path}/version_4.sqlite');
      _createVersionFourDatabase(versionFourBackup);

      await backupService.restoreBackup(versionFourBackup.path);

      final version = await lifecycleManager.database
          .customSelect('PRAGMA user_version')
          .getSingle();
      final settings = await _settingsRepository(
        lifecycleManager,
        () => currentTime,
      ).getSettings();
      final repair = await lifecycleManager.database
          .customSelect(
            "SELECT repair_code FROM repairs WHERE repair_code = 'REP-0042'",
          )
          .getSingleOrNull();
      final sequence = await lifecycleManager.database
          .customSelect(
            'SELECT last_used_sequence AS value FROM repair_code_sequence WHERE id = 1',
          )
          .getSingle();

      final commonProblemCount = await lifecycleManager.database
          .customSelect('SELECT COUNT(*) AS value FROM common_problems')
          .getSingle();

      expect(version.read<int>('user_version'), 7);
      expect(settings.shopName, 'Version Four Shop');
      expect(settings.ticketFooter, 'Keep this v4 ticket.');
      expect(settings.shopSubtitle, isNull);
      expect(settings.defaultCustomerTicketPrinterId, isNull);
      expect(settings.defaultDeviceLabelPrinterId, isNull);
      expect(repair, isNotNull);
      expect(sequence.read<int>('value'), 42);
      expect(commonProblemCount.read<int>('value'), 0);
    },
  );

  test('restore from current live database path fails clearly', () async {
    await _seedRealisticData(
      repairRepository,
      settingsRepository,
      () => currentTime,
      (value) => currentTime = value,
    );

    await expectLater(
      backupService.restoreBackup(databaseFile.path),
      throwsA(isA<RestoreFromCurrentDatabaseException>()),
    );
  });

  test(
    'restore rolls back and reopens current database after replacement failure',
    () async {
      await _seedRealisticData(
        repairRepository,
        settingsRepository,
        () => currentTime,
        (value) => currentTime = value,
      );
      final backup = await backupService.createBackup(
        '${tempDirectory.path}/backups',
      );
      final deletingService = LocalBackupService(
        lifecycleManager,
        _DeletingBackupValidator(backup.filePath),
        now: () => currentTime,
      );

      await expectLater(
        deletingService.restoreBackup(backup.filePath),
        throwsA(isA<RestoreException>()),
      );

      expect(await _liveRepairCount(lifecycleManager), 2);
      expect(await _liveShopName(lifecycleManager), 'Nova Backup Shop');
      expect(await _liveSequence(lifecycleManager), 2);
    },
  );

  test('invalid destination fails clearly', () async {
    await _seedRealisticData(
      repairRepository,
      settingsRepository,
      () => currentTime,
      (value) => currentTime = value,
    );
    final fileDestination = File('${tempDirectory.path}/not_a_directory');
    await fileDestination.writeAsString('already a file');

    await expectLater(
      backupService.createBackup(fileDestination.path),
      throwsA(isA<BackupDestinationInvalidException>()),
    );
  });
}

Future<void> _seedRealisticData(
  DriftRepairRepository repairRepository,
  DriftShopSettingsRepository settingsRepository,
  DateTime Function() currentTime,
  void Function(DateTime value) setCurrentTime,
) async {
  final settings = await settingsRepository.getSettings();
  await settingsRepository.saveSettings(
    settings.copyWith(
      shopName: 'Nova Backup Shop',
      shopSubtitle: 'Repair Center',
      phoneNumber: '0555000000',
      address: 'Algiers',
      logoPath: '/logos/nova.png',
      ticketFooter: 'Keep this ticket.',
      warrantyTerms: 'Warranty applies to repaired parts.',
      defaultCustomerTicketPrinterId: 'ticket-printer-id',
      defaultDeviceLabelPrinterId: 'label-printer-id',
    ),
  );

  final first = await repairRepository.createRepair(
    CreateRepairInput(
      customerName: 'Amina',
      reportedProblem: 'Does not power on',
      receivedAt: DateTime.utc(2026, 7, 1, 9),
    ),
  );
  await repairRepository.createRepair(
    CreateRepairInput(
      customerName: 'Karim',
      reportedProblem: 'Broken screen',
      receivedAt: DateTime.utc(2026, 7, 2, 10),
    ),
  );

  setCurrentTime(DateTime(2026, 7, 5, 15));
  final diagnosing = await repairRepository.changeStatus(
    ChangeRepairStatusInput(
      repairId: first.id!,
      targetStatus: RepairStatus.diagnosing,
    ),
  );
  await repairRepository.proposePrice(
    ProposeRepairPriceInput(repairId: diagnosing.id!, priceAmount: 5000),
  );
}

DatabaseLifecycleManager _lifecycleManager(File databaseFile) {
  AppDatabase open(File file) => AppDatabase(openNativeDatabaseFile(file));

  return DatabaseLifecycleManager(
    resolveDatabaseFile: () async => databaseFile,
    openDatabase: open,
    initialDatabase: open(databaseFile),
  );
}

DriftRepairRepository _repairRepository(
  DatabaseLifecycleManager manager,
  DateTime Function() now,
) {
  return DriftRepairRepository(
    manager.database,
    RepairLocalDataSource(manager.database),
    RepairCodeSequenceLocalDataSource(manager.database),
    ShopSettingsLocalDataSource(manager.database),
    now: now,
  );
}

DriftShopSettingsRepository _settingsRepository(
  DatabaseLifecycleManager manager,
  DateTime Function() now,
) {
  return DriftShopSettingsRepository(
    ShopSettingsLocalDataSource(manager.database),
    now: now,
  );
}

Future<int> _liveRepairCount(DatabaseLifecycleManager manager) async {
  final row = await manager.database
      .customSelect('SELECT COUNT(*) AS value FROM repairs')
      .getSingle();
  return row.read<int>('value');
}

Future<String> _liveShopName(DatabaseLifecycleManager manager) async {
  final row = await manager.database
      .customSelect('SELECT shop_name AS value FROM shop_settings WHERE id = 1')
      .getSingle();
  return row.read<String>('value');
}

Future<int> _liveSequence(DatabaseLifecycleManager manager) async {
  final row = await manager.database
      .customSelect(
        'SELECT last_used_sequence AS value FROM repair_code_sequence WHERE id = 1',
      )
      .getSingle();
  return row.read<int>('value');
}

int _intValue(sqlite3.Database database, String sql) {
  return database.select(sql).first['value'] as int;
}

String _textValue(sqlite3.Database database, String sql) {
  return database.select(sql).first['value'] as String;
}

void _createSqliteDatabase(
  File file,
  void Function(sqlite3.Database database) build,
) {
  final database = sqlite3.sqlite3.open(file.path);
  try {
    build(database);
  } finally {
    database.close();
  }
}

void _createVersionTwoDatabase(File file) {
  _createSqliteDatabase(file, (database) {
    database
      ..execute('''
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
''')
      ..execute(
        "INSERT INTO repairs "
        "(repair_code, reported_problem, status, customer_price_decision, created_at, updated_at, received_at) "
        "VALUES ('REP-0042', 'Does not power on', 'received', 'not_requested', 0, 0, 0)",
      )
      ..execute('PRAGMA user_version = 2');
  });
}

void _createVersionFourDatabase(File file) {
  _createSqliteDatabase(file, (database) {
    database
      ..execute('''
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
''')
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
''')
      ..execute(
        "INSERT INTO shop_settings "
        "(id, shop_name, phone_number, address, logo_path, repair_code_prefix, "
        "repair_code_number_width, ticket_footer, warranty_terms, created_at, updated_at) "
        "VALUES (1, 'Version Four Shop', '0555000000', 'Chlef', '/logo.png', "
        "'REP', 4, 'Keep this v4 ticket.', 'V4 warranty terms.', 0, 0)",
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
  });
}

class _DeletingBackupValidator extends BackupValidator {
  _DeletingBackupValidator(this.pathToDelete);

  final String pathToDelete;
  bool _deleted = false;

  @override
  Future<BackupMetadata> validateBackup(String backupFilePath) async {
    final metadata = await super.validateBackup(backupFilePath);
    if (!_deleted && backupFilePath == pathToDelete) {
      _deleted = true;
      await File(pathToDelete).delete();
    }
    return metadata;
  }
}
