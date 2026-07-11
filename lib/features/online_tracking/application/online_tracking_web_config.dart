class OnlineTrackingWebConfig {
  const OnlineTrackingWebConfig({
    this.trackingWebBaseUrl = const String.fromEnvironment(
      'NOVA_TRACKING_WEB_BASE_URL',
    ),
  });

  final String trackingWebBaseUrl;
}
