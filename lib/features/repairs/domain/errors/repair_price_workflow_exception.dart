import '../customer_price_decision.dart';
import '../repair_status.dart';

sealed class RepairPriceWorkflowException implements Exception {
  const RepairPriceWorkflowException(this.message);

  final String message;

  @override
  String toString() => message;
}

class InvalidRepairPriceWorkflowStateException
    extends RepairPriceWorkflowException {
  InvalidRepairPriceWorkflowStateException({
    required this.status,
    required this.operation,
  }) : super('Cannot $operation while repair status is ${status.name}.');

  final RepairStatus status;
  final String operation;
}

class InvalidCustomerPriceDecisionTransitionException
    extends RepairPriceWorkflowException {
  InvalidCustomerPriceDecisionTransitionException({
    required this.currentDecision,
    required this.targetDecision,
  }) : super(
         'Cannot record customer price decision from '
         '${currentDecision.name} to ${targetDecision.name}.',
       );

  final CustomerPriceDecision currentDecision;
  final CustomerPriceDecision targetDecision;
}

class RepairPriceProposalNotPresentException
    extends RepairPriceWorkflowException {
  const RepairPriceProposalNotPresentException(this.repairId)
    : super('Repair with ID $repairId has no proposed price.');

  final int repairId;
}

class RepairPriceProposalAlreadyPendingException
    extends RepairPriceWorkflowException {
  const RepairPriceProposalAlreadyPendingException(this.repairId)
    : super(
        'Repair with ID $repairId already has the same pending price proposal.',
      );

  final int repairId;
}
