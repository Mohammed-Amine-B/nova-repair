import 'dart:io';

import 'package:drift/drift.dart' show Variable;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_repair/database/app_database.dart';
import 'package:nova_repair/database/database_lifecycle_manager.dart';
import 'package:nova_repair/features/backup/application/local_backup_service.dart';
import 'package:nova_repair/features/backup/infrastructure/backup_validator.dart';
import 'package:nova_repair/features/online_tracking/data/datasources/tracking_sync_outbox_local_data_source.dart';
import 'package:nova_repair/features/online_tracking/data/repositories/drift_tracking_sync_outbox_repository.dart';
import 'package:nova_repair/features/online_tracking/domain/tracking_sync_operation.dart';
import 'package:nova_repair/features/online_tracking/infrastructure/tracking_token_generator.dart';
import 'package:nova_repair/features/repairs/data/datasources/repair_code_sequence_local_data_source.dart';
import 'package:nova_repair/features/repairs/data/datasources/repair_local_data_source.dart';
import 'package:nova_repair/features/repairs/data/repositories/drift_repair_repository.dart';
import 'package:nova_repair/features/repairs/domain/entities/change_repair_status_input.dart';
import 'package:nova_repair/features/repairs/domain/entities/create_repair_input.dart';
import 'package:nova_repair/features/repairs/domain/entities/update_repair_input.dart';
import 'package:nova_repair/features/repairs/domain/repair_status.dart';
import 'package:nova_repair/features/settings/data/datasources/shop_settings_local_data_source.dart';
import 'package:nova_repair/features/settings/data/repositories/drift_shop_settings_repository.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

