sealed class RepairUpdateWorkflowException implements Exception {
  const RepairUpdateWorkflowException(this.message);

  final String message;

  @override
  String toString() => message;
}

class InvalidRepairUpdateInputException extends RepairUpdateWorkflowException {
  const InvalidRepairUpdateInputException({
    required this.fieldName,
    required String message,
  }) : super(message);

  final String fieldName;
}
