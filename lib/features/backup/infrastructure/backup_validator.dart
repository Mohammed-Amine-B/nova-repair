import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart' as sqlite3;

import '../domain/entities/backup_metadata.dart';
import '../domain/errors/backup_exception.dart';

class BackupValidator {
  const BackupValidator();

  static const supportedSchemaVersions = {1, 2, 3, 4, 5, 6, 7};

  Future<BackupMetadata> validateBackup(String backupFilePath) async {
    final file = File(backupFilePath);
    if (!await file.exists()) {
      throw const BackupValidationException('file does not exist');
    }

    final stat = await file.stat();
    if (stat.type != FileSystemEntityType.file) {
      throw const BackupValidationException('path is not a file');
    }
    if (stat.size <= 0) {
      throw const BackupValidationException('file is empty');
    }

    sqlite3.Database database;
    try {
      database = sqlite3.sqlite3.open(file.path);
    } on Object {
      throw const BackupValidationException('SQLite could not open the file');
    }

    try {
      final schemaVersion = _readUserVersion(database);
      if (!supportedSchemaVersions.contains(schemaVersion)) {
        throw UnsupportedBackupSchemaException(schemaVersion);
      }

      _validateRequiredTables(database, schemaVersion);

      return BackupMetadata(
        filePath: file.path,
        fileName: p.basename(file.path),
        createdAt: stat.modified.toUtc(),
        fileSizeBytes: stat.size,
        schemaVersion: schemaVersion,
        repairCount: _readRepairCount(database),
      );
    } on BackupException {
      rethrow;
    } on Object {
      throw const BackupValidationException('SQLite validation failed');
    } finally {
      database.close();
    }
  }

  int _readUserVersion(sqlite3.Database database) {
    final result = database.select('PRAGMA user_version');
    return result.first['user_version'] as int;
  }

  void _validateRequiredTables(sqlite3.Database database, int schemaVersion) {
    final requiredTables = <String>[
      if (schemaVersion >= 2) 'repairs',
      if (schemaVersion >= 3) 'shop_settings',
      if (schemaVersion >= 4) 'repair_code_sequence',
      if (schemaVersion >= 6) 'common_problems',
      if (schemaVersion >= 7) 'tracking_sync_outbox',
    ];

    for (final table in requiredTables) {
      final result = database.select(
        "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
        [table],
      );
      if (result.isEmpty) {
        throw BackupValidationException('required table is missing');
      }
    }
  }

  int _readRepairCount(sqlite3.Database database) {
    final hasRepairs = database.select(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'repairs'",
    );
    if (hasRepairs.isEmpty) {
      return 0;
    }

    final result = database.select('SELECT COUNT(*) AS count FROM repairs');
    return result.first['count'] as int;
  }

  Future<BackupMetadata> validateCurrentDatabaseFile(File file) {
    return validateBackup(file.path);
  }
}
