class OnlineTrackingBackendConfig {
  const OnlineTrackingBackendConfig({
    this.functionsBaseUrl = const String.fromEnvironment(
      'NOVA_TRACKING_FUNCTIONS_BASE_URL',
      defaultValue: 'https://nkskvskdoetridrujtjv.supabase.co/functions/v1',
    ),
  });

  final String functionsBaseUrl;

  Uri get verifyInstallationUri {
    return Uri.parse(
      '${functionsBaseUrl.replaceFirst(RegExp(r'/$'), '')}/'
      'verify-tracking-installation',
    );
  }

  Uri get publishRepairTrackingUri {
    return Uri.parse(
      '${functionsBaseUrl.replaceFirst(RegExp(r'/$'), '')}/'
      'publish-repair-tracking',
    );
  }
}
