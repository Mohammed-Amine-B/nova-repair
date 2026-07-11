class RepairAttentionCounts {
  const RepairAttentionCounts({
    required this.waitingForCustomerApproval,
    required this.readyTooLong,
    required this.delayedActive,
  });

  final int waitingForCustomerApproval;
  final int readyTooLong;
  final int delayedActive;
}
