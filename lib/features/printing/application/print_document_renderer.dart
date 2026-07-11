import '../domain/entities/repair_print_data.dart';
import '../infrastructure/qr/qr_code_svg.dart';
import '../presentation/print_document_mode.dart';
import 'rendered_print_document.dart';

abstract class PrintDocumentRenderer {
  Future<RenderedPrintDocument> render({
    required RepairPrintData printData,
    required QrCodeSvg qrCode,
    required PrintDocumentMode documentMode,
  });
}
