import '../errors/repair_status_workflow_exception.dart';
import '../repair_status.dart';

class RepairStatusTransitionPolicy {
  const RepairStatusTransitionPolicy();

  List<RepairStatus> allowedNextStatuses(RepairStatus currentStatus) {
    return [
      for (final status in RepairStatus.values)
        if (status != currentStatus) status,
    ];
  }

  bool canTransition({required RepairStatus from, required RepairStatus to}) {
    return from != to;
  }

  void validate({required RepairStatus from, required RepairStatus to}) {
    if (!canTransition(from: from, to: to)) {
      throw InvalidRepairStatusTransitionException(from: from, to: to);
    }
  }
}
