import 'dart:io';

import 'package:path/path.dart' as p;

import '../../../database/database_lifecycle_manager.dart';
import '../domain/entities/backup_metadata.dart';
import '../domain/errors/backup_exception.dart';
import '../infrastructure/backup_validator.dart';

class LocalBackupService {
  const LocalBackupService(
    this._databaseLifecycleManager,
    this._validator, {
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final DatabaseLifecycleManager _databaseLifecycleManager;
  final BackupValidator _validator;
  final DateTime Function() _now;

  Future<BackupMetadata> createBackup(String destinationDirectoryPath) async {
    final databaseFile = await _databaseLifecycleManager.resolveDatabaseFile();
    if (!await databaseFile.exists()) {
      throw const BackupSourceUnavailableException();
    }

    final destinationDirectory = await _prepareDestinationDirectory(
      destinationDirectoryPath,
    );
    final createdAt = _now();
    final fileName = buildBackupFileName(createdAt);
    final finalFile = File(p.join(destinationDirectory.path, fileName));
    final tempFile = File(p.join(destinationDirectory.path, '.$fileName.tmp'));

    if (await finalFile.exists()) {
      throw const BackupCreationException();
    }

    try {
      await _deleteIfExists(tempFile);
      await _databaseLifecycleManager.database.customStatement(
        'VACUUM INTO ?',
        [tempFile.path],
      );

      await _validator.validateBackup(tempFile.path);
      await tempFile.rename(finalFile.path);
      final validated = await _validator.validateBackup(finalFile.path);

      return BackupMetadata(
        filePath: validated.filePath,
        fileName: validated.fileName,
        createdAt: createdAt.toUtc(),
        fileSizeBytes: validated.fileSizeBytes,
        schemaVersion: validated.schemaVersion,
        repairCount: validated.repairCount,
      );
    } on BackupException {
      await _deleteIfExists(tempFile);
      rethrow;
    } on Object {
      await _deleteIfExists(tempFile);
      throw const BackupCreationException();
    }
  }

  Future<BackupMetadata> createBackupFile(String destinationFilePath) async {
    final databaseFile = await _databaseLifecycleManager.resolveDatabaseFile();
    if (!await databaseFile.exists()) {
      throw const BackupSourceUnavailableException();
    }

    final finalFile = File(destinationFilePath);
    final destinationDirectory = await _prepareDestinationDirectory(
      finalFile.parent.path,
    );
    final fileName = p.basename(finalFile.path);
    final resolvedFinalFile = File(p.join(destinationDirectory.path, fileName));
    final tempFile = File(p.join(destinationDirectory.path, '.$fileName.tmp'));
    final createdAt = _now();

    if (await resolvedFinalFile.exists()) {
      throw const BackupCreationException();
    }

    try {
      await _deleteIfExists(tempFile);
      await _databaseLifecycleManager.database.customStatement(
        'VACUUM INTO ?',
        [tempFile.path],
      );

      await _validator.validateBackup(tempFile.path);
      await tempFile.rename(resolvedFinalFile.path);
      final validated = await _validator.validateBackup(resolvedFinalFile.path);

      return BackupMetadata(
        filePath: validated.filePath,
        fileName: validated.fileName,
        createdAt: createdAt.toUtc(),
        fileSizeBytes: validated.fileSizeBytes,
        schemaVersion: validated.schemaVersion,
        repairCount: validated.repairCount,
      );
    } on BackupException {
      await _deleteIfExists(tempFile);
      rethrow;
    } on Object {
      await _deleteIfExists(tempFile);
      throw const BackupCreationException();
    }
  }

  Future<BackupMetadata> validateBackup(String backupFilePath) {
    return _validator.validateBackup(backupFilePath);
  }

  Future<BackupMetadata> restoreBackup(String backupFilePath) async {
    final selectedBackup = File(backupFilePath);
    final validatedBackup = await _validator.validateBackup(
      selectedBackup.path,
    );
    final databaseFile = await _databaseLifecycleManager.resolveDatabaseFile();

    if (_samePath(selectedBackup.path, databaseFile.path)) {
      throw const RestoreFromCurrentDatabaseException();
    }

    final safetyFile = File(
      p.join(
        databaseFile.parent.path,
        '.restore_safety_${_formatForFileName(_now())}.sqlite',
      ),
    );

    try {
      await _deleteIfExists(safetyFile);
      if (await databaseFile.exists()) {
        await _databaseLifecycleManager.database.customStatement(
          'VACUUM INTO ?',
          [safetyFile.path],
        );
        await _validator.validateBackup(safetyFile.path);
      }

      await _databaseLifecycleManager.closeCurrentDatabase();
      try {
        await databaseFile.parent.create(recursive: true);
        await _deleteSqliteSidecars(databaseFile);
        await selectedBackup.copy(databaseFile.path);
        final reopened = await _databaseLifecycleManager.reopenDatabase();
        await reopened.customSelect('SELECT 1').getSingle();
        await _validator.validateBackup(databaseFile.path);
      } on Object {
        await _rollbackRestore(databaseFile, safetyFile);
        rethrow;
      }

      await _deleteIfExists(safetyFile);

      return BackupMetadata(
        filePath: databaseFile.path,
        fileName: p.basename(databaseFile.path),
        createdAt: validatedBackup.createdAt,
        fileSizeBytes: (await databaseFile.stat()).size,
        schemaVersion: _databaseLifecycleManager.database.schemaVersion,
        repairCount: (await _validator.validateBackup(
          databaseFile.path,
        )).repairCount,
      );
    } on RestoreFromCurrentDatabaseException {
      rethrow;
    } on BackupException {
      rethrow;
    } on Object {
      throw const RestoreException();
    } finally {
      await _deleteIfExists(safetyFile);
    }
  }

  static String buildBackupFileName(DateTime createdAt) {
    return 'nova_repair_backup_${_formatForFileName(createdAt)}.sqlite';
  }

  static String _formatForFileName(DateTime value) {
    final local = value.toLocal();
    return '${_four(local.year)}-${_two(local.month)}-${_two(local.day)}_'
        '${_two(local.hour)}${_two(local.minute)}${_two(local.second)}';
  }

  static String _four(int value) => value.toString().padLeft(4, '0');

  static String _two(int value) => value.toString().padLeft(2, '0');

  Future<Directory> _prepareDestinationDirectory(String path) async {
    final directory = Directory(path);
    try {
      await directory.create(recursive: true);
      final stat = await directory.stat();
      if (stat.type != FileSystemEntityType.directory) {
        throw const BackupDestinationInvalidException();
      }

      final probe = File(
        p.join(
          directory.path,
          '.nova_repair_backup_write_probe_${_formatForFileName(_now())}',
        ),
      );
      await probe.writeAsString('ok');
      await _deleteIfExists(probe);
      return directory;
    } on BackupException {
      rethrow;
    } on Object {
      throw const BackupDestinationInvalidException();
    }
  }

  Future<void> _rollbackRestore(File databaseFile, File safetyFile) async {
    try {
      await _databaseLifecycleManager.closeCurrentDatabase();
      await _deleteSqliteSidecars(databaseFile);
      if (await safetyFile.exists()) {
        await safetyFile.copy(databaseFile.path);
      } else {
        await _deleteIfExists(databaseFile);
      }
      final reopened = await _databaseLifecycleManager.reopenDatabase();
      await reopened.customSelect('SELECT 1').getSingle();
    } on Object {
      throw const RestoreRollbackException();
    }
  }

  bool _samePath(String first, String second) {
    return p.normalize(p.absolute(first)) == p.normalize(p.absolute(second));
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
