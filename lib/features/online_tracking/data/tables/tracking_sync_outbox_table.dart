import 'package:drift/drift.dart';

import '../../../repairs/data/tables/repairs_table.dart';

@DataClassName('TrackingSyncOutboxRow')
class TrackingSyncOutboxTable extends Table {
  @override
  String get tableName => 'tracking_sync_outbox';

  IntColumn get id => integer().autoIncrement()();

  IntColumn get repairId => integer().references(Repairs, #id).unique()();

  TextColumn get operation => text().customConstraint(
    "NOT NULL CHECK(operation IN ('upsert_snapshot'))",
  )();

  IntColumn get attemptCount =>
      integer().customConstraint('NOT NULL CHECK(attempt_count >= 0)')();

  TextColumn get lastError => text().nullable()();

  DateTimeColumn get nextAttemptAt => dateTime()();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();
}
