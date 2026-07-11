class PublicTrackingIdentity {
  factory PublicTrackingIdentity({
    required String trackingToken,
    required String publicShopId,
  }) {
    final normalizedToken = trackingToken.trim();
    final normalizedShopId = publicShopId.trim();

    if (normalizedToken.isEmpty) {
      throw ArgumentError.value(
        trackingToken,
        'trackingToken',
        'Cannot be blank.',
      );
    }
    if (normalizedShopId.isEmpty) {
      throw ArgumentError.value(
        publicShopId,
        'publicShopId',
        'Cannot be blank.',
      );
    }

    return PublicTrackingIdentity._(
      trackingToken: normalizedToken,
      publicShopId: normalizedShopId,
    );
  }

  const PublicTrackingIdentity._({
    required this.trackingToken,
    required this.publicShopId,
  });

  final String trackingToken;
  final String publicShopId;
}
