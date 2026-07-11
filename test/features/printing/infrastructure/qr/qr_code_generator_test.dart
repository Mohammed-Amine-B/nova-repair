import 'package:flutter_test/flutter_test.dart';
import 'package:nova_repair/features/printing/infrastructure/qr/qr_code_generator.dart';
import 'package:nova_repair/features/printing/infrastructure/qr/qr_code_request.dart';

void main() {
  const generator = QrCodeGenerator();

  test('normal payload succeeds and produces SVG output', () {
    final result = generator.generateSvg(
      QrCodeRequest(payload: 'REP-0042', size: 256),
    );

    expect(result.payload, 'REP-0042');
    expect(result.size, 256);
    expect(result.svg, isNotEmpty);
    expect(result.svg, startsWith('<svg '));
    expect(result.svg, contains('xmlns="http://www.w3.org/2000/svg"'));
    expect(result.svg, contains('width="256"'));
    expect(result.svg, contains('height="256"'));
    expect(result.svg, contains('viewBox="0 0 '));
    expect(result.svg, contains('<rect '));
    expect(result.svg, contains('<path fill="#000000" d="M'));
    expect(result.svg, endsWith('</svg>'));
  });

  test(
    'payload trims surrounding whitespace and preserves internal whitespace',
    () {
      final trimmed = generator.generateSvg(
        QrCodeRequest(payload: 'REP-0042  DEMO', size: 256),
      );
      final surrounded = generator.generateSvg(
        QrCodeRequest(payload: ' \n\tREP-0042  DEMO\t\n ', size: 256),
      );
      final internalChanged = generator.generateSvg(
        QrCodeRequest(payload: 'REP-0042 DEMO', size: 256),
      );

      expect(surrounded.payload, 'REP-0042  DEMO');
      expect(surrounded.svg, trimmed.svg);
      expect(internalChanged.svg, isNot(trimmed.svg));
    },
  );

  test('blank and whitespace-only payloads are rejected', () {
    expect(() => QrCodeRequest(payload: '', size: 256), throwsArgumentError);
    expect(
      () => QrCodeRequest(payload: '   \n\t  ', size: 256),
      throwsArgumentError,
    );
  });

  test('size must be positive', () {
    expect(
      () => QrCodeRequest(payload: 'REP-0042', size: 0),
      throwsArgumentError,
    );
    expect(
      () => QrCodeRequest(payload: 'REP-0042', size: -1),
      throwsArgumentError,
    );
  });

  test('same payload and size produce deterministic output', () {
    final first = generator.generateSvg(
      QrCodeRequest(payload: 'REP-0042', size: 256),
    );
    final second = generator.generateSvg(
      QrCodeRequest(payload: 'REP-0042', size: 256),
    );

    expect(second.svg, first.svg);
  });

  test('different payloads produce different output', () {
    final first = generator.generateSvg(
      QrCodeRequest(payload: 'REP-0042', size: 256),
    );
    final second = generator.generateSvg(
      QrCodeRequest(payload: 'REP-0043', size: 256),
    );

    expect(second.svg, isNot(first.svg));
  });

  test('different sizes preserve data but change rendered dimensions', () {
    final small = generator.generateSvg(
      QrCodeRequest(payload: 'REP-0042', size: 128),
    );
    final large = generator.generateSvg(
      QrCodeRequest(payload: 'REP-0042', size: 256),
    );

    expect(small.payload, large.payload);
    expect(small.svg, contains('width="128"'));
    expect(small.svg, contains('height="128"'));
    expect(large.svg, contains('width="256"'));
    expect(large.svg, contains('height="256"'));
    expect(
      _pathData(small.svg),
      _pathData(large.svg),
      reason:
          'Only SVG rendered dimensions should change for the same payload.',
    );
  });

  test('unicode payloads are supported', () {
    final result = generator.generateSvg(
      QrCodeRequest(
        payload: 'تصليح هاتف - écran cassé - 1234 - #+/%',
        size: 256,
      ),
    );

    expect(result.payload, 'تصليح هاتف - écran cassé - 1234 - #+/%');
    expect(result.svg, startsWith('<svg '));
    expect(result.svg, contains('<path fill="#000000" d="M'));
  });

  test('url-like payload succeeds without creating a tracking contract', () {
    final result = generator.generateSvg(
      QrCodeRequest(
        payload: 'https://example.test/track/demo-token',
        size: 256,
      ),
    );

    expect(result.payload, 'https://example.test/track/demo-token');
    expect(result.svg, contains('<path fill="#000000" d="M'));
  });

  test('reasonably long payload succeeds', () {
    final payload = List.filled(
      20,
      'Repair ticket offline QR payload demo',
    ).join(' | ');

    final result = generator.generateSvg(
      QrCodeRequest(payload: payload, size: 384),
    );

    expect(result.payload, payload);
    expect(result.svg, contains('width="384"'));
    expect(result.svg, contains('<path fill="#000000" d="M'));
  });

  test('quiet zone and error correction defaults are stable', () {
    expect(QrCodeGenerator.quietZoneModules, 4);
    expect(QrCodeGenerator.errorCorrectionLevel, 3);
  });
}

String _pathData(String svg) {
  final match = RegExp(r'<path fill="#000000" d="([^"]+)"').firstMatch(svg);
  return match?.group(1) ?? '';
}
