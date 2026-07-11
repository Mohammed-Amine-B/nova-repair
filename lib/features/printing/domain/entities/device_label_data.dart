class DeviceLabelData {
  const DeviceLabelData({
    required this.repairCode,
    required this.receivedAt,
    required this.deviceDisplayName,
    required this.customerName,
    required this.customerPhone,
    required this.reportedProblem,
  });

  final String repairCode;
  final DateTime receivedAt;
  final String deviceDisplayName;
  final String? customerName;
  final String? customerPhone;
  final String reportedProblem;
}
