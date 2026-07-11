import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../database/database_provider.dart';
import 'application/installation_credential_store.dart';
import 'application/online_tracking_backend_config.dart';
import 'application/online_tracking_web_config.dart';
import 'application/tracking_installation_verifier.dart';
import 'data/datasources/tracking_sync_outbox_local_data_source.dart';
import 'data/repositories/drift_tracking_sync_outbox_repository.dart';
import 'domain/repositories/tracking_sync_outbox_repository.dart';
import 'infrastructure/public_shop_id_generator.dart';
import 'infrastructure/secure_installation_credential_store.dart';
import 'infrastructure/tracking_token_generator.dart';

final trackingTokenGeneratorProvider = Provider<TrackingTokenGenerator>((ref) {
  return TrackingTokenGenerator();
});

final publicShopIdGeneratorProvider = Provider<PublicShopIdGenerator>((ref) {
  return PublicShopIdGenerator(
    tokenGenerator: ref.watch(trackingTokenGeneratorProvider),
  );
});

final onlineTrackingBackendConfigProvider =
    Provider<OnlineTrackingBackendConfig>((ref) {
      return const OnlineTrackingBackendConfig();
    });

final onlineTrackingWebConfigProvider = Provider<OnlineTrackingWebConfig>((
  ref,
) {
  return const OnlineTrackingWebConfig();
});

final onlineTrackingHttpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

final installationCredentialStoreProvider =
    Provider<InstallationCredentialStore>((ref) {
      return const SecureInstallationCredentialStore();
    });

final installationCredentialExistsProvider = FutureProvider.autoDispose<bool>((
  ref,
) {
  return ref.watch(installationCredentialStoreProvider).hasInstallationSecret();
});

final trackingInstallationVerifierProvider =
    Provider<TrackingInstallationVerifier>((ref) {
      return TrackingInstallationVerifier(
        config: ref.watch(onlineTrackingBackendConfigProvider),
        httpClient: ref.watch(onlineTrackingHttpClientProvider),
      );
    });

final trackingSyncOutboxLocalDataSourceProvider =
    Provider<TrackingSyncOutboxLocalDataSource>((ref) {
      return TrackingSyncOutboxLocalDataSource(ref.watch(appDatabaseProvider));
    });

final trackingSyncOutboxRepositoryProvider =
    Provider<TrackingSyncOutboxRepository>((ref) {
      return DriftTrackingSyncOutboxRepository(
        ref.watch(trackingSyncOutboxLocalDataSourceProvider),
      );
    });
