import 'package:drift/drift.dart';

import '../../../../database/app_database.dart';

const repairCodeSequenceSingletonId = 1;

class RepairCodeSequenceLocalDataSource {
  const RepairCodeSequenceLocalDataSource(this._database);

  final AppDatabase _database;

  Future<RepairCodeSequenceRow?> getSequenceRow() {
    return (_database.select(_database.repairCodeSequenceTable)
          ..where((row) => row.id.equals(repairCodeSequenceSingletonId)))
        .getSingleOrNull();
  }

  Future<void> saveLastUsedSequence(int lastUsedSequence) {
    return _database
        .into(_database.repairCodeSequenceTable)
        .insertOnConflictUpdate(
          RepairCodeSequenceTableCompanion.insert(
            id: const Value(repairCodeSequenceSingletonId),
            lastUsedSequence: lastUsedSequence,
          ),
        );
  }
}
