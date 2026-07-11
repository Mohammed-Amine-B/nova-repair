import 'dart:io';

import 'package:drift/drift.dart' show Variable;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_repair/database/app_database.dart';
import 'package:nova_repair/database/database_lifecycle_manager.dart';
import 'package:nova_repair/database/database_provider.dart';
import 'package:nova_repair/features/backup/application/local_backup_service.dart';
import 'package:nova_repair/features/backup/infrastructure/backup_validator.dart';
import 'package:nova_repair/features/common_problems/common_problem_providers.dart';
import 'package:nova_repair/features/common_problems/data/datasources/common_problem_local_data_source.dart';
import 'package:nova_repair/features/common_problems/data/repositories/drift_common_problem_repository.dart';
import 'package:nova_repair/features/common_problems/domain/entities/create_common_problem_input.dart';
import 'package:nova_repair/features/common_problems/domain/entities/update_common_problem_input.dart';
import 'package:nova_repair/features/common_problems/domain/errors/common_problem_exception.dart';
import 'package:nova_repair/features/repairs/data/datasources/repair_code_sequence_local_data_source.dart';
import 'package:nova_repair/features/repairs/data/datasources/repair_local_data_source.dart';
import 'package:nova_repair/features/repairs/data/repositories/drift_repair_repository.dart';
import 'package:nova_repair/features/repairs/domain/entities/create_repair_input.dart';
import 'package:nova_repair/features/settings/data/datasources/shop_settings_local_data_source.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

