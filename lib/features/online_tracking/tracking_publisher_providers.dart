import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repairs/repair_providers.dart';
import '../settings/settings_providers.dart';
import 'application/build_public_repair_tracking_snapshot.dart';
import 'application/repair_tracking_publish_client.dart';
import 'application/tracking_sync_coordinator.dart';
import 'application/tracking_sync_processor.dart';
import 'application/tracking_sync_retry_policy.dart';
import 'online_tracking_providers.dart';

final publicRepairTrackingSnapshotBuilderProvider =
    Provider<BuildPublicRepairTrackingSnapshot>((ref) {
      return const BuildPublicRepairTrackingSnapshot();
    });

final repairTrackingPublishClientProvider =
    Provider<RepairTrackingPublishClient>((ref) {
      return RepairTrackingPublishClient(
        config: ref.watch(onlineTrackingBackendConfigProvider),
        httpClient: ref.watch(onlineTrackingHttpClientProvider),
      );
    });

final trackingSyncRetryPolicyProvider = Provider<TrackingSyncRetryPolicy>((
  ref,
) {
  return const TrackingSyncRetryPolicy();
});

final trackingSyncProcessorProvider = Provider<TrackingSyncProcessor>((ref) {
  return TrackingSyncProcessor(
    outboxRepository: ref.watch(trackingSyncOutboxRepositoryProvider),
    repairRepository: ref.watch(repairRepositoryProvider),
    shopSettingsRepository: ref.watch(shopSettingsRepositoryProvider),
    credentialStore: ref.watch(installationCredentialStoreProvider),
    snapshotBuilder: ref.watch(publicRepairTrackingSnapshotBuilderProvider),
    publishClient: ref.watch(repairTrackingPublishClientProvider),
    retryPolicy: ref.watch(trackingSyncRetryPolicyProvider),
    diagnosticLog: debugPrint,
  );
});

final trackingSyncCoordinatorProvider = Provider<TrackingSyncCoordinator>((
  ref,
) {
  final coordinator = TrackingSyncCoordinator(
    processor: ref.watch(trackingSyncProcessorProvider),
    diagnosticLog: debugPrint,
  );
  ref.onDispose(coordinator.stop);
  return coordinator;
});
