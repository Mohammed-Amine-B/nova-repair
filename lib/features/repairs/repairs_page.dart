import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/widgets/buttons/app_buttons.dart';
import '../../app/widgets/empty_value_text.dart';
import '../../app/widgets/page_header.dart';
import '../../app/widgets/section_card.dart';
import '../../app/widgets/status_badge.dart';
import '../../app/widgets/table/app_table_shell.dart';
import 'domain/entities/repair.dart';
import 'domain/entities/repair_search_query.dart';
import 'domain/repair_status.dart';
import 'domain/services/device_display_name_formatter.dart';
import 'presentation/repairs_list_controller.dart';
import 'presentation/repairs_list_date_formatter.dart';
import 'presentation/repairs_list_state.dart';

class RepairsPage extends ConsumerStatefulWidget {
  const RepairsPage({this.onNewRepair, this.onRepairSelected, super.key});

  final VoidCallback? onNewRepair;
  final ValueChanged<Repair>? onRepairSelected;

  @override
  ConsumerState<RepairsPage> createState() => _RepairsPageState();
}

class _RepairsPageState extends ConsumerState<RepairsPage> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repairsList = ref.watch(repairsListControllerProvider);
    final loadedState = repairsList.asData?.value;

    if (loadedState != null &&
        _searchController.text != loadedState.searchText) {
      _searchController.value = TextEditingValue(
        text: loadedState.searchText,
        selection: TextSelection.collapsed(
          offset: loadedState.searchText.length,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'Repairs',
            subtitle: 'Manage and track all repair jobs',
            actions: [
              PrimaryButton(
                label: 'New Repair',
                icon: Icons.add,
                onPressed: widget.onNewRepair,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          _RepairsFilters(
            state: loadedState ?? RepairsListState.initial(),
            searchController: _searchController,
          ),
          const SizedBox(height: AppSpacing.xl),
          Expanded(
            child: repairsList.when(
              data: (state) => _RepairsTableSection(
                state: state,
                onRepairSelected: widget.onRepairSelected,
              ),
              loading: () => const _RepairsLoadingState(),
              error: (error, stackTrace) => _RepairsErrorState(
                onRetry: () {
                  ref.read(repairsListControllerProvider.notifier).refresh();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RepairsFilters extends ConsumerWidget {
  const _RepairsFilters({required this.state, required this.searchController});

  final RepairsListState state;
  final TextEditingController searchController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(repairsListControllerProvider.notifier);
    Widget searchField() {
      return TextField(
        controller: searchController,
        onChanged: controller.updateSearchText,
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.search, size: 20),
          hintText: 'Search by repair code, customer, phone, or device',
        ),
      );
    }

    Widget statusFilter() {
      return SizedBox(
        width: 220,
        child: DropdownButtonFormField<RepairStatus?>(
          initialValue: state.selectedStatus,
          isExpanded: true,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.tune_outlined, size: 18),
          ),
          items: [
            const DropdownMenuItem<RepairStatus?>(child: Text('All Statuses')),
            for (final status in RepairStatus.values)
              DropdownMenuItem<RepairStatus?>(
                value: status,
                child: Text(status.displayLabel),
              ),
          ],
          onChanged: (status) => controller.applyStatusFilter(status),
        ),
      );
    }

    Widget dateFilter() {
      return SizedBox(
        width: 190,
        child: DropdownButtonFormField<RepairsDatePreset>(
          initialValue: state.datePreset,
          isExpanded: true,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.event_outlined, size: 18),
          ),
          items: [
            for (final preset in RepairsDatePreset.values)
              DropdownMenuItem(value: preset, child: Text(preset.label)),
          ],
          onChanged: (preset) {
            if (preset != null) {
              controller.applyDatePreset(preset);
            }
          },
        ),
      );
    }

    return SectionCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 760) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    searchField(),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        statusFilter(),
                        dateFilter(),
                        _MoreFiltersButton(state: state),
                      ],
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: searchField()),
                  const SizedBox(width: AppSpacing.sm),
                  statusFilter(),
                  const SizedBox(width: AppSpacing.sm),
                  dateFilter(),
                  const SizedBox(width: AppSpacing.sm),
                  _MoreFiltersButton(state: state),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(child: _QuickFilterChips(state: state)),
              if (state.hasActiveFilters)
                GhostButton(
                  label: 'Clear filters',
                  icon: Icons.close,
                  onPressed: controller.clearFilters,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MoreFiltersButton extends ConsumerWidget {
  const _MoreFiltersButton({required this.state});

  final RepairsListState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(repairsListControllerProvider.notifier);

    return PopupMenuButton<_MoreFilterAction>(
      tooltip: 'More Filters',
      onSelected: (action) {
        switch (action) {
          case _MoreFilterAction.lifecycleAll:
            controller.applyLifecycleScope(RepairLifecycleScope.all);
          case _MoreFilterAction.lifecycleActive:
            controller.applyLifecycleScope(RepairLifecycleScope.active);
          case _MoreFilterAction.lifecycleFinalized:
            controller.applyLifecycleScope(RepairLifecycleScope.finalized);
          case _MoreFilterAction.sortNewest:
            controller.applySort(RepairSearchSort.newestFirst);
          case _MoreFilterAction.sortOldest:
            controller.applySort(RepairSearchSort.oldestFirst);
        }
      },
      itemBuilder: (context) {
        return const [
          PopupMenuItem(enabled: false, child: Text('Lifecycle')),
          PopupMenuItem(
            value: _MoreFilterAction.lifecycleAll,
            child: Text('All'),
          ),
          PopupMenuItem(
            value: _MoreFilterAction.lifecycleActive,
            child: Text('Active'),
          ),
          PopupMenuItem(
            value: _MoreFilterAction.lifecycleFinalized,
            child: Text('Finalized'),
          ),
          PopupMenuDivider(),
          PopupMenuItem(enabled: false, child: Text('Sort')),
          PopupMenuItem(
            value: _MoreFilterAction.sortNewest,
            child: Text('Newest first'),
          ),
          PopupMenuItem(
            value: _MoreFilterAction.sortOldest,
            child: Text('Oldest first'),
          ),
        ];
      },
      child: Container(
        height: AppSpacing.minimumButtonHeight,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(AppRadius.control),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.filter_list, size: 18, color: AppColors.textSecondary),
            SizedBox(width: AppSpacing.xs),
            Text('More Filters'),
          ],
        ),
      ),
    );
  }
}

