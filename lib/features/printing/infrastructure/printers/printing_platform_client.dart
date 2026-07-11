import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

class PrintingPrinterSnapshot {
  const PrintingPrinterSnapshot({
    required this.id,
    required this.displayName,
    required this.isDefault,
    required this.isAvailable,
  });

  final String id;
  final String displayName;
  final bool isDefault;
  final bool isAvailable;
}

abstract class PrintingPlatformClient {
  Future<List<PrintingPrinterSnapshot>> listPrinters();

  Future<bool> directPrintPdf({
    required PrintingPrinterSnapshot printer,
    required Uint8List bytes,
    required PdfPageFormat pageFormat,
    required String jobName,
  });
}

class PrintingPackagePlatformClient implements PrintingPlatformClient {
  const PrintingPackagePlatformClient();

  @override
  Future<List<PrintingPrinterSnapshot>> listPrinters() async {
    final printers = await Printing.listPrinters();
    return [
      for (final printer in printers)
        PrintingPrinterSnapshot(
          id: printer.url,
          displayName: printer.name,
          isDefault: printer.isDefault,
          isAvailable: printer.isAvailable,
        ),
    ];
  }

  @override
  Future<bool> directPrintPdf({
    required PrintingPrinterSnapshot printer,
    required Uint8List bytes,
    required PdfPageFormat pageFormat,
    required String jobName,
  }) {
    return Future.value(
      Printing.directPrintPdf(
        printer: Printer(
          url: printer.id,
          name: printer.displayName,
          isDefault: printer.isDefault,
          isAvailable: printer.isAvailable,
        ),
        name: jobName,
        format: pageFormat,
        usePrinterSettings: true,
        onLayout: (_) => bytes,
      ),
    );
  }
}
