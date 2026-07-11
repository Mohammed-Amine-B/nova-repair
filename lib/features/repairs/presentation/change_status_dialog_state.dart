import '../domain/entities/repair.dart';
import '../domain/repair_status.dart';

class ChangeStatusDialogState {
  const ChangeStatusDialogState({
    required this.repair,
    this.selectedStatus,
    this.customerMessageText = '',
    this.customerMessageChanged = false,
    this.isSubmitting = false,
    this.submissionError,
  });

  final Repair repair;
  final RepairStatus? selectedStatus;
  final String customerMessageText;
  final bool customerMessageChanged;
  final bool isSubmitting;
  final String? submissionError;

  bool get canSubmit {
    return selectedStatus != null && !isSubmitting;
  }

  ChangeStatusDialogState copyWith({
    RepairStatus? selectedStatus,
    bool clearSelectedStatus = false,
    String? customerMessageText,
    bool? customerMessageChanged,
    bool? isSubmitting,
    String? submissionError,
    bool clearSubmissionError = false,
  }) {
    return ChangeStatusDialogState(
      repair: repair,
      selectedStatus: clearSelectedStatus
          ? null
          : selectedStatus ?? this.selectedStatus,
      customerMessageText: customerMessageText ?? this.customerMessageText,
      customerMessageChanged:
          customerMessageChanged ?? this.customerMessageChanged,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submissionError: clearSubmissionError
          ? null
          : submissionError ?? this.submissionError,
    );
  }
}
