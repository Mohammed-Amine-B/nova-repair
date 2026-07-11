import '../../repairs/domain/repositories/repair_repository.dart';
import '../../settings/domain/repositories/shop_settings_repository.dart';
import '../domain/public_tracking_identity.dart';
import '../domain/repositories/tracking_sync_outbox_repository.dart';
import 'build_public_repair_tracking_snapshot.dart';
import 'installation_credential_store.dart';
import 'repair_tracking_publish_client.dart';
import 'tracking_sync_retry_policy.dart';

typedef TrackingSyncDiagnosticLog = void Function(String message);

class TrackingSyncProcessor {
  const TrackingSyncProcessor({
    required TrackingSyncOutboxRepository outboxRepository,
    required RepairRepository repairRepository,
    required ShopSettingsRepository shopSettingsRepository,
    required InstallationCredentialStore credentialStore,
    required BuildPublicRepairTrackingSnapshot snapshotBuilder,
    required RepairTrackingPublishClient publishClient,
    required TrackingSyncRetryPolicy retryPolicy,
    DateTime Function()? now,
    int batchLimit = 20,
    TrackingSyncDiagnosticLog? diagnosticLog,
  }) : _outboxRepository = outboxRepository,
       _repairRepository = repairRepository,
       _shopSettingsRepository = shopSettingsRepository,
       _credentialStore = credentialStore,
       _snapshotBuilder = snapshotBuilder,
       _publishClient = publishClient,
       _retryPolicy = retryPolicy,
       _now = now ?? DateTime.now,
       _batchLimit = batchLimit,
       _diagnosticLog = diagnosticLog;

  final TrackingSyncOutboxRepository _outboxRepository;
  final RepairRepository _repairRepository;
  final ShopSettingsRepository _shopSettingsRepository;
  final InstallationCredentialStore _credentialStore;
  final BuildPublicRepairTrackingSnapshot _snapshotBuilder;
  final RepairTrackingPublishClient _publishClient;
  final TrackingSyncRetryPolicy _retryPolicy;
  final DateTime Function() _now;
  final int _batchLimit;
  final TrackingSyncDiagnosticLog? _diagnosticLog;

  Future<void> processDue() async {
    final installationSecret = await _credentialStore.readInstallationSecret();
    if (installationSecret == null || installationSecret.isEmpty) {
      _diagnosticLog?.call('Tracking sync skipped: no credential');
      return;
    }

    final now = _now().toUtc();
    final entries = await _outboxRepository.listDue(
      now: now,
      limit: _batchLimit,
    );
    if (entries.isEmpty) {
      _diagnosticLog?.call('Tracking sync skipped: no due entries');
      return;
    }

    _diagnosticLog?.call('Tracking sync processing ${entries.length} entries');
    final settings = await _shopSettingsRepository.getSettings();
    final publicShopId = settings.publicShopId;
    if (publicShopId == null || publicShopId.isEmpty) {
      return;
    }

    for (final entry in entries) {
      final repair = await _repairRepository.getRepairById(entry.repairId);
      if (repair == null) {
        await _outboxRepository.dropStaleEntry(entry.id);
        continue;
      }

      final trackingToken = repair.trackingToken;
      if (trackingToken == null || trackingToken.isEmpty) {
        await _outboxRepository.markPublishFailure(
          entryId: entry.id,
          safeError: _retryPolicy.safeErrorFor(
            RepairTrackingPublishFailure.invalidPayload,
          ),
          nextAttemptAt: _now().toUtc().add(
            _retryPolicy.delayFor(
              failure: RepairTrackingPublishFailure.invalidPayload,
              currentAttemptCount: entry.attemptCount,
            ),
          ),
        );
        continue;
      }

      final identity = PublicTrackingIdentity(
        trackingToken: trackingToken,
        publicShopId: publicShopId,
      );
      final snapshot = _snapshotBuilder(
        repair: repair,
        settings: settings,
        identity: identity,
      );
      final result = await _publishClient.publish(
        installationSecret: installationSecret,
        snapshot: snapshot,
      );

      if (result.isSuccess) {
        await _outboxRepository.markPublishSuccess(entry.id);
        continue;
      }

      final failure = result.failure!;
      final delay = _retryPolicy.delayFor(
        failure: failure,
        currentAttemptCount: entry.attemptCount,
      );
      await _outboxRepository.markPublishFailure(
        entryId: entry.id,
        safeError: _retryPolicy.safeErrorFor(failure),
        nextAttemptAt: _now().toUtc().add(delay),
      );

      if (_retryPolicy.shouldStopCycle(failure)) {
        return;
      }
    }
  }
}
