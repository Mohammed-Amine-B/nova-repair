import 'package:flutter/material.dart';

import '../../infrastructure/qr/qr_code_svg.dart';

class QrSvgView extends StatelessWidget {
  const QrSvgView({
    required this.qrCode,
    this.size = 96,
    this.semanticLabel,
    super.key,
  });

  final QrCodeSvg qrCode;
  final double size;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel ?? 'QR code for ${qrCode.payload}',
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(painter: _QrSvgPainter(qrCode.svg)),
      ),
    );
  }
}

class _QrSvgPainter extends CustomPainter {
  _QrSvgPainter(String svg)
    : _modules = _parseModules(svg),
      _moduleCount = _parseModuleCount(svg);

  final List<Offset> _modules;
  final int _moduleCount;

  @override
  void paint(Canvas canvas, Size size) {
    final whitePaint = Paint()..color = Colors.white;
    final blackPaint = Paint()..color = Colors.black;
    canvas.drawRect(Offset.zero & size, whitePaint);

    if (_moduleCount <= 0) {
      return;
    }

    final moduleSize = size.shortestSide / _moduleCount;
    for (final module in _modules) {
      canvas.drawRect(
        Rect.fromLTWH(
          module.dx * moduleSize,
          module.dy * moduleSize,
          moduleSize.ceilToDouble(),
          moduleSize.ceilToDouble(),
        ),
        blackPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _QrSvgPainter oldDelegate) {
    return oldDelegate._moduleCount != _moduleCount ||
        oldDelegate._modules.length != _modules.length;
  }
}

int _parseModuleCount(String svg) {
  final match = RegExp(r'viewBox="0 0 (\d+) \d+"').firstMatch(svg);
  return int.tryParse(match?.group(1) ?? '') ?? 0;
}

List<Offset> _parseModules(String svg) {
  final pathMatch = RegExp(r'<path fill="#000000" d="([^"]*)"').firstMatch(svg);
  final path = pathMatch?.group(1);
  if (path == null || path.isEmpty) {
    return const [];
  }

  return [
    for (final match in RegExp(r'M(\d+) (\d+)h1v1h-1z').allMatches(path))
      Offset(double.parse(match.group(1)!), double.parse(match.group(2)!)),
  ];
}
