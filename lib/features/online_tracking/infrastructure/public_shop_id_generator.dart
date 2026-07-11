import 'tracking_token_generator.dart';

class PublicShopIdGenerator {
  PublicShopIdGenerator({TrackingTokenGenerator? tokenGenerator})
    : _tokenGenerator = tokenGenerator ?? TrackingTokenGenerator();

  final TrackingTokenGenerator _tokenGenerator;

  String generate() {
    return 'shop_${_tokenGenerator.generate(byteLength: 24)}';
  }
}
