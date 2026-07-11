import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/repair.dart';
import '../domain/repair_status.dart';
import '../repair_providers.dart';
import 'repair_details_state.dart';

final repairDetailsControllerProvider = FutureProvider.autoDispose
    .family<RepairDetailsState?, int>((ref, repairId) async {
      final repository = ref.watch(repairRepositoryProvider);
      final repair = await repository.getRepairById(repairId);
      if (repair == null) {
        return null;
      }

      Repair? originalRepair;
      if (repair.parentRepairId != null) {
        originalRepair = await repository.getRepairById(repair.parentRepairId!);
      }

      return RepairDetailsState(
        repair: repair,
        originalRepair: originalRepair,
        timelineEntries: _buildTimelineEntries(repair),
        canCreateWarrantyReturn:
            repair.status == RepairStatus.delivered &&
            repair.parentRepairId == null,
      );
    });

List<RepairTimelineEntry> _buildTimelineEntries(Repair repair) {
  final entries = <RepairTimelineEntry>[
    RepairTimelineEntry(
      title: 'Repair received',
      timestamp: repair.receivedAt,
      type: RepairTimelineEntryType.received,
    ),
  ];

  if (repair.readyAt != null) {
    entries.add(
      RepairTimelineEntry(
        title: 'Ready for pickup',
        timestamp: repair.readyAt!,
        type: RepairTimelineEntryType.readyForPickup,
      ),
    );
  }

  if (repair.deliveredAt != null) {
    entries.add(
      RepairTimelineEntry(
        title: 'Delivered',
        timestamp: repair.deliveredAt!,
        type: RepairTimelineEntryType.delivered,
      ),
    );
  }

  entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  return entries;
}
