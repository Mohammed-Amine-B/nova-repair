import '../repair_status.dart';

sealed class WarrantyReturnWorkflowException implements Exception {
  const WarrantyReturnWorkflowException(this.message);

  final String message;

  @override
  String toString() => message;
}

class WarrantyParentRepairNotFoundException
    extends WarrantyReturnWorkflowException {
  const WarrantyParentRepairNotFoundException(this.repairId)
    : super('Warranty parent repair with ID $repairId was not found.');

  final int repairId;
}

class RepairNotEligibleForWarrantyReturnException
    extends WarrantyReturnWorkflowException {
  RepairNotEligibleForWarrantyReturnException({
    required this.repairId,
    required this.status,
  }) : super(
         'Repair with ID $repairId cannot be used as a warranty parent '
         'while status is ${status.name}.',
       );

  final int repairId;
  final RepairStatus status;
}

class WarrantyReturnFromWarrantyReturnNotAllowedException
    extends WarrantyReturnWorkflowException {
  const WarrantyReturnFromWarrantyReturnNotAllowedException(this.repairId)
    : super(
        'Repair with ID $repairId is already a warranty return and cannot be '
        'used as a warranty parent.',
      );

  final int repairId;
}
