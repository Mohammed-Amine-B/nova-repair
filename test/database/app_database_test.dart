import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_repair/database/app_database.dart';
import 'package:path/path.dart' as p;

void main() {
  test('database initializes and exposes schema version', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    await database.customSelect('SELECT 1').getSingle();
    final userVersion = await database
        .customSelect('PRAGMA user_version')
        .getSingle();

    expect(database.schemaVersion, 7);
    expect(userVersion.read<int>('user_version'), 7);

    final commonProblemsTable = await database
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'common_problems'",
        )
        .getSingleOrNull();
    final trackingOutboxTable = await database
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'tracking_sync_outbox'",
        )
        .getSingleOrNull();
    expect(commonProblemsTable, isNotNull);
    expect(trackingOutboxTable, isNotNull);
  });

  test('persistent database path uses app support directory', () async {
    final tempDirectory = await Directory.systemTemp.createTemp(
      'nova_repair_db_path_test_',
    );
    addTearDown(() => tempDirectory.delete(recursive: true));

    final file = await resolveAppDatabaseFile(
      appSupportDirectoryProvider: () async => tempDirectory,
    );

    expect(
      file.path,
      p.join(tempDirectory.path, 'Nova Repair', appDatabaseFileName),
    );
  });
}
