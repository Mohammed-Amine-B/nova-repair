import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

class TrackingTokenGenerator {
  TrackingTokenGenerator({Random? random})
    : _random = random ?? Random.secure();

  final Random _random;

  String generate({int byteLength = 32}) {
    if (byteLength < 16) {
      throw ArgumentError.value(
        byteLength,
        'byteLength',
        'Must provide at least 128 bits of entropy.',
      );
    }

    final bytes = Uint8List(byteLength);
    for (var index = 0; index < bytes.length; index += 1) {
      bytes[index] = _random.nextInt(256);
    }

    return base64UrlEncode(bytes).replaceAll('=', '');
  }
}
