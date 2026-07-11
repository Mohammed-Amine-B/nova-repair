import 'package:drift/drift.dart';

import '../../../../database/app_database.dart';
import '../../domain/tracking_sync_operation.dart';

class TrackingSyncOutboxLocalDataSource {
  const TrackingSyncOutboxLocalDataSource(this._database);

  final AppDatabase _database;

  Future<void> enqueueRepair({
    required int repairId,
    required DateTime now,
  }) async {
    final utcNowValue = _millisecondsSinceEpoch(now);

    await _database.customUpdate(
      '''
      INSERT INTO tracking_sync_outbox (
        repair_id,
        operation,
        attempt_count,
        last_error,
        next_attempt_at,
        created_at,
        updated_at
      )
      VALUES (?, ?, 0, NULL, ?, ?, ?)
      ON CONFLICT(repair_id) DO UPDATE SET
        operation = excluded.operation,
        attempt_count = 0,
        last_error = NULL,
        next_attempt_at = excluded.next_attempt_at,
        updated_at = excluded.updated_at
      ''',
      variables: [
        Variable.withInt(repairId),
        Variable.withString(TrackingSyncOperation.upsertSnapshot.databaseValue),
        Variable.withInt(utcNowValue),
        Variable.withInt(utcNowValue),
        Variable.withInt(utcNowValue),
      ],
      updates: {_database.trackingSyncOutboxTable},
    );
  }

  Future<TrackingSyncOutboxRow?> getEntryForRepair(int repairId) async {
    final row = await _database
        .customSelect(
          '''
          SELECT id,
                 repair_id,
                 operation,
                 attempt_count,
                 last_error,
                 next_attempt_at,
                 created_at,
                 updated_at
          FROM tracking_sync_outbox
          WHERE repair_id = ?
          ''',
          variables: [Variable.withInt(repairId)],
          readsFrom: {_database.trackingSyncOutboxTable},
        )
        .getSingleOrNull();
    return row == null ? null : _rowFromQuery(row);
  }

  Future<List<TrackingSyncOutboxRow>> listDue({
    required DateTime now,
    required int limit,
  }) {
    if (limit <= 0) {
      throw ArgumentError.value(limit, 'limit', 'Must be positive.');
    }

    return _database
        .customSelect(
          '''
          SELECT id,
                 repair_id,
                 operation,
                 attempt_count,
                 last_error,
                 next_attempt_at,
                 created_at,
                 updated_at
          FROM tracking_sync_outbox
          WHERE next_attempt_at <= ?
          ORDER BY next_attempt_at ASC,
                   created_at ASC,
                   id ASC
          LIMIT ?
          ''',
          variables: [
            Variable.withInt(_millisecondsSinceEpoch(now)),
            Variable.withInt(limit),
          ],
          readsFrom: {_database.trackingSyncOutboxTable},
        )
        .map(_rowFromQuery)
        .get();
  }

  Future<int> markSuccess(int entryId) {
    return (_database.delete(
      _database.trackingSyncOutboxTable,
    )..where((row) => row.id.equals(entryId))).go();
  }

  Future<int> dropEntry(int entryId) {
    return markSuccess(entryId);
  }

  Future<int> markFailure({
    required int entryId,
    required String safeError,
    required DateTime nextAttemptAt,
    required DateTime now,
  }) {
    return _database.customUpdate(
      '''
      UPDATE tracking_sync_outbox
      SET attempt_count = attempt_count + 1,
          last_error = ?,
          next_attempt_at = ?,
          updated_at = ?
      WHERE id = ?
      ''',
      variables: [
        Variable.withString(_normalizeError(safeError)),
        Variable.withInt(_millisecondsSinceEpoch(nextAttemptAt)),
        Variable.withInt(_millisecondsSinceEpoch(now)),
        Variable.withInt(entryId),
      ],
      updates: {_database.trackingSyncOutboxTable},
    );
  }

  TrackingSyncOutboxRow _rowFromQuery(QueryRow row) {
    return TrackingSyncOutboxRow(
      id: row.read<int>('id'),
      repairId: row.read<int>('repair_id'),
      operation: row.read<String>('operation'),
      attemptCount: row.read<int>('attempt_count'),
      lastError: row.readNullable<String>('last_error'),
      nextAttemptAt: _dateTimeFromMilliseconds(
        row.read<int>('next_attempt_at'),
      ),
      createdAt: _dateTimeFromMilliseconds(row.read<int>('created_at')),
      updatedAt: _dateTimeFromMilliseconds(row.read<int>('updated_at')),
    );
  }

  int _millisecondsSinceEpoch(DateTime value) {
    return value.toUtc().millisecondsSinceEpoch;
  }

  DateTime _dateTimeFromMilliseconds(int value) {
    return DateTime.fromMillisecondsSinceEpoch(value, isUtc: true);
  }

  String _normalizeError(String value) {
    final trimmed = value.trim();
    if (trimmed.length <= 240) {
      return trimmed;
    }

    return trimmed.substring(0, 240);
  }
}
