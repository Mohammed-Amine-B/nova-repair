import '../repair_status.dart';

enum RepairLifecycleScope {
  all,
  active,
  finalized;

  Set<RepairStatus>? get statusSet {
    return switch (this) {
      RepairLifecycleScope.all => null,
      RepairLifecycleScope.active => RepairSearchQuery.activeStatuses,
      RepairLifecycleScope.finalized => RepairSearchQuery.finalizedStatuses,
    };
  }
}

enum RepairSearchSort { newestFirst, oldestFirst }

class RepairSearchQuery {
  RepairSearchQuery({
    String? searchText,
    Set<RepairStatus> statuses = const {},
    this.lifecycleScope = RepairLifecycleScope.all,
    DateTime? receivedFrom,
    DateTime? receivedTo,
    this.sort = RepairSearchSort.newestFirst,
    this.limit = 50,
    this.offset = 0,
  }) : searchText = _normalizeSearchText(searchText),
       statuses = Set.unmodifiable(statuses),
       receivedFrom = receivedFrom?.toUtc(),
       receivedTo = receivedTo?.toUtc() {
    if (limit <= 0) {
      throw ArgumentError.value(limit, 'limit', 'Must be positive.');
    }
    if (offset < 0) {
      throw ArgumentError.value(offset, 'offset', 'Cannot be negative.');
    }
    if (this.receivedFrom != null &&
        this.receivedTo != null &&
        !this.receivedFrom!.isBefore(this.receivedTo!)) {
      throw ArgumentError.value(
        this.receivedTo,
        'receivedTo',
        'Must be after receivedFrom.',
      );
    }
  }

  static const activeStatuses = {
    RepairStatus.received,
    RepairStatus.diagnosing,
    RepairStatus.waitingForCustomerApproval,
    RepairStatus.waitingForPart,
    RepairStatus.repairing,
    RepairStatus.readyForPickup,
  };

  static const finalizedStatuses = {
    RepairStatus.delivered,
    RepairStatus.cancelled,
  };

  final String? searchText;
  final Set<RepairStatus> statuses;
  final RepairLifecycleScope lifecycleScope;
  final DateTime? receivedFrom;
  final DateTime? receivedTo;
  final RepairSearchSort sort;
  final int limit;
  final int offset;

  Set<RepairStatus>? get effectiveStatuses {
    final scopeStatuses = lifecycleScope.statusSet;
    if (statuses.isEmpty) {
      return scopeStatuses;
    }
    if (scopeStatuses == null) {
      return statuses;
    }

    return statuses.intersection(scopeStatuses);
  }

  static String? _normalizeSearchText(String? value) {
    if (value == null) {
      return null;
    }

    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