enum _MoreFilterAction {
  lifecycleAll,
  lifecycleActive,
  lifecycleFinalized,
  sortNewest,
  sortOldest,
}

class _QuickFilterChips extends ConsumerWidget {
  const _QuickFilterChips({required this.state});

  final RepairsListState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(repairsListControllerProvider.notifier);

    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        for (final filter in RepairsQuickFilter.values)
          ChoiceChip(
            label: Text(filter.label),
            selected: state.quickFilter == filter,
            onSelected: (_) => controller.applyQuickFilter(filter),
            showCheckmark: false,
          ),
      ],
    );
  }
}

class _RepairsTableSection extends StatelessWidget {
  const _RepairsTableSection({
    required this.state,
    required this.onRepairSelected,
  });

  final RepairsListState state;
  final ValueChanged<Repair>? onRepairSelected;

  @override
  Widget build(BuildContext context) {
    if (state.repairs.isEmpty) {
      return _RepairsEmptyState(hasActiveFilters: state.hasActiveFilters);
    }

    return AppTableShell(
      expandChild: true,
      child: Column(
        children: [
          const _RepairsTableHeader(),
          Expanded(
            child: ListView.builder(
              itemCount: state.repairs.length,
              itemBuilder: (context, index) {
                final repair = state.repairs[index];
                return _RepairTableRow(
                  repair: repair,
                  onTap: onRepairSelected == null
                      ? null
                      : () => onRepairSelected!(repair),
                );
              },
            ),
          ),
          _PaginationBar(state: state),
        ],
      ),
    );
  }
}

