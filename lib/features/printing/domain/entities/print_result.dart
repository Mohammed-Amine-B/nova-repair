enum PrintResultStatus { success, cancelled, failed }

enum PrintFailureKind {
  invalidRequest,
  noPrinterAvailable,
  printerTargetUnavailable,
  documentRenderingFailed,
  printSubmissionFailed,
}

class PrintResult {
  const PrintResult._({
    required this.status,
    required this.message,
    this.failureKind,
  });

  factory PrintResult.success({String? message}) {
    return PrintResult._(
      status: PrintResultStatus.success,
      message: message ?? 'Print job sent successfully.',
    );
  }

  factory PrintResult.cancelled({String? message}) {
    return PrintResult._(
      status: PrintResultStatus.cancelled,
      message: message ?? 'Print was cancelled.',
    );
  }

  factory PrintResult.failed({
    required PrintFailureKind failureKind,
    required String message,
  }) {
    return PrintResult._(
      status: PrintResultStatus.failed,
      failureKind: failureKind,
      message: message,
    );
  }

  final PrintResultStatus status;
  final PrintFailureKind? failureKind;
  final String message;

  bool get isSuccess => status == PrintResultStatus.success;
}
