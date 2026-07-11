import 'dart:typed_data';

import 'package:pdf/pdf.dart';

class RenderedPrintDocument {
  const RenderedPrintDocument({
    required this.bytes,
    required this.pageFormat,
    required this.jobName,
  });

  final Uint8List bytes;
  final PdfPageFormat pageFormat;
  final String jobName;
}
