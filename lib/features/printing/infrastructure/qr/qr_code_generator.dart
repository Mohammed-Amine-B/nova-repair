import 'package:qr/qr.dart';

import 'qr_code_request.dart';
import 'qr_code_svg.dart';

class QrCodeGenerator {
  const QrCodeGenerator();

  static const int quietZoneModules = 4;
  static const int errorCorrectionLevel = QrErrorCorrectLevel.Q;

  QrCodeSvg generateSvg(QrCodeRequest request) {
    final code = QrCode.fromData(
      data: request.payload,
      errorCorrectLevel: errorCorrectionLevel,
    );
    final image = QrImage(code);
    final totalModules = image.moduleCount + quietZoneModules * 2;
    final path = StringBuffer();

    for (var row = 0; row < image.moduleCount; row++) {
      for (var col = 0; col < image.moduleCount; col++) {
        if (image.isDark(row, col)) {
          final x = col + quietZoneModules;
          final y = row + quietZoneModules;
          path.write('M$x ${y}h1v1h-1z');
        }
      }
    }

    final svg =
        '<svg xmlns="http://www.w3.org/2000/svg" '
        'width="${request.size}" height="${request.size}" '
        'viewBox="0 0 $totalModules $totalModules" '
        'shape-rendering="crispEdges">'
        '<rect width="$totalModules" height="$totalModules" fill="#FFFFFF"/>'
        '<path fill="#000000" d="$path"/>'
        '</svg>';

    return QrCodeSvg(payload: request.payload, size: request.size, svg: svg);
  }
}
