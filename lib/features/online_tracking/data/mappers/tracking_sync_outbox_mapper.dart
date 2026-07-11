import '../../../../database/app_database.dart';
import '../../domain/tracking_sync_operation.dart';
import '../../domain/tracking_sync_outbox_entry.dart';

extension TrackingSyncOutboxRowMapper on TrackingSyncOutboxRow {
  TrackingSyncOutboxEntry toDomain() {
    return TrackingSyncOutboxEntry(
      id: id,
      repairId: repairId,
      operation: TrackingSyncOperation.fromDatabaseValue(operation),
      attemptCount: attemptCount,
      lastError: lastError,
      nextAttemptAt: nextAttemptAt.toUtc(),
      createdAt: createdAt.toUtc(),
      updatedAt: updatedAt.toUtc(),
    );
  }
}
