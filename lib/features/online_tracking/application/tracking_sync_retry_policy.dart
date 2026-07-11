import 'repair_tracking_publish_client.dart';

class TrackingSyncRetryPolicy {
  const TrackingSyncRetryPolicy();

  Duration delayFor({
    required RepairTrackingPublishFailure failure,
    required int currentAttemptCount,
  }) {
    return switch (failure) {
      RepairTrackingPublishFailure.authenticationFailed => const Duration(
        hours: 1,
      ),
      RepairTrackingPublishFailure.invalidPayload => const Duration(hours: 24),
      RepairTrackingPublishFailure.ownershipConflict => const Duration(
        hours: 24,
      ),
      RepairTrackingPublishFailure.networkError ||
      RepairTrackingPublishFailure.timeout ||
      RepairTrackingPublishFailure.rateLimited ||
      RepairTrackingPublishFailure.serverError ||
      RepairTrackingPublishFailure.unexpectedResponse => _temporaryDelay(
        currentAttemptCount,
      ),
    };
  }

  String safeErrorFor(RepairTrackingPublishFailure failure) {
    return switch (failure) {
      RepairTrackingPublishFailure.networkError => 'network_error',
      RepairTrackingPublishFailure.timeout => 'timeout',
      RepairTrackingPublishFailure.rateLimited => 'rate_limited',
      RepairTrackingPublishFailure.serverError => 'server_error',
      RepairTrackingPublishFailure.authenticationFailed =>
        'authentication_failed',
      RepairTrackingPublishFailure.invalidPayload => 'invalid_payload',
      RepairTrackingPublishFailure.ownershipConflict => 'ownership_conflict',
      RepairTrackingPublishFailure.unexpectedResponse => 'unexpected_response',
    };
  }

  bool shouldStopCycle(RepairTrackingPublishFailure failure) {
    return failure == RepairTrackingPublishFailure.authenticationFailed;
  }

  Duration _temporaryDelay(int currentAttemptCount) {
    return switch (currentAttemptCount + 1) {
      1 => const Duration(seconds: 30),
      2 => const Duration(minutes: 2),
      3 => const Duration(minutes: 10),
      4 => const Duration(minutes: 30),
      _ => const Duration(minutes: 60),
    };
  }
}
