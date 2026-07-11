import 'dart:io';

import 'app_database.dart';

class DatabaseLifecycleManager {
  DatabaseLifecycleManager({
    required Future<File> Function() resolveDatabaseFile,
    required AppDatabase Function(File file) openDatabase,
    AppDatabase? initialDatabase,
  }) : _resolveDatabaseFile = resolveDatabaseFile,
       _openDatabase = openDatabase,
       _database = initialDatabase ?? AppDatabase();

  factory DatabaseLifecycleManager.production() {
    return DatabaseLifecycleManager(
      resolveDatabaseFile: resolveAppDatabaseFile,
      openDatabase: (file) => AppDatabase(openNativeDatabaseFile(file)),
      initialDatabase: AppDatabase(),
    );
  }

  final Future<File> Function() _resolveDatabaseFile;
  final AppDatabase Function(File file) _openDatabase;
  AppDatabase _database;
  bool _isClosed = false;

  AppDatabase get database => _database;

  Future<File> resolveDatabaseFile() => _resolveDatabaseFile();

  Future<void> closeCurrentDatabase() async {
    if (_isClosed) {
      return;
    }
    await _database.close();
    _isClosed = true;
  }

  Future<AppDatabase> reopenDatabase() async {
    final file = await _resolveDatabaseFile();
    _database = _openDatabase(file);
    _isClosed = false;
    return _database;
  }
}
