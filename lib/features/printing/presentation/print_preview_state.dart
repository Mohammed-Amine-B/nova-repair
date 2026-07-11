import 'print_document_mode.dart';

class PrintPreviewState {
  const PrintPreviewState({
    this.documentMode = PrintDocumentMode.customerTicket,
    this.copies = 1,
    this.isSubmitting = false,
    this.successMessage,
    this.errorMessage,
  });

  static const minCopies = 1;
  static const maxCopies = 99;

  final PrintDocumentMode documentMode;
  final int copies;
  final bool isSubmitting;
  final String? successMessage;
  final String? errorMessage;

  PrintPreviewState copyWith({
    PrintDocumentMode? documentMode,
    int? copies,
    bool? isSubmitting,
    String? successMessage,
    String? errorMessage,
    bool clearFeedback = false,
  }) {
    return PrintPreviewState(
      documentMode: documentMode ?? this.documentMode,
      copies: copies ?? this.copies,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      successMessage: clearFeedback
          ? null
          : successMessage ?? this.successMessage,
      errorMessage: clearFeedback ? null : errorMessage ?? this.errorMessage,
    );
  }
}
