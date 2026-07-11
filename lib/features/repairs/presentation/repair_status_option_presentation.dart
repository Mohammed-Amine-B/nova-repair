import '../domain/repair_status.dart';

class RepairStatusOptionPresentation {
  const RepairStatusOptionPresentation({
    required this.status,
    required this.description,
  });

  final RepairStatus status;
  final String description;
}

const repairStatusOptionPresentations = [
  RepairStatusOptionPresentation(
    status: RepairStatus.received,
    description: 'Device has been received by the repair shop',
  ),
  RepairStatusOptionPresentation(
    status: RepairStatus.diagnosing,
    description: 'Device is being inspected and diagnosed',
  ),
  RepairStatusOptionPresentation(
    status: RepairStatus.waitingForCustomerApproval,
    description: 'Waiting for the customer to approve the proposed price',
  ),
  RepairStatusOptionPresentation(
    status: RepairStatus.waitingForPart,
    description: 'Repair is paused while waiting for a required part',
  ),
  RepairStatusOptionPresentation(
    status: RepairStatus.repairing,
    description: 'Repair work is currently in progress',
  ),
  RepairStatusOptionPresentation(
    status: RepairStatus.readyForPickup,
    description: 'Repair is complete and the device is ready for collection',
  ),
  RepairStatusOptionPresentation(
    status: RepairStatus.delivered,
    description: 'Device has been returned to the customer',
  ),
  RepairStatusOptionPresentation(
    status: RepairStatus.cancelled,
    description: 'Repair job has been cancelled',
  ),
];
