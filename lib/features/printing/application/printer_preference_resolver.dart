import '../../settings/domain/entities/shop_settings.dart';
import '../presentation/print_document_mode.dart';
import 'print_printer_target.dart';

class PrinterPreferenceResolver {
  const PrinterPreferenceResolver();

  PrintPrinterTarget resolve({
    required PrintDocumentMode documentMode,
    required ShopSettings settings,
  }) {
    final printerId = switch (documentMode) {
      PrintDocumentMode.customerTicket =>
        settings.defaultCustomerTicketPrinterId,
      PrintDocumentMode.deviceLabel => settings.defaultDeviceLabelPrinterId,
    };

    if (printerId == null) {
      return const PrintPrinterTarget.systemDefault();
    }

    return PrintPrinterTarget.printerId(printerId);
  }
}
