import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../domain/public_repair_tracking_snapshot.dart';
import 'online_tracking_backend_config.dart';

class RepairTrackingPublishClient {
  const RepairTrackingPublishClient({
    required OnlineTrackingBackendConfig config,
    required http.Client httpClient,
    Duration timeout = const Duration(seconds: 15),
  }) : _config = config,
       _httpClient = httpClient,
       _timeout = timeout;

  final OnlineTrackingBackendConfig _config;
  final http.Client _httpClient;
  final Duration _timeout;

  Future<RepairTrackingPublishResult> publish({
    required String installationSecret,
    required PublicRepairTrackingSnapshot snapshot,
  }) async {
    try {
      final response = await _httpClient
          .post(
            _config.publishRepairTrackingUri,
            headers: {
              'Content-Type': 'application/json',
              'X-Nova-Shop-Id': snapshot.publicShopId,
              'X-Nova-Installation-Secret': installationSecret,
            },
            body: jsonEncode(snapshot.toJson()),
          )
          .timeout(_timeout);

      return _classifyResponse(response);
    } on TimeoutException {
      return const RepairTrackingPublishResult.failure(
        RepairTrackingPublishFailure.timeout,
      );
    } on SocketException {
      return const RepairTrackingPublishResult.failure(
        RepairTrackingPublishFailure.networkError,
      );
    } on http.ClientException {
      return const RepairTrackingPublishResult.failure(
        RepairTrackingPublishFailure.networkError,
      );
    }
  }

  RepairTrackingPublishResult _classifyResponse(http.Response response) {
    if (response.statusCode == 200) {
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is! Map<String, Object?> || decoded['ok'] != true) {
          return const RepairTrackingPublishResult.failure(
            RepairTrackingPublishFailure.unexpectedResponse,
          );
        }

        final result = decoded['result'];
        if (result == 'published' ||
            result == 'already_current' ||
            result == 'ignored_stale') {
          return RepairTrackingPublishResult.success(result as String);
        }
      } catch (_) {
        return const RepairTrackingPublishResult.failure(
          RepairTrackingPublishFailure.unexpectedResponse,
        );
      }

      return const RepairTrackingPublishResult.failure(
        RepairTrackingPublishFailure.unexpectedResponse,
      );
    }

    return switch (response.statusCode) {
      400 || 422 => const RepairTrackingPublishResult.failure(
        RepairTrackingPublishFailure.invalidPayload,
      ),
      401 || 403 => const RepairTrackingPublishResult.failure(
        RepairTrackingPublishFailure.authenticationFailed,
      ),
      409 => const RepairTrackingPublishResult.failure(
        RepairTrackingPublishFailure.ownershipConflict,
      ),
      429 => const RepairTrackingPublishResult.failure(
        RepairTrackingPublishFailure.rateLimited,
      ),
      >= 500 && <= 599 => const RepairTrackingPublishResult.failure(
        RepairTrackingPublishFailure.serverError,
      ),
      _ => const RepairTrackingPublishResult.failure(
        RepairTrackingPublishFailure.unexpectedResponse,
      ),
    };
  }
}

class RepairTrackingPublishResult {
  const RepairTrackingPublishResult.success(String result)
    : isSuccess = true,
      successResult = result,
      failure = null;

  const RepairTrackingPublishResult.failure(this.failure)
    : isSuccess = false,
      successResult = null,
      assert(failure != null);

  final bool isSuccess;
  final String? successResult;
  final RepairTrackingPublishFailure? failure;
}

enum RepairTrackingPublishFailure {
  networkError,
  timeout,
  rateLimited,
  serverError,
  authenticationFailed,
  invalidPayload,
  ownershipConflict,
  unexpectedResponse,
}
