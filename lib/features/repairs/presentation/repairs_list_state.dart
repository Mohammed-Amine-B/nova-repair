import '../domain/entities/repair.dart';
import '../domain/entities/repair_search_query.dart';
import '../domain/repair_status.dart';

const repairsListPageSize = 20;

enum RepairsQuickFilter {
  all('All'),
  active('Active'),
  waitingForApproval('Waiting for Approval'),
  waitingForPart('Waiting for Part'),
  readyForPickup('Ready for Pickup'),
  delivered('Delivered');

  const RepairsQuickFilter(this.label);

  final String label;

  RepairLifecycleScope get lifecycleScope {
    return switch (this) {
      RepairsQuickFilter.active => RepairLifecycleScope.active,
      _ => RepairLifecycleScope.all,
    };
  }

  Set<RepairStatus> get statuses {
    return switch (this) {
      RepairsQuickFilter.waitingForApproval => {
        RepairStatus.waitingForCustomerApproval,
      },
      RepairsQuickFilter.waitingForPart => {RepairStatus.waitingForPart},
      RepairsQuickFilter.readyForPickup => {RepairStatus.readyForPickup},
      RepairsQuickFilter.delivered => {RepairStatus.delivered},
      _ => const {},
    };
  }
}

enum RepairsDatePreset {
  all('All Dates'),
  today('Today'),
  last7Days('Last 7 Days'),
  last30Days('Last 30 Days');

  const RepairsDatePreset(this.label);

  final String label;
}

class RepairsDateRange {
  const RepairsDateRange({this.from, this.to});

  final DateTime? from;
  final DateTime? to;
}

class RepairsListState {
  const RepairsListState({
    required this.repairs,
    required this.searchText,
    required this.quickFilter,
    required this.selectedStatus,
    required this.datePreset,
    required this.lifecycleScope,
    required this.sort,
    required this.offset,
    required this.pageSize,
  });

  factory RepairsListState.initial() {
    return const RepairsListState(
      repairs: [],
      searchText: '',
      quickFilter: RepairsQuickFilter.all,
      selectedStatus: null,
      datePreset: RepairsDatePreset.all,
      lifecycleScope: RepairLifecycleScope.all,
      sort: RepairSearchSort.newestFirst,
      offset: 0,
      pageSize: repairsListPageSize,
    );
  }

  final List<Repair> repairs;
  final String searchText;
  final RepairsQuickFilter quickFilter;
  final RepairStatus? selectedStatus;
  final RepairsDatePreset datePreset;
  final RepairLifecycleScope lifecycleScope;
  final RepairSearchSort sort;
  final int offset;
  final int pageSize;

  bool get canGoPrevious => offset > 0;

  bool get canGoNext => repairs.length == pageSize;

  int get currentPage => (offset ~/ pageSize) + 1;

  bool get hasActiveFilters {
    return searchText.trim().isNotEmpty ||
        quickFilter != RepairsQuickFilter.all ||
        selectedStatus != null ||
        datePreset != RepairsDatePreset.all ||
        lifecycleScope != RepairLifecycleScope.all ||
        sort != RepairSearchSort.newestFirst;
  }

  RepairsListState copyWith({
    List<Repair>? repairs,
    String? searchText,
    RepairsQuickFilter? quickFilter,
    RepairStatus? selectedStatus,
    bool clearSelectedStatus = false,
    RepairsDatePreset? datePreset,
    RepairLifecycleScope? lifecycleScope,
    RepairSearchSort? sort,
    int? offset,
    int? pageSize,
  }) {
    return RepairsListState(
      repairs: repairs ?? this.repairs,
      searchText: searchText ?? this.searchText,
      quickFilter: quickFilter ?? this.quickFilter,
      selectedStatus: clearSelectedStatus
          ? null
          : selectedStatus ?? this.selectedStatus,
      datePreset: datePreset ?? this.datePreset,
      lifecycleScope: lifecycleScope ?? this.lifecycleScope,
      sort: sort ?? this.sort,
      offset: offset ?? this.offset,
      pageSize: pageSize ?? this.pageSize,
    );
  }
}
