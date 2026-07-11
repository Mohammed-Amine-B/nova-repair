import '../../application/local_printer_service.dart';
import '../../application/print_printer_target.dart';
import '../../application/rendered_print_document.dart';
import '../../domain/entities/local_printer.dart';
import '../../domain/entities/print_result.dart';
import 'printing_platform_client.dart';

class PrintingLocalPrinterService implements LocalPrinterService {
  const PrintingLocalPrinterService(this._client);

  final PrintingPlatformClient _client;

  @override
  Future<List<LocalPrinter>> listPrinters() async {
    final printers = await _client.listPrinters();
    return [
      for (final printer in printers)
        LocalPrinter(
          id: printer.id,
          displayName: printer.displayName,
          isDefault: printer.isDefault,
          isAvailable: printer.isAvailable,
        ),
    ];
  }

  @override
  Future<LocalPrinter?> getDefaultPrinter() async {
    final printers = await listPrinters();
    for (final printer in printers) {
      if (printer.isDefault && printer.isAvailable) {
        return printer;
      }
    }

    for (final printer in printers) {
      if (printer.isAvailable) {
        return printer;
      }
    }

    return null;
  }

  @override
  Future<PrintResult> printDocument({
    required PrintPrinterTarget printerTarget,
    required RenderedPrintDocument document,
    required int copies,
  }) async {
    return switch (printerTarget) {
      SystemDefaultPrintPrinterTarget() => _printToSystemDefault(
        copies: copies,
        document: document,
      ),
      SpecificPrintPrinterTarget(:final id) => _printToSpecificPrinter(
        printerId: id,
        copies: copies,
        document: document,
      ),
    };
  }

  Future<PrintResult> _printToSystemDefault({
    required int copies,
    required RenderedPrintDocument document,
  }) async {
    final snapshots = await _client.listPrinters();
    final printer = _resolveDefaultSnapshot(snapshots);
    if (printer == null) {
      return PrintResult.failed(
        failureKind: PrintFailureKind.noPrinterAvailable,
        message: 'No printer is available.',
      );
    }

    return _submitCopies(printer: printer, document: document, copies: copies);
  }

  Future<PrintResult> _printToSpecificPrinter({
    required String printerId,
    required int copies,
    required RenderedPrintDocument document,
  }) async {
    final snapshots = await _client.listPrinters();
    final printer = _resolvePrinterIdSnapshot(snapshots, printerId);
    if (printer == null) {
      return PrintResult.failed(
        failureKind: PrintFailureKind.printerTargetUnavailable,
        message: 'The selected printer is unavailable.',
      );
    }

    return _submitCopies(printer: printer, document: document, copies: copies);
  }

  Future<PrintResult> _submitCopies({
    required PrintingPrinterSnapshot printer,
    required RenderedPrintDocument document,
    required int copies,
  }) async {
    try {
      for (var copy = 0; copy < copies; copy++) {
        final submitted = await _client.directPrintPdf(
          printer: printer,
          bytes: document.bytes,
          pageFormat: document.pageFormat,
          jobName: document.jobName,
        );
        if (!submitted) {
          return PrintResult.cancelled();
        }
      }

      return PrintResult.success();
    } catch (_) {
      return PrintResult.failed(
        failureKind: PrintFailureKind.printSubmissionFailed,
        message: 'The print job could not be sent.',
      );
    }
  }
}

PrintingPrinterSnapshot? _resolveDefaultSnapshot(
  List<PrintingPrinterSnapshot> printers,
) {
  for (final printer in printers) {
    if (printer.isDefault && printer.isAvailable) {
      return printer;
    }
  }

  for (final printer in printers) {
    if (printer.isAvailable) {
      return printer;
    }
  }

  return null;
}

PrintingPrinterSnapshot? _resolvePrinterIdSnapshot(
  List<PrintingPrinterSnapshot> printers,
  String printerId,
) {
  for (final printer in printers) {
    if (printer.id == printerId && printer.isAvailable) {
      return printer;
    }
  }

  return null;
}
