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
import '../repairs/domain/entities/repair.dart';
import '../repairs/domain/services/device_display_name_formatter.dart';
import 'presentation/dashboard_controller.dart';
import 'presentation/dashboard_date_formatter.dart';
import 'presentation/dashboard_state.dart';
import 'presentation/widgets/dashboard_summary_card.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({
    this.onViewAllRepairs,
    this.onRepairSelected,
    super.key,
  });

  final VoidCallback? onViewAllRepairs;
  final ValueChanged<Repair>? onRepairSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(dashboardControllerProvider);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: dashboard.when(
        data: (state) => _DashboardContent(
          state: state,
          onViewAllRepairs: onViewAllRepairs,
          onRepairSelected: onRepairSelected,
        ),
        loading: () => const _DashboardLoading(),
        error: (error, stackTrace) => _DashboardError(
          onRetry: () {
            ref.read(dashboardControllerProvider.notifier).refreshDashboard();
          },
        ),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    required this.state,
    required this.onViewAllRepairs,
    required this.onRepairSelected,
  });

  final DashboardState state;
  final VoidCallback? onViewAllRepairs;
  final ValueChanged<Repair>? onRepairSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
            title: 'Dashboard',
            subtitle: 'Overview of your repair activity',
          ),
          const SizedBox(height: AppSpacing.xl),
          _SummaryCards(state: state),
          const SizedBox(height: AppSpacing.xl),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 7,
                child: _RecentRepairsSection(
                  repairs: state.recentRepairs,
                  onViewAllRepairs: onViewAllRepairs,
                  onRepairSelected: onRepairSelected,
                ),
              ),
              const SizedBox(width: AppSpacing.xl),
              Expanded(flex: 3, child: _NeedsAttentionSection(state: state)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryCards extends StatelessWidget {
  const _SummaryCards({required this.state});

  final DashboardState state;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: DashboardSummaryCard(
            label: 'Active Repairs',
            value: state.activeRepairCount,
            icon: Icons.home_repair_service_outlined,
            iconBackground: AppColors.primarySoft,
            iconColor: AppColors.primary,
          ),
        ),
        const SizedBox(width: AppSpacing.xl),
        Expanded(
          child: DashboardSummaryCard(
            label: 'Waiting for Approval',
            value: state.waitingForApprovalCount,
            icon: Icons.pending_actions_outlined,
            iconBackground: AppColors.waitingForCustomerApproval.background,
            iconColor: AppColors.waitingForCustomerApproval.foreground,
          ),
        ),
        const SizedBox(width: AppSpacing.xl),
        Expanded(
          child: DashboardSummaryCard(
            label: 'Waiting for Part',
            value: state.waitingForPartCount,
            icon: Icons.event_available_outlined,
            iconBackground: AppColors.waitingForPart.background,
            iconColor: AppColors.waitingForPart.foreground,
          ),
        ),
        const SizedBox(width: AppSpacing.xl),
        Expanded(
          child: DashboardSummaryCard(
            label: 'Ready for Pickup',
            value: state.readyForPickupCount,
            icon: Icons.task_alt_outlined,
            iconBackground: AppColors.readyForPickup.background,
            iconColor: AppColors.readyForPickup.foreground,
          ),
        ),
      ],
    );
  }
}

class _RecentRepairsSection extends StatelessWidget {
  const _RecentRepairsSection({
    required this.repairs,
    required this.onViewAllRepairs,
    required this.onRepairSelected,
  });

  final List<Repair> repairs;
  final VoidCallback? onViewAllRepairs;
  final ValueChanged<Repair>? onRepairSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppTableShell(
      header: Row(
        children: [
          Expanded(
            child: Text(
              'Recent Repairs',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          TextButton(
            onPressed: onViewAllRepairs,
            child: const Text('View all repairs →'),
          ),
        ],
      ),
      child: repairs.isEmpty
          ? const _RecentRepairsEmptyState()
          : Column(
              children: [
                const _RecentRepairsHeaderRow(),
                for (final repair in repairs)
                  _RecentRepairRow(
                    repair: repair,
                    onTap: onRepairSelected == null
                        ? null
                        : () => onRepairSelected!(repair),
                  ),
              ],
            ),
    );
  }
}

class _RecentRepairsHeaderRow extends StatelessWidget {
  const _RecentRepairsHeaderRow();

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
            _TableHeaderCell('Repair Code', flex: 2),
            _TableHeaderCell('Device', flex: 3),
            _TableHeaderCell('Customer', flex: 3),
            _TableHeaderCell('Status', flex: 3),
            _TableHeaderCell('Received Date', flex: 2),
          ],
        ),
      ),
    );
  }
}

class _TableHeaderCell extends StatelessWidget {
  const _TableHeaderCell(this.label, {required this.flex});

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

class _RecentRepairRow extends StatelessWidget {
  const _RecentRepairRow({required this.repair, required this.onTap});

  final Repair repair;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    const deviceFormatter = DeviceDisplayNameFormatter();
    const dateFormatter = DashboardDateFormatter();
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
            child: Text(
              repair.repairCode,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
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
            flex: 3,
            child: Align(
              alignment: Alignment.centerLeft,
              child: StatusBadge(status: repair.status),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(dateFormatter.formatReceivedDate(repair.receivedAt)),
          ),
        ],
      ),
    );
  }
}

class _RecentRepairsEmptyState extends StatelessWidget {
  const _RecentRepairsEmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        children: [
          Text(
            'No repairs yet',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'New repairs will appear here.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _NeedsAttentionSection extends StatelessWidget {
  const _NeedsAttentionSection({required this.state});

  final DashboardState state;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Needs Attention',
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          _AttentionItem(
            label: 'Waiting for customer approval',
            count: state.attentionCounts.waitingForCustomerApproval,
            icon: Icons.rate_review_outlined,
            color: AppColors.waitingForCustomerApproval.foreground,
            background: AppColors.waitingForCustomerApproval.background,
          ),
          const SizedBox(height: AppSpacing.md),
          _AttentionItem(
            label: 'Ready for pickup over 5 days',
            count: state.attentionCounts.readyTooLong,
            icon: Icons.fact_check_outlined,
            color: AppColors.readyForPickup.foreground,
            background: AppColors.readyForPickup.background,
          ),
          const SizedBox(height: AppSpacing.md),
          _AttentionItem(
            label: 'Open for over 14 days',
            count: state.attentionCounts.delayedActive,
            icon: Icons.warning_amber_outlined,
            color: AppColors.waitingForPart.foreground,
            background: AppColors.waitingForPart.background,
          ),
        ],
      ),
    );
  }
}

class _AttentionItem extends StatelessWidget {
  const _AttentionItem({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
    required this.background,
  });

  final String label;
  final int count;
  final IconData icon;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: background.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ColoredBox(color: color, child: const SizedBox(width: 3)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, color: color, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _countText(count),
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            label,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _countText(int count) {
    return count == 1 ? '1 repair' : '$count repairs';
  }
}

class _DashboardLoading extends StatelessWidget {
  const _DashboardLoading();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: 'Dashboard',
          subtitle: 'Overview of your repair activity',
        ),
        Expanded(child: Center(child: CircularProgressIndicator())),
      ],
    );
  }
}

class _DashboardError extends StatelessWidget {
  const _DashboardError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageHeader(
          title: 'Dashboard',
          subtitle: 'Overview of your repair activity',
        ),
        const SizedBox(height: AppSpacing.xl),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dashboard could not be loaded.',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                'Please try again.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SecondaryButton(label: 'Retry', onPressed: onRetry),
            ],
          ),
        ),
      ],
    );
  }
}
