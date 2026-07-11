import '../tracking_sync_outbox_entry.dart';

abstract class TrackingSyncOutboxRepository {
  Future<void> enqueueRepair(int repairId);

  Future<List<TrackingSyncOutboxEntry>> listDue({
    required DateTime now,
    required int limit,
  });

  Future<void> markPublishSuccess(int entryId);

  Future<void> markPublishFailure({
    required int entryId,
    required String safeError,
    required DateTime nextAttemptAt,
  });

  Future<void> dropStaleEntry(int entryId);
}
