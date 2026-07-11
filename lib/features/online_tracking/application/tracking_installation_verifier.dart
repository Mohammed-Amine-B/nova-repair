import 'package:http/http.dart' as http;

import 'online_tracking_backend_config.dart';

class TrackingInstallationVerifier {
  const TrackingInstallationVerifier({
    required OnlineTrackingBackendConfig config,
    required http.Client httpClient,
  }) : _config = config,
       _httpClient = httpClient;

  final OnlineTrackingBackendConfig _config;
  final http.Client _httpClient;

  Future<TrackingInstallationVerificationResult> verify({
    required String publicShopId,
    required String installationSecret,
  }) async {
    final response = await _httpClient.post(
      _config.verifyInstallationUri,
      headers: {
        'Content-Type': 'application/json',
        'X-Nova-Shop-Id': publicShopId,
        'X-Nova-Installation-Secret': installationSecret,
      },
      body: '{}',
    );

    if (response.statusCode == 200) {
      return TrackingInstallationVerificationResult.valid;
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      return TrackingInstallationVerificationResult.invalidCredentials;
    }

    return TrackingInstallationVerificationResult.unavailable;
  }
}

enum TrackingInstallationVerificationResult {
  valid,
  invalidCredentials,
  unavailable,
}
