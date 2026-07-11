import '../domain/entities/local_printer.dart';
import '../domain/entities/print_result.dart';
import 'print_printer_target.dart';
import 'rendered_print_document.dart';

abstract class LocalPrinterService {
  Future<List<LocalPrinter>> listPrinters();

  Future<LocalPrinter?> getDefaultPrinter();

  Future<PrintResult> printDocument({
    required PrintPrinterTarget printerTarget,
    required RenderedPrintDocument document,
    required int copies,
  });
}
