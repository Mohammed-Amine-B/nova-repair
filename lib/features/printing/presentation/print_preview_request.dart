import 'print_document_mode.dart';

class PrintPreviewRequest {
  const PrintPreviewRequest({
    required this.repairId,
    required this.documentMode,
    required this.copies,
  });

  final int repairId;
  final PrintDocumentMode documentMode;
  final int copies;
}
