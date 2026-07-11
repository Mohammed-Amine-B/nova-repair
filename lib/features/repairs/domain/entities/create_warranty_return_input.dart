class CreateWarrantyReturnInput {
  CreateWarrantyReturnInput({
    required this.originalRepairId,
    required this.reportedProblem,
    this.receivedAccessories,
    this.deviceAccessInfo,
    this.internalNotes,
    this.customerMessage,
    this.receivedAt,
  }) {
    if (reportedProblem.trim().isEmpty) {
      throw ArgumentError.value(
        reportedProblem,
        'reportedProblem',
        'Cannot be blank.',
      );
    }
  }

  final int originalRepairId;
  final String reportedProblem;
  final String? receivedAccessories;
  final String? deviceAccessInfo;
  final String? internalNotes;
  final String? customerMessage;
  final DateTime? receivedAt;

  String get normalizedReportedProblem => reportedProblem.trim();

  String? normalizedText(String? value) {
    if (value == null) {
      return null;
    }

    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
