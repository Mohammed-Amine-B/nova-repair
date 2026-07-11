sealed class BackupException implements Exception {
  const BackupException(this.message);

  final String message;

  @override
  String toString() => message;
}

class BackupSourceUnavailableException extends BackupException {
  const BackupSourceUnavailableException()
    : super('The application database is not available for backup.');
}

class BackupDestinationInvalidException extends BackupException {
  const BackupDestinationInvalidException()
    : super('The selected backup destination is not a writable directory.');
}

class BackupCreationException extends BackupException {
  const BackupCreationException() : super('The backup could not be created.');
}

class BackupValidationException extends BackupException {
  const BackupValidationException(String reason)
    : super('The backup file is not valid: $reason');
}

class UnsupportedBackupSchemaException extends BackupException {
  const UnsupportedBackupSchemaException(this.schemaVersion)
    : super('Backup schema version $schemaVersion is not supported.');

  final int schemaVersion;
}

class RestoreFromCurrentDatabaseException extends BackupException {
  const RestoreFromCurrentDatabaseException()
    : super('Cannot restore from the current live database file.');
}

class RestoreException extends BackupException {
  const RestoreException() : super('The backup could not be restored.');
}

class RestoreRollbackException extends BackupException {
  const RestoreRollbackException()
    : super('Restore failed and the previous database could not be restored.');
}
