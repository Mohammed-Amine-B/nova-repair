import 'tracking_sync_operation.dart';

class TrackingSyncOutboxEntry {
  const TrackingSyncOutboxEntry({
    required this.id,
    required this.repairId,
    required this.operation,
    required this.attemptCount,
    this.lastError,
    required this.nextAttemptAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int repairId;
  final TrackingSyncOperation operation;
  final int attemptCount;
  final String? lastError;
  final DateTime nextAttemptAt;
  final DateTime createdAt;
  final DateTime updatedAt;
}
