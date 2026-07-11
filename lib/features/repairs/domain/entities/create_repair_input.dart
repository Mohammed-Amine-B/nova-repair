class CreateRepairInput {
  CreateRepairInput({
    this.customerName,
    this.customerPhone,
    this.deviceType,
    this.brand,
    this.model,
    required this.reportedProblem,
    this.receivedAccessories,
    this.deviceAccessInfo,
    this.priceAmount,
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
    if (priceAmount != null && priceAmount! < 0) {
      throw ArgumentError.value(
        priceAmount,
        'priceAmount',
        'Cannot be negative.',
      );
    }
  }

  final String? customerName;
  final String? customerPhone;
  final String? deviceType;
  final String? brand;
  final String? model;
  final String reportedProblem;
  final String? receivedAccessories;
  final String? deviceAccessInfo;
  final int? priceAmount;
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
