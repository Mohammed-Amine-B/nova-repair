import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

import 'app_database.dart';

const localDatabaseDirectoryName = 'Nova Repair';

class LocalDatabasePathResolver {
  const LocalDatabasePathResolver({
    this.documentsDirectoryProvider = getApplicationDocumentsDirectory,
    this.legacyAppSupportDirectoryProvider = getApplicationSupportDirectory,
    this.fileName = appDatabaseFileName,
  });

  final Future<Directory> Function() documentsDirectoryProvider;
  final Future<Directory> Function() legacyAppSupportDirectoryProvider;
  final String fileName;

  Future<File> resolveDatabaseFile() async {
    final canonicalFile = await resolveCanonicalDatabaseFile();
    if (await canonicalFile.exists()) {
      return canonicalFile;
    }

    final legacyFile = await resolveLegacyDatabaseFile();
    if (await legacyFile.exists()) {
      await _migrateLegacyDatabase(legacyFile, canonicalFile);
    }

    return canonicalFile;
  }

  Future<File> resolveCanonicalDatabaseFile() async {
    final documentsDirectory = await documentsDirectoryProvider();
    final databaseDirectory = Directory(
      p.join(documentsDirectory.path, localDatabaseDirectoryName),
    );
    await databaseDirectory.create(recursive: true);
    return File(p.join(databaseDirectory.path, fileName));
  }

  Future<File> resolveLegacyDatabaseFile() async {
    final appSupportDirectory = await legacyAppSupportDirectoryProvider();
    return File(
      p.join(appSupportDirectory.path, localDatabaseDirectoryName, fileName),
    );
  }

  Future<void> _migrateLegacyDatabase(
    File legacyFile,
    File canonicalFile,
  ) async {
    final tempFile = File('${canonicalFile.path}.migration_tmp');

    try {
      await canonicalFile.parent.create(recursive: true);
      if (await canonicalFile.exists()) {
        return;
      }

      await _deleteIfExists(tempFile);
      await _deleteSqliteSidecars(tempFile);
      await _checkpointLegacyDatabase(legacyFile);
      await legacyFile.copy(tempFile.path);
      await _validateSqliteDatabase(tempFile);

      if (await canonicalFile.exists()) {
        await _deleteIfExists(tempFile);
        return;
      }

      await tempFile.rename(canonicalFile.path);
    } catch (_) {
      await _deleteIfExists(tempFile);
      await _deleteSqliteSidecars(tempFile);
      rethrow;
    }
  }

  Future<void> _checkpointLegacyDatabase(File legacyFile) async {
    final database = sqlite3.sqlite3.open(legacyFile.path);
    try {
      database.execute('PRAGMA wal_checkpoint(TRUNCATE)');
      database.execute('PRAGMA optimize');
    } finally {
      database.close();
    }
  }

  Future<void> _validateSqliteDatabase(File databaseFile) async {
    final database = sqlite3.sqlite3.open(databaseFile.path);
    try {
      final integrity = database.select('PRAGMA integrity_check').first;
      if (integrity.values.first != 'ok') {
        throw const FileSystemException(
          'Copied database failed integrity check',
        );
      }

      database.select('PRAGMA user_version');
    } finally {
      database.close();
    }
  }

  Future<void> _deleteSqliteSidecars(File databaseFile) async {
    await _deleteIfExists(File('${databaseFile.path}-wal'));
    await _deleteIfExists(File('${databaseFile.path}-shm'));
  }

  Future<void> _deleteIfExists(File file) async {
    if (await file.exists()) {
      await file.delete();
    }
  }
}
