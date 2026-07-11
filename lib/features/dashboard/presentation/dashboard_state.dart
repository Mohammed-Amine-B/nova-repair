import '../../repairs/domain/entities/repair.dart';
import '../../repairs/domain/entities/repair_attention_counts.dart';

class DashboardState {
  const DashboardState({
    required this.activeRepairCount,
    required this.waitingForApprovalCount,
    required this.waitingForPartCount,
    required this.readyForPickupCount,
    required this.recentRepairs,
    required this.attentionCounts,
  });

  final int activeRepairCount;
  final int waitingForApprovalCount;
  final int waitingForPartCount;
  final int readyForPickupCount;
  final List<Repair> recentRepairs;
  final RepairAttentionCounts attentionCounts;
}
