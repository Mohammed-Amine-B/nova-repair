import '../../domain/repositories/tracking_sync_outbox_repository.dart';
import '../../domain/tracking_sync_outbox_entry.dart';
import '../datasources/tracking_sync_outbox_local_data_source.dart';
import '../mappers/tracking_sync_outbox_mapper.dart';

class DriftTrackingSyncOutboxRepository
    implements TrackingSyncOutboxRepository {
  const DriftTrackingSyncOutboxRepository(
    this._localDataSource, {
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final TrackingSyncOutboxLocalDataSource _localDataSource;
  final DateTime Function() _now;

  @override
  Future<void> enqueueRepair(int repairId) {
    return _localDataSource.enqueueRepair(repairId: repairId, now: _now());
  }

  @override
  Future<List<TrackingSyncOutboxEntry>> listDue({
    required DateTime now,
    required int limit,
  }) async {
    final rows = await _localDataSource.listDue(now: now, limit: limit);
    return [for (final row in rows) row.toDomain()];
  }

  @override
  Future<void> markPublishSuccess(int entryId) async {
    await _localDataSource.markSuccess(entryId);
  }

  @override
  Future<void> markPublishFailure({
    required int entryId,
    required String safeError,
    required DateTime nextAttemptAt,
  }) async {
    await _localDataSource.markFailure(
      entryId: entryId,
      safeError: safeError,
      nextAttemptAt: nextAttemptAt,
      now: _now(),
    );
  }

  @override
  Future<void> dropStaleEntry(int entryId) async {
    await _localDataSource.dropEntry(entryId);
  }
}
