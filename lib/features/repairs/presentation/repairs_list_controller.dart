import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/repair_search_query.dart';
import '../domain/repair_status.dart';
import '../repair_providers.dart';
import 'repairs_list_state.dart';

const repairsSearchDebounceDuration = Duration(milliseconds: 300);

final repairsListClockProvider = Provider<DateTime Function()>((ref) {
  return DateTime.now;
});

final repairsListControllerProvider =
    AsyncNotifierProvider<RepairsListController, RepairsListState>(
      RepairsListController.new,
    );

class RepairsListController extends AsyncNotifier<RepairsListState> {
  Timer? _searchDebounce;
  RepairsListState _filters = RepairsListState.initial();

  @override
  Future<RepairsListState> build() {
    ref.onDispose(() => _searchDebounce?.cancel());
    return _load();
  }

  Future<void> refresh() {
    return _reload();
  }

  void updateSearchText(String value) {
    _filters = _filters.copyWith(searchText: value, offset: 0);
    _searchDebounce?.cancel();
    _searchDebounce = Timer(repairsSearchDebounceDuration, () {
      _reload();
    });
  }

  Future<void> applyQuickFilter(RepairsQuickFilter filter) {
    _filters = _filters.copyWith(
      quickFilter: filter,
      clearSelectedStatus: true,
      offset: 0,
    );
    return _reload();
  }

  Future<void> applyStatusFilter(RepairStatus? status) {
    _filters = _filters.copyWith(
      quickFilter: RepairsQuickFilter.all,
      selectedStatus: status,
      clearSelectedStatus: status == null,
      offset: 0,
    );
    return _reload();
  }

  Future<void> applyDatePreset(RepairsDatePreset preset) {
    _filters = _filters.copyWith(datePreset: preset, offset: 0);
    return _reload();
  }

  Future<void> applyLifecycleScope(RepairLifecycleScope scope) {
    _filters = _filters.copyWith(lifecycleScope: scope, offset: 0);
    return _reload();
  }

  Future<void> applySort(RepairSearchSort sort) {
    _filters = _filters.copyWith(sort: sort, offset: 0);
    return _reload();
  }

  Future<void> clearFilters() {
    _filters = RepairsListState.initial();
    _searchDebounce?.cancel();
    return _reload();
  }

  Future<void> nextPage() {
    if (state.asData?.value.canGoNext != true) {
      return Future.value();
    }

    _filters = _filters.copyWith(offset: _filters.offset + _filters.pageSize);
    return _reload();
  }

  Future<void> previousPage() {
    if (_filters.offset == 0) {
      return Future.value();
    }

    final nextOffset = _filters.offset - _filters.pageSize;
    _filters = _filters.copyWith(offset: nextOffset < 0 ? 0 : nextOffset);
    return _reload();
  }

  RepairSearchQuery buildQuery() {
    final dateRange = _dateRangeFor(_filters.datePreset);
    final statuses = <RepairStatus>{
      ..._filters.quickFilter.statuses,
      if (_filters.selectedStatus != null) _filters.selectedStatus!,
    };
    final scope = _filters.quickFilter == RepairsQuickFilter.active
        ? RepairLifecycleScope.active
        : _filters.lifecycleScope;

    return RepairSearchQuery(
      searchText: _filters.searchText,
      statuses: statuses,
      lifecycleScope: scope,
      receivedFrom: dateRange.from,
      receivedTo: dateRange.to,
      sort: _filters.sort,
      limit: _filters.pageSize,
      offset: _filters.offset,
    );
  }

  Future<void> _reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  Future<RepairsListState> _load() async {
    final query = buildQuery();
    final repairs = await ref
        .read(repairRepositoryProvider)
        .searchRepairs(query);

    _filters = _filters.copyWith(repairs: repairs);
    return _filters;
  }

  RepairsDateRange _dateRangeFor(RepairsDatePreset preset) {
    if (preset == RepairsDatePreset.all) {
      return const RepairsDateRange();
    }

    final localNow = ref.read(repairsListClockProvider)().toLocal();
    final todayStart = DateTime(localNow.year, localNow.month, localNow.day);
    final tomorrowStart = todayStart.add(const Duration(days: 1));

    return switch (preset) {
      RepairsDatePreset.today => RepairsDateRange(
        from: todayStart.toUtc(),
        to: tomorrowStart.toUtc(),
      ),
      RepairsDatePreset.last7Days => RepairsDateRange(
        from: todayStart.subtract(const Duration(days: 6)).toUtc(),
        to: tomorrowStart.toUtc(),
      ),
      RepairsDatePreset.last30Days => RepairsDateRange(
        from: todayStart.subtract(const Duration(days: 29)).toUtc(),
        to: tomorrowStart.toUtc(),
      ),
      RepairsDatePreset.all => const RepairsDateRange(),
    };
  }
}
