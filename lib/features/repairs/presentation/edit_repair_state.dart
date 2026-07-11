import '../domain/entities/repair.dart';

class EditRepairState {
  const EditRepairState({
    this.deviceTypeError,
    this.reportedProblemError,
    this.priceError,
    this.submissionError,
    this.partialFailureMessage,
    this.latestRepairAfterPartialFailure,
    this.isSubmitting = false,
  });

  final String? deviceTypeError;
  final String? reportedProblemError;
  final String? priceError;
  final String? submissionError;
  final String? partialFailureMessage;
  final Repair? latestRepairAfterPartialFailure;
  final bool isSubmitting;

  EditRepairState copyWith({
    String? deviceTypeError,
    bool clearDeviceTypeError = false,
    String? reportedProblemError,
    bool clearReportedProblemError = false,
    String? priceError,
    bool clearPriceError = false,
    String? submissionError,
    bool clearSubmissionError = false,
    String? partialFailureMessage,
    bool clearPartialFailure = false,
    Repair? latestRepairAfterPartialFailure,
    bool clearLatestRepairAfterPartialFailure = false,
    bool? isSubmitting,
  }) {
    return EditRepairState(
      deviceTypeError: clearDeviceTypeError
          ? null
          : deviceTypeError ?? this.deviceTypeError,
      reportedProblemError: clearReportedProblemError
          ? null
          : reportedProblemError ?? this.reportedProblemError,
      priceError: clearPriceError ? null : priceError ?? this.priceError,
      submissionError: clearSubmissionError
          ? null
          : submissionError ?? this.submissionError,
      partialFailureMessage: clearPartialFailure
          ? null
          : partialFailureMessage ?? this.partialFailureMessage,
      latestRepairAfterPartialFailure: clearLatestRepairAfterPartialFailure
          ? null
          : latestRepairAfterPartialFailure ??
                this.latestRepairAfterPartialFailure,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}
