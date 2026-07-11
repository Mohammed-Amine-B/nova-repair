enum TrackingSyncOperation {
  upsertSnapshot('upsert_snapshot');

  const TrackingSyncOperation(this.databaseValue);

  final String databaseValue;

  static TrackingSyncOperation fromDatabaseValue(String value) {
    for (final operation in TrackingSyncOperation.values) {
      if (operation.databaseValue == value) {
        return operation;
      }
    }

    throw FormatException('Unknown tracking sync operation: $value');
  }
}
