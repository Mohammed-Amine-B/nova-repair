import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../repairs/domain/repair_status.dart';
import '../../repairs/repair_providers.dart';
import 'dashboard_state.dart';

const dashboardRecentRepairLimit = 5;
const dashboardReadyTooLongThreshold = Duration(days: 5);
const dashboardDelayedActiveThreshold = Duration(days: 14);

final dashboardClockProvider = Provider<DateTime Function()>((ref) {
  return DateTime.now;
});

final dashboardControllerProvider =
    AsyncNotifierProvider<DashboardController, DashboardState>(
      DashboardController.new,
    );

class DashboardController extends AsyncNotifier<DashboardState> {
  @override
  Future<DashboardState> build() {
    return _load();
  }

  Future<void> refreshDashboard() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  Future<DashboardState> _load() async {
    final repository = ref.read(repairRepositoryProvider);
    final now = ref.read(dashboardClockProvider)().toUtc();
    final readyBefore = now.subtract(dashboardReadyTooLongThreshold);
    final delayedBefore = now.subtract(dashboardDelayedActiveThreshold);

    final statusCountsFuture = repository.getStatusCounts();
    final activeCountFuture = repository.getActiveRepairCount();
    final recentRepairsFuture = repository.getRecentRepairs(
      limit: dashboardRecentRepairLimit,
    );
    final attentionCountsFuture = repository.getAttentionCounts(
      readyBefore: readyBefore,
      delayedBefore: delayedBefore,
    );

    final statusCounts = await statusCountsFuture;
    final activeCount = await activeCountFuture;
    final recentRepairs = await recentRepairsFuture;
    final attentionCounts = await attentionCountsFuture;

    return DashboardState(
      activeRepairCount: activeCount,
      waitingForApprovalCount:
          statusCounts[RepairStatus.waitingForCustomerApproval] ?? 0,
      waitingForPartCount: statusCounts[RepairStatus.waitingForPart] ?? 0,
      readyForPickupCount: statusCounts[RepairStatus.readyForPickup] ?? 0,
      recentRepairs: recentRepairs,
      attentionCounts: attentionCounts,
    );
  }
}
