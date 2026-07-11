enum RepairStatus {
  received('received'),
  diagnosing('diagnosing'),
  waitingForCustomerApproval('waiting_for_customer_approval'),
  waitingForPart('waiting_for_part'),
  repairing('repairing'),
  readyForPickup('ready_for_pickup'),
  delivered('delivered'),
  cancelled('cancelled');

  const RepairStatus(this.databaseValue);

  final String databaseValue;

  static RepairStatus fromDatabaseValue(String value) {
    for (final status in RepairStatus.values) {
      if (status.databaseValue == value) {
        return status;
      }
    }

    throw FormatException('Unknown repair status database value: $value');
  }
}
