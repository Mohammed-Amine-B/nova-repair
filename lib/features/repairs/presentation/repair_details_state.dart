import '../domain/entities/repair.dart';

class RepairDetailsState {
  const RepairDetailsState({
    required this.repair,
    required this.timelineEntries,
    required this.canCreateWarrantyReturn,
    this.originalRepair,
  });

  final Repair repair;
  final Repair? originalRepair;
  final List<RepairTimelineEntry> timelineEntries;
  final bool canCreateWarrantyReturn;
}

class RepairTimelineEntry {
  const RepairTimelineEntry({
    required this.title,
    required this.timestamp,
    required this.type,
  });

  final String title;
  final DateTime timestamp;
  final RepairTimelineEntryType type;
}

enum RepairTimelineEntryType { received, readyForPickup, delivered }
