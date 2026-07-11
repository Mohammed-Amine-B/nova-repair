import 'online_tracking_web_config.dart';

class BuildPublicTrackingUrl {
  const BuildPublicTrackingUrl({this.config = const OnlineTrackingWebConfig()});

  final OnlineTrackingWebConfig config;

  String? call(String? trackingToken) {
    final baseUrl = config.trackingWebBaseUrl.trim();
    final token = trackingToken?.trim();

    if (baseUrl.isEmpty || token == null || token.isEmpty) {
      return null;
    }

    final normalizedBaseUrl = baseUrl.replaceFirst(RegExp(r'/+$'), '');
    final parsedBaseUrl = Uri.tryParse(normalizedBaseUrl);
    if (parsedBaseUrl == null ||
        !parsedBaseUrl.hasScheme ||
        parsedBaseUrl.host.isEmpty) {
      return null;
    }

    return '$normalizedBaseUrl/track/${Uri.encodeComponent(token)}';
  }
}