void main() {
  late AppDatabase database;
  late DateTime currentTime;

  setUp(() {
    currentTime = DateTime.utc(2026, 7, 7, 9);
    database = AppDatabase(_inMemoryDatabase());
  });

  tearDown(() async {
    await database.close();
  });

  test('tracking token generator creates URL-safe unique opaque tokens', () {
    final generator = TrackingTokenGenerator();
    final tokens = {
      for (var index = 0; index < 100; index += 1) generator.generate(),
    };

    expect(tokens.length, 100);
    for (final token in tokens) {
      expect(token, isNotEmpty);
      expect(token.length, greaterThanOrEqualTo(32));
      expect(RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(token), isTrue);
      expect(token, isNot(contains('REP-0001')));
    }
  });

  test('public shop ID is generated once and stable across reopen', () async {
    final tempDirectory = await Directory.systemTemp.createTemp(
      'nova_repair_public_shop_id_test_',
    );
    addTearDown(() => tempDirectory.delete(recursive: true));
    final file = File('${tempDirectory.path}/nova_repair.sqlite');
    var database = AppDatabase(_fileDatabase(file));
    var repository = DriftShopSettingsRepository(
      ShopSettingsLocalDataSource(database),
    );

    final first = await repository.getSettings();
    await database.close();

    database = AppDatabase(_fileDatabase(file));
    addTearDown(database.close);
    repository = DriftShopSettingsRepository(
      ShopSettingsLocalDataSource(database),
    );
    final second = await repository.getSettings();

    expect(first.publicShopId, isNotNull);
    expect(first.publicShopId, second.publicShopId);
    expect(first.publicShopId, isNot(first.shopName));
    expect(RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(first.publicShopId!), isTrue);
  });

  test(
    'repair creation assigns tracking token and one pending outbox row',
    () async {
      final repository = _repairRepository(database, () => currentTime);

      final repair = await repository.createRepair(
        CreateRepairInput(reportedProblem: 'Does not power on'),
      );

      expect(repair.trackingToken, isNotNull);
      expect(repair.trackingToken, isNot(repair.repairCode));
      expect(
        RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(repair.trackingToken!),
        isTrue,
      );

      final rows = await _outboxRows(database);
      expect(rows, hasLength(1));
      expect(rows.single.read<int>('repair_id'), repair.id);
      expect(rows.single.read<String>('operation'), 'upsert_snapshot');
      expect(rows.single.read<int>('attempt_count'), 0);
      expect(rows.single.read<String?>('last_error'), isNull);
    },
  );

  test(
    'status changes deduplicate outbox and reset failure metadata',
    () async {
      final repository = _repairRepository(database, () => currentTime);
      final outbox = TrackingSyncOutboxLocalDataSource(database);
      final repair = await repository.createRepair(
        CreateRepairInput(reportedProblem: 'Does not power on'),
      );
      final entry = (await _outboxRows(database)).single;
      await outbox.markFailure(
        entryId: entry.read<int>('id'),
        safeError: 'network failed',
        nextAttemptAt: DateTime.utc(2026, 7, 8),
        now: DateTime.utc(2026, 7, 7, 10),
      );

      currentTime = DateTime.utc(2026, 7, 7, 11);
      await repository.changeStatus(
        ChangeRepairStatusInput(
          repairId: repair.id!,
          targetStatus: RepairStatus.repairing,
        ),
      );
      currentTime = DateTime.utc(2026, 7, 7, 12);
      await repository.changeStatus(
        ChangeRepairStatusInput(
          repairId: repair.id!,
          targetStatus: RepairStatus.readyForPickup,
        ),
      );

      final rows = await _outboxRows(database);
      expect(rows, hasLength(1));
      expect(rows.single.read<int>('id'), entry.read<int>('id'));
      expect(rows.single.read<int>('attempt_count'), 0);
      expect(rows.single.read<String?>('last_error'), isNull);
      expect(rows.single.read<int>('repair_id'), repair.id);
    },
  );

  test(
    'repair edit and customer message change refresh pending outbox',
    () async {
      final repository = _repairRepository(database, () => currentTime);
      final repair = await repository.createRepair(
        CreateRepairInput(reportedProblem: 'Does not power on'),
      );
      final entryId = (await _outboxRows(database)).single.read<int>('id');

      currentTime = DateTime.utc(2026, 7, 7, 10);
      await repository.updateRepairDetails(
        UpdateRepairInput(
          repairId: repair.id!,
          deviceType: 'Laptop',
          reportedProblem: 'Does not power on',
          customerMessage: 'Customer-visible update',
        ),
      );

      final rows = await _outboxRows(database);
      expect(rows, hasLength(1));
      expect(rows.single.read<int>('id'), entryId);
      expect(rows.single.read<int>('attempt_count'), 0);
    },
  );

  test(
    'outbox repository operations insert, list due, fail, and delete',
    () async {
      final repository = _repairRepository(database, () => currentTime);
      final outboxRepository = DriftTrackingSyncOutboxRepository(
        TrackingSyncOutboxLocalDataSource(database),
        now: () => currentTime,
      );
      final first = await repository.createRepair(
        CreateRepairInput(reportedProblem: 'First repair'),
      );
      currentTime = DateTime.utc(2026, 7, 7, 10);
      final second = await repository.createRepair(
        CreateRepairInput(reportedProblem: 'Second repair'),
      );

      await outboxRepository.enqueueRepair(first.id!);
      expect(await _outboxRows(database), hasLength(2));

      final due = await outboxRepository.listDue(
        now: DateTime.utc(2026, 7, 7, 10),
        limit: 1,
      );
      expect(due, hasLength(1));
      expect(due.single.repairId, first.id);
      expect(due.single.operation, TrackingSyncOperation.upsertSnapshot);

      await outboxRepository.markPublishFailure(
        entryId: due.single.id,
        safeError:
            '  printer backend unavailable with long details ${'x' * 300}',
        nextAttemptAt: DateTime.utc(2026, 7, 7, 12),
      );
      final failed = await TrackingSyncOutboxLocalDataSource(
        database,
      ).getEntryForRepair(first.id!);
      expect(failed?.attemptCount, 1);
      expect(
        failed?.lastError?.startsWith('printer backend unavailable'),
        isTrue,
      );
      expect(failed?.lastError?.length, 240);
      expect(failed?.nextAttemptAt.toUtc(), DateTime.utc(2026, 7, 7, 12));

      await outboxRepository.markPublishSuccess(failed!.id);
      final remaining = await _outboxRows(database);
      expect(remaining, hasLength(1));
      expect(remaining.single.read<int>('repair_id'), second.id);
    },
  );

  test('version 6 database migrates identities, tokens, and pending outbox', () async {
    final tempDirectory = await Directory.systemTemp.createTemp(
      'nova_repair_tracking_v7_migration_test_',
    );
    addTearDown(() => tempDirectory.delete(recursive: true));
    final file = File('${tempDirectory.path}/migration.sqlite');
    final legacy = sqlite3.sqlite3.open(file.path);
    _createVersionSixSchema(legacy);
    legacy
      ..execute(
        "INSERT INTO shop_settings "
        "(id, shop_name, repair_code_prefix, repair_code_number_width, created_at, updated_at) "
        "VALUES (1, 'Legacy Shop', 'REP', 4, 0, 0)",
      )
      ..execute(
        "INSERT INTO repairs "
        "(repair_code, reported_problem, status, customer_price_decision, created_at, updated_at, received_at) "
        "VALUES ('REP-0001', 'Original problem', 'received', 'not_requested', 0, 0, 0)",
      )
      ..execute(
        "INSERT INTO repairs "
        "(repair_code, reported_problem, status, customer_price_decision, created_at, updated_at, received_at) "
        "VALUES ('REP-0002', 'Second problem', 'repairing', 'not_requested', 0, 0, 0)",
      )
      ..execute('PRAGMA user_version = 6');
    legacy.close();

    final migrated = AppDatabase(_fileDatabase(file));
    addTearDown(migrated.close);
    final version = await migrated
        .customSelect('PRAGMA user_version')
        .getSingle();
    final settings = await migrated
        .customSelect('SELECT public_shop_id FROM shop_settings WHERE id = 1')
        .getSingle();
    final repairs = await migrated
        .customSelect('SELECT tracking_token FROM repairs ORDER BY id')
        .get();
    final outboxCount = await migrated
        .customSelect('SELECT COUNT(*) AS count FROM tracking_sync_outbox')
        .getSingle();

    expect(version.read<int>('user_version'), 7);
    expect(settings.read<String?>('public_shop_id'), isNotNull);
    expect(
      repairs.map((row) => row.read<String?>('tracking_token')).toSet(),
      hasLength(2),
    );
    expect(
      repairs.every((row) => row.read<String?>('tracking_token') != null),
      isTrue,
    );
    expect(outboxCount.read<int>('count'), 2);
  });

  test('backup and restore preserve v7 identity tokens and outbox', () async {
    final tempDirectory = await Directory.systemTemp.createTemp(
      'nova_repair_tracking_backup_test_',
    );
    addTearDown(() => tempDirectory.delete(recursive: true));
    final file = File('${tempDirectory.path}/nova_repair.sqlite');
    final manager = _lifecycleManager(file);
    addTearDown(manager.closeCurrentDatabase);
    final backupService = LocalBackupService(
      manager,
      const BackupValidator(),
      now: () => DateTime.utc(2026, 7, 7, 12),
    );
    final settingsRepository = DriftShopSettingsRepository(
      ShopSettingsLocalDataSource(manager.database),
    );
    final repairRepository = _repairRepository(
      manager.database,
      () => currentTime,
    );

    final settings = await settingsRepository.getSettings();
    final repair = await repairRepository.createRepair(
      CreateRepairInput(reportedProblem: 'Backup repair'),
    );
    final backup = await backupService.createBackupFile(
      '${tempDirectory.path}/tracking_backup.nrbackup',
    );

    await TrackingSyncOutboxLocalDataSource(
      manager.database,
    ).markSuccess((await _outboxRows(manager.database)).single.read<int>('id'));
    await backupService.restoreBackup(backup.filePath);

    final restoredSettings = await manager.database
        .customSelect('SELECT public_shop_id FROM shop_settings WHERE id = 1')
        .getSingle();
    final restoredRepair = await manager.database
        .customSelect(
          'SELECT tracking_token FROM repairs WHERE id = ?',
          variables: [Variable<int>(repair.id!)],
        )
        .getSingle();
    final restoredOutbox = await _outboxRows(manager.database);

    expect(backup.schemaVersion, 7);
    expect(
      restoredSettings.read<String>('public_shop_id'),
      settings.publicShopId,
    );
    expect(restoredRepair.read<String>('tracking_token'), repair.trackingToken);
    expect(restoredOutbox, hasLength(1));
    expect(restoredOutbox.single.read<int>('repair_id'), repair.id);
  });

  test('pre-v7 restore generates identity tokens and pending rows', () async {
    final tempDirectory = await Directory.systemTemp.createTemp(
      'nova_repair_tracking_old_restore_test_',
    );
    addTearDown(() => tempDirectory.delete(recursive: true));
    final file = File('${tempDirectory.path}/nova_repair.sqlite');
    final manager = _lifecycleManager(file);
    addTearDown(manager.closeCurrentDatabase);
    final backupService = LocalBackupService(
      manager,
      const BackupValidator(),
      now: () => DateTime.utc(2026, 7, 7, 12),
    );
    final olderBackup = File('${tempDirectory.path}/older_v6.sqlite');
    final legacy = sqlite3.sqlite3.open(olderBackup.path);
    _createVersionSixSchema(legacy);
    legacy
      ..execute(
        "INSERT INTO shop_settings "
        "(id, shop_name, repair_code_prefix, repair_code_number_width, created_at, updated_at) "
        "VALUES (1, 'Old Shop', 'REP', 4, 0, 0)",
      )
      ..execute(
        "INSERT INTO repairs "
        "(repair_code, reported_problem, status, customer_price_decision, created_at, updated_at, received_at) "
        "VALUES ('REP-OLD', 'Old repair', 'received', 'not_requested', 0, 0, 0)",
      )
      ..execute('PRAGMA user_version = 6');
    legacy.close();

    await backupService.restoreBackup(olderBackup.path);

    final version = await manager.database
        .customSelect('PRAGMA user_version')
        .getSingle();
    final settings = await manager.database
        .customSelect('SELECT public_shop_id FROM shop_settings WHERE id = 1')
        .getSingle();
    final repair = await manager.database
        .customSelect(
          'SELECT tracking_token FROM repairs WHERE repair_code = ?',
          variables: [Variable<String>('REP-OLD')],
        )
        .getSingle();
    final outbox = await _outboxRows(manager.database);

    expect(version.read<int>('user_version'), 7);
    expect(settings.read<String?>('public_shop_id'), isNotNull);
    expect(repair.read<String?>('tracking_token'), isNotNull);
    expect(outbox, hasLength(1));
    expect(outbox.single.read<String>('operation'), 'upsert_snapshot');
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
    trackingSyncOutboxLocalDataSource: TrackingSyncOutboxLocalDataSource(
      database,
    ),
    now: now,
  );
}

Future<List<dynamic>> _outboxRows(AppDatabase database) {
  return database
      .customSelect('SELECT * FROM tracking_sync_outbox ORDER BY id ASC')
      .get();
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

DatabaseLifecycleManager _lifecycleManager(File file) {
  AppDatabase open(File databaseFile) =>
      AppDatabase(_fileDatabase(databaseFile));

  final manager = DatabaseLifecycleManager(
    resolveDatabaseFile: () async => file,
    openDatabase: open,
    initialDatabase: open(file),
  );
  return manager;
}

void _createVersionSixSchema(sqlite3.Database database) {
  database
    ..execute('PRAGMA foreign_keys = ON')
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
      )
    ''')
    ..execute('''
      CREATE TABLE shop_settings (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        shop_name TEXT NOT NULL CHECK(length(trim(shop_name)) > 0),
        shop_subtitle TEXT NULL,
        phone_number TEXT NULL,
        address TEXT NULL,
        logo_path TEXT NULL,
        repair_code_prefix TEXT NOT NULL CHECK(length(repair_code_prefix) BETWEEN 2 AND 10),
        repair_code_number_width INTEGER NOT NULL CHECK(repair_code_number_width BETWEEN 3 AND 8),
        ticket_footer TEXT NULL,
        warranty_terms TEXT NULL,
        default_customer_ticket_printer_id TEXT NULL,
        default_device_label_printer_id TEXT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        CHECK(id = 1)
      )
    ''')
    ..execute('''
      CREATE TABLE repair_code_sequence (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        last_used_sequence INTEGER NOT NULL CHECK(last_used_sequence >= 0),
        CHECK(id = 1)
      )
    ''')
    ..execute('''
      CREATE TABLE common_problems (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL CHECK(length(trim(title)) > 0),
        normalized_title TEXT NOT NULL UNIQUE CHECK(length(trim(normalized_title)) > 0),
        usage_count INTEGER NOT NULL CHECK(usage_count >= 0),
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
}
