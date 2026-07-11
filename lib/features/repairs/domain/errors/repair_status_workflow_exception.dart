import '../repair_status.dart';

sealed class RepairStatusWorkflowException implements Exception {
  const RepairStatusWorkflowException(this.message);

  final String message;

  @override
  String toString() => message;
}

class RepairNotFoundException extends RepairStatusWorkflowException {
  const RepairNotFoundException(this.repairId)
    : super('Repair with ID $repairId was not found.');

  final int repairId;
}

class InvalidRepairStatusTransitionException
    extends RepairStatusWorkflowException {
  InvalidRepairStatusTransitionException({required this.from, required this.to})
    : super('Cannot change repair status from ${from.name} to ${to.name}.');

  final RepairStatus from;
  final RepairStatus to;
}
