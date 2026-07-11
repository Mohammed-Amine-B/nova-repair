import '../errors/repair_update_workflow_exception.dart';

class UpdateRepairInput {
  UpdateRepairInput({
    required this.repairId,
    this.customerName,
    this.customerPhone,
    required this.deviceType,
    this.brand,
    this.model,
    required this.reportedProblem,
    this.receivedAccessories,
    this.deviceAccessInfo,
    this.internalNotes,
    this.customerMessage,
  }) {
    if (deviceType.trim().isEmpty) {
      throw const InvalidRepairUpdateInputException(
        fieldName: 'deviceType',
        message: 'Device type is required.',
      );
    }
    if (reportedProblem.trim().isEmpty) {
      throw const InvalidRepairUpdateInputException(
        fieldName: 'reportedProblem',
        message: 'Reported problem is required.',
      );
    }
  }

  final int repairId;
  final String? customerName;
  final String? customerPhone;
  final String deviceType;
  final String? brand;
  final String? model;
  final String reportedProblem;
  final String? receivedAccessories;
  final String? deviceAccessInfo;
  final String? internalNotes;
  final String? customerMessage;

  String get normalizedDeviceType => deviceType.trim();

  String get normalizedReportedProblem => reportedProblem.trim();

  String? normalizedText(String? value) {
    if (value == null) {
      return null;
    }

    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