class _RepairsTableHeader extends StatelessWidget {
  const _RepairsTableHeader();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.softSurface,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            _HeaderCell('Repair Code', flex: 2),
            _HeaderCell('Device', flex: 3),
            _HeaderCell('Customer', flex: 3),
            _HeaderCell('Phone', flex: 2),
            _HeaderCell('Status', flex: 3),
            _HeaderCell('Received Date', flex: 2),
            _HeaderCell('Last Updated', flex: 2),
            SizedBox(width: 32),
          ],
        ),
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.label, {required this.flex});

  final String label;
  final int flex;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _RepairTableRow extends ConsumerWidget {
  const _RepairTableRow({required this.repair, required this.onTap});

  final Repair repair;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const deviceFormatter = DeviceDisplayNameFormatter();
    const dateFormatter = RepairsListDateFormatter();
    final now = ref.watch(repairsListClockProvider)().toUtc();
    final finalized = RepairSearchQuery.finalizedStatuses.contains(
      repair.status,
    );
    final openIndicator = dateFormatter.formatOpenDays(
      receivedAt: repair.receivedAt,
      now: now,
      isFinalized: finalized,
    );
    final deviceDisplay = deviceFormatter.format(
      brand: repair.brand,
      model: repair.model,
      deviceType: repair.deviceType,
    );

    return AppTableRowShell(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    repair.repairCode,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (openIndicator != null) ...[
                  const SizedBox(width: AppSpacing.xs),
                  const Icon(
                    Icons.warning_amber_outlined,
                    color: Color(0xFFD97706),
                    size: 16,
                  ),
                ],
              ],
            ),
          ),
          Expanded(flex: 3, child: Text(deviceDisplay)),
          Expanded(
            flex: 3,
            child: repair.customerName == null
                ? const EmptyValueText()
                : Text(repair.customerName!),
          ),
          Expanded(
            flex: 2,
            child: repair.customerPhone == null
                ? const EmptyValueText()
                : Text(repair.customerPhone!),
          ),
          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.centerLeft,
              child: StatusBadge(status: repair.status),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(dateFormatter.formatDate(repair.receivedAt, now)),
          ),
          Expanded(
            flex: 2,
            child: openIndicator == null
                ? Text(dateFormatter.formatDate(repair.updatedAt, now))
                : Text(
                    openIndicator,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFFD97706),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
          const SizedBox(
            width: 32,
            child: Icon(
              Icons.chevron_right,
              color: AppColors.textMuted,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaginationBar extends ConsumerWidget {
  const _PaginationBar({required this.state});

  final RepairsListState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(repairsListControllerProvider.notifier);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      decoration: const BoxDecoration(
        color: AppColors.softSurface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Text(
            'Page ${state.currentPage}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Previous page',
            onPressed: state.canGoPrevious ? controller.previousPage : null,
            icon: const Icon(Icons.chevron_left),
          ),
          const SizedBox(width: AppSpacing.xs),
          IconButton(
            tooltip: 'Next page',
            onPressed: state.canGoNext ? controller.nextPage : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}

class _RepairsLoadingState extends StatelessWidget {
  const _RepairsLoadingState();

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      child: SectionCard(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.xxl),
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    );
  }
}

class _RepairsEmptyState extends StatelessWidget {
  const _RepairsEmptyState({required this.hasActiveFilters});

  final bool hasActiveFilters;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: SectionCard(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  hasActiveFilters ? 'No repairs found' : 'No repairs yet',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  hasActiveFilters
                      ? 'Try adjusting your search or filters.'
                      : 'Create your first repair to get started.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RepairsErrorState extends StatelessWidget {
  const _RepairsErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Repairs could not be loaded.',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              'Please try again.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
            SecondaryButton(label: 'Retry', onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}
