import '../domain/entities/repair.dart';

enum NewRepairSubmitAction { save, saveAndPrint }

class NewRepairState {
  const NewRepairState({
    this.deviceTypeError,
    this.reportedProblemError,
    this.priceError,
    this.submissionError,
    this.isSubmitting = false,
    this.activeSubmitAction,
    this.createdRepair,
  });

  final String? deviceTypeError;
  final String? reportedProblemError;
  final String? priceError;
  final String? submissionError;
  final bool isSubmitting;
  final NewRepairSubmitAction? activeSubmitAction;
  final Repair? createdRepair;

  bool get hasValidationErrors {
    return deviceTypeError != null ||
        reportedProblemError != null ||
        priceError != null;
  }

  NewRepairState copyWith({
    String? deviceTypeError,
    bool clearDeviceTypeError = false,
    String? reportedProblemError,
    bool clearReportedProblemError = false,
    String? priceError,
    bool clearPriceError = false,
    String? submissionError,
    bool clearSubmissionError = false,
    bool? isSubmitting,
    NewRepairSubmitAction? activeSubmitAction,
    bool clearActiveSubmitAction = false,
    Repair? createdRepair,
    bool clearCreatedRepair = false,
  }) {
    return NewRepairState(
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
      isSubmitting: isSubmitting ?? this.isSubmitting,
      activeSubmitAction: clearActiveSubmitAction
          ? null
          : activeSubmitAction ?? this.activeSubmitAction,
      createdRepair: clearCreatedRepair
          ? null
          : createdRepair ?? this.createdRepair,
    );
  }
}