void main() {
  late AppDatabase database;
  late DriftCommonProblemRepository repository;
  late DateTime currentTime;

  setUp(() {
    currentTime = DateTime.utc(2026, 7, 6, 9);
    database = AppDatabase(_inMemoryDatabase());
    repository = _commonProblemRepository(database, () => currentTime);
  });

  tearDown(() async {
    await database.close();
  });

  test(
    'create stores trimmed title, zero usage, and backend timestamps',
    () async {
      final created = await repository.createCommonProblem(
        CreateCommonProblemInput(title: '  Does not charge  '),
      );

      expect(created.id, isNotNull);
      expect(created.title, 'Does not charge');
      expect(created.usageCount, 0);
      expect(created.createdAt, currentTime);
      expect(created.updatedAt, currentTime);

      final row = await database
          .customSelect(
            'SELECT normalized_title FROM common_problems WHERE id = ?',
            variables: [Variable<int>(created.id!)],
          )
          .getSingle();
      expect(row.read<String>('normalized_title'), 'does not charge');
    },
  );

  test('blank title is rejected', () {
    expect(
      () => CreateCommonProblemInput(title: '   '),
      throwsA(isA<InvalidCommonProblemTitleException>()),
    );
  });

  test(
    'normalized duplicate titles are rejected without aggressive Unicode changes',
    () async {
      await repository.createCommonProblem(
        CreateCommonProblemInput(title: 'Does not charge'),
      );

      for (final duplicate in [
        'does not charge',
        'Does   not   charge',
        'Does not charge ',
      ]) {
        await expectLater(
          repository.createCommonProblem(
            CreateCommonProblemInput(title: duplicate),
          ),
          throwsA(isA<DuplicateCommonProblemTitleException>()),
        );
      }

      final arabic = await repository.createCommonProblem(
        CreateCommonProblemInput(title: 'لا يعمل'),
      );

      expect(arabic.title, 'لا يعمل');
      final row = await database
          .customSelect(
            'SELECT normalized_title FROM common_problems WHERE id = ?',
            variables: [Variable<int>(arabic.id!)],
          )
          .getSingle();
      expect(row.read<String>('normalized_title'), 'لا يعمل');
    },
  );

  test(
    'rename preserves usage and createdAt while updating updatedAt',
    () async {
      final created = await repository.createCommonProblem(
        CreateCommonProblemInput(title: 'Broken screen'),
      );
      await repository.incrementUsage(created.id!);
      currentTime = DateTime.utc(2026, 7, 7, 10);

      final renamed = await repository.updateCommonProblemTitle(
        UpdateCommonProblemInput(id: created.id!, title: '  Cracked screen  '),
      );

      expect(renamed.id, created.id);
      expect(renamed.title, 'Cracked screen');
      expect(renamed.usageCount, 1);
      expect(renamed.createdAt, created.createdAt);
      expect(renamed.updatedAt, currentTime);
    },
  );

  test('duplicate rename and missing update fail safely', () async {
    final first = await repository.createCommonProblem(
      CreateCommonProblemInput(title: 'Broken screen'),
    );
    final second = await repository.createCommonProblem(
      CreateCommonProblemInput(title: 'Overheating'),
    );

    await expectLater(
      repository.updateCommonProblemTitle(
        UpdateCommonProblemInput(id: second.id!, title: ' broken   screen '),
      ),
      throwsA(isA<DuplicateCommonProblemTitleException>()),
    );
    await expectLater(
      repository.updateCommonProblemTitle(
        UpdateCommonProblemInput(id: first.id! + second.id! + 100, title: 'X'),
      ),
      throwsA(isA<CommonProblemNotFoundException>()),
    );
  });

  test(
    'delete removes common problem without modifying repair reported problem',
    () async {
      final problem = await repository.createCommonProblem(
        CreateCommonProblemInput(title: 'Does not power on'),
      );
      final repairRepository = _repairRepository(database, () => currentTime);
      final repair = await repairRepository.createRepair(
        CreateRepairInput(reportedProblem: problem.title, deviceType: 'Laptop'),
      );

      await repository.deleteCommonProblem(problem.id!);

      expect(await repository.getCommonProblemById(problem.id!), isNull);
      final reloadedRepair = await repairRepository.getRepairById(repair.id!);
      expect(reloadedRepair?.reportedProblem, 'Does not power on');
    },
  );

  test('list orders by usage, updatedAt, then stable ID', () async {
    final low = await repository.createCommonProblem(
      CreateCommonProblemInput(title: 'Low usage'),
    );
    final sameOld = await repository.createCommonProblem(
      CreateCommonProblemInput(title: 'Same old'),
    );
    final sameNew = await repository.createCommonProblem(
      CreateCommonProblemInput(title: 'Same new'),
    );
    currentTime = DateTime.utc(2026, 7, 7, 10);
    await repository.incrementUsage(sameOld.id!);
    currentTime = DateTime.utc(2026, 7, 7, 11);
    await repository.incrementUsage(sameNew.id!);
    currentTime = DateTime.utc(2026, 7, 7, 12);
    await repository.incrementUsage(low.id!);
    await repository.incrementUsage(low.id!);

    final listed = await repository.listCommonProblems();

    expect(listed.map((problem) => problem.title), [
      'Low usage',
      'Same new',
      'Same old',
    ]);
  });

  test(
    'search is SQL-side, case-insensitive, and blank behaves like list',
    () async {
      final first = await repository.createCommonProblem(
        CreateCommonProblemInput(title: 'Does not charge'),
      );
      final second = await repository.createCommonProblem(
        CreateCommonProblemInput(title: 'Broken screen'),
      );

      expect(
        (await repository.searchCommonProblems('CHARGE')).map((p) => p.id),
        [first.id],
      );
      expect(
        (await repository.searchCommonProblems(' screen ')).map((p) => p.id),
        [second.id],
      );
      expect(
        (await repository.searchCommonProblems('')).map((p) => p.id),
        (await repository.listCommonProblems()).map((p) => p.id),
      );
    },
  );

  test('usage increments atomically and missing ID fails safely', () async {
    final problem = await repository.createCommonProblem(
      CreateCommonProblemInput(title: 'Overheating'),
    );

    await repository.incrementUsage(problem.id!);
    currentTime = DateTime.utc(2026, 7, 7, 10);
    final updated = await repository.incrementUsage(problem.id!);

    expect(updated.usageCount, 2);
    expect(updated.updatedAt, currentTime);
    await expectLater(
      repository.incrementUsage(problem.id! + 999),
      throwsA(isA<CommonProblemNotFoundException>()),
    );
  });

  test('Riverpod providers expose repository and mutation use cases', () async {
    final container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(database)],
    );
    addTearDown(container.dispose);

    final created = await container.read(createCommonProblemUseCaseProvider)(
      CreateCommonProblemInput(title: 'Does not charge'),
    );
    final incremented = await container.read(
      incrementCommonProblemUsageUseCaseProvider,
    )(created.id!);
    final renamed = await container.read(updateCommonProblemUseCaseProvider)(
      UpdateCommonProblemInput(id: created.id!, title: 'Charging issue'),
    );
    await container.read(deleteCommonProblemUseCaseProvider)(created.id!);

    expect(incremented.usageCount, 1);
    expect(renamed.title, 'Charging issue');
    expect(
      await container
          .read(commonProblemRepositoryProvider)
          .getCommonProblemById(created.id!),
      isNull,
    );
  });

  test('version 5 database migrates to current schema with empty common problems', () async {
    final tempDirectory = await Directory.systemTemp.createTemp(
      'nova_repair_common_problem_v6_migration_test_',
    );
    addTearDown(() => tempDirectory.delete(recursive: true));
    final file = File('${tempDirectory.path}/migration.sqlite');
    final legacy = sqlite3.sqlite3.open(file.path);
    _createVersionFiveSchema(legacy);
    legacy
      ..execute(
        "INSERT INTO repairs "
        "(repair_code, reported_problem, status, customer_price_decision, created_at, updated_at, received_at) "
        "VALUES ('REP-0001', 'Original problem', 'received', 'not_requested', 0, 0, 0)",
      )
      ..execute(
        "INSERT INTO shop_settings "
        "(id, shop_name, repair_code_prefix, repair_code_number_width, "
        "default_customer_ticket_printer_id, default_device_label_printer_id, created_at, updated_at) "
        "VALUES (1, 'Legacy Shop', 'REP', 4, 'ticket-printer', 'label-printer', 0, 0)",
      )
      ..execute(
        'INSERT INTO repair_code_sequence (id, last_used_sequence) VALUES (1, 42)',
      )
      ..execute('PRAGMA user_version = 5');
    legacy.close();

    final migrated = AppDatabase(_fileDatabase(file));
    addTearDown(migrated.close);
    final version = await migrated
        .customSelect('PRAGMA user_version')
        .getSingle();
    final commonProblemCount = await migrated
        .customSelect('SELECT COUNT(*) AS value FROM common_problems')
        .getSingle();
    final repair = await migrated
        .customSelect(
          "SELECT repair_code FROM repairs WHERE repair_code = 'REP-0001'",
        )
        .getSingleOrNull();
    final settings = await migrated
        .customSelect(
          'SELECT default_customer_ticket_printer_id AS value FROM shop_settings WHERE id = 1',
        )
        .getSingle();
    final sequence = await migrated
        .customSelect(
          'SELECT last_used_sequence AS value FROM repair_code_sequence WHERE id = 1',
        )
        .getSingle();

    expect(version.read<int>('user_version'), 7);
    expect(commonProblemCount.read<int>('value'), 0);
    expect(repair, isNotNull);
    expect(settings.read<String>('value'), 'ticket-printer');
    expect(sequence.read<int>('value'), 42);
  });

  test(
    'backup and restore preserve v6 common problems and older backups migrate empty',
    () async {
      final tempDirectory = await Directory.systemTemp.createTemp(
        'nova_repair_common_problem_backup_test_',
      );
      addTearDown(() => tempDirectory.delete(recursive: true));
      final file = File('${tempDirectory.path}/nova_repair.sqlite');
      final manager = _lifecycleManager(file);
      addTearDown(manager.closeCurrentDatabase);
      final backupService = LocalBackupService(
        manager,
        const BackupValidator(),
        now: () => DateTime.utc(2026, 7, 8, 12),
      );
      final commonRepository = _commonProblemRepository(
        manager.database,
        () => currentTime,
      );

      final problem = await commonRepository.createCommonProblem(
        CreateCommonProblemInput(title: 'Does not charge'),
      );
      await commonRepository.incrementUsage(problem.id!);
      await commonRepository.incrementUsage(problem.id!);
      final backup = await backupService.createBackupFile(
        '${tempDirectory.path}/common_problem_backup.nrbackup',
      );

      await commonRepository.deleteCommonProblem(problem.id!);
      await backupService.restoreBackup(backup.filePath);

      final restoredRows = await manager.database
          .customSelect(
            'SELECT title, usage_count FROM common_problems WHERE title = ?',
            variables: [Variable<String>('Does not charge')],
          )
          .get();
      expect(backup.schemaVersion, 7);
      expect(restoredRows.single.read<int>('usage_count'), 2);

      final olderBackup = File('${tempDirectory.path}/older_v5.sqlite');
      final legacy = sqlite3.sqlite3.open(olderBackup.path);
      _createVersionFiveSchema(legacy);
      legacy
        ..execute(
          "INSERT INTO repairs "
          "(repair_code, reported_problem, status, customer_price_decision, created_at, updated_at, received_at) "
          "VALUES ('REP-0002', 'Legacy repair', 'received', 'not_requested', 0, 0, 0)",
        )
        ..execute('PRAGMA user_version = 5');
      legacy.close();

      await backupService.restoreBackup(olderBackup.path);
      final version = await manager.database
          .customSelect('PRAGMA user_version')
          .getSingle();
      final count = await manager.database
          .customSelect('SELECT COUNT(*) AS value FROM common_problems')
          .getSingle();

      expect(version.read<int>('user_version'), 7);
      expect(count.read<int>('value'), 0);
    },
  );
}

DriftCommonProblemRepository _commonProblemRepository(
  AppDatabase database,
  DateTime Function() now,
) {
  return DriftCommonProblemRepository(
    database,
    CommonProblemLocalDataSource(database),
    now: now,
  );
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

DatabaseLifecycleManager _lifecycleManager(File file) {
  AppDatabase open(File databaseFile) =>
      AppDatabase(_fileDatabase(databaseFile));

  return DatabaseLifecycleManager(
    resolveDatabaseFile: () async => file,
    openDatabase: open,
    initialDatabase: open(file),
  );
}

void _createVersionFiveSchema(sqlite3.Database database) {
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
