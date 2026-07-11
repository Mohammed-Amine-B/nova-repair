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
import 'domain/customer_price_decision.dart';
import 'domain/entities/repair.dart';
import 'domain/services/device_display_name_formatter.dart';
import 'presentation/repair_details_controller.dart';
import 'presentation/repair_details_formatters.dart';
import 'presentation/repair_details_state.dart';

class RepairDetailsPage extends ConsumerWidget {
  const RepairDetailsPage({
    required this.repairId,
    required this.onBackToRepairs,
    required this.onEditRepair,
    required this.onChangeStatus,
    required this.onPrintRepair,
    required this.onCreateWarrantyReturn,
    super.key,
  });

  final int repairId;
  final VoidCallback onBackToRepairs;
  final ValueChanged<Repair> onEditRepair;
  final ValueChanged<Repair> onChangeStatus;
  final ValueChanged<Repair> onPrintRepair;
  final ValueChanged<Repair> onCreateWarrantyReturn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final details = ref.watch(repairDetailsControllerProvider(repairId));

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
            title: 'Repair Details',
            subtitle: 'View and manage repair information',
          ),
          const SizedBox(height: AppSpacing.xl),
          Expanded(
            child: details.when(
              data: (state) {
                if (state == null) {
                  return _RepairMissingState(onBack: onBackToRepairs);
                }

                return _RepairDetailsContent(
                  state: state,
                  onBackToRepairs: onBackToRepairs,
                  onEditRepair: onEditRepair,
                  onChangeStatus: onChangeStatus,
                  onPrintRepair: onPrintRepair,
                  onCreateWarrantyReturn: onCreateWarrantyReturn,
                );
              },
              loading: () => const _RepairDetailsLoadingState(),
              error: (error, stackTrace) => _RepairDetailsErrorState(
                onRetry: () {
                  ref.invalidate(repairDetailsControllerProvider(repairId));
                },
                onBack: onBackToRepairs,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RepairDetailsContent extends StatelessWidget {
  const _RepairDetailsContent({
    required this.state,
    required this.onBackToRepairs,
    required this.onEditRepair,
    required this.onChangeStatus,
    required this.onPrintRepair,
    required this.onCreateWarrantyReturn,
  });

  final RepairDetailsState state;
  final VoidCallback onBackToRepairs;
  final ValueChanged<Repair> onEditRepair;
  final ValueChanged<Repair> onChangeStatus;
  final ValueChanged<Repair> onPrintRepair;
  final ValueChanged<Repair> onCreateWarrantyReturn;

  @override
  Widget build(BuildContext context) {
    final repair = state.repair;

    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _RepairContextHeader(
                repair: repair,
                onBackToRepairs: onBackToRepairs,
                onEditRepair: onEditRepair,
                onChangeStatus: onChangeStatus,
                onPrintRepair: onPrintRepair,
              ),
              const SizedBox(height: AppSpacing.lg),
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 980) {
                    return Column(
                      children: [
                        _LeftColumn(state: state),
                        const SizedBox(height: AppSpacing.lg),
                        _RightColumn(
                          state: state,
                          onCreateWarrantyReturn: onCreateWarrantyReturn,
                        ),
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 2, child: _LeftColumn(state: state)),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        child: _RightColumn(
                          state: state,
                          onCreateWarrantyReturn: onCreateWarrantyReturn,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RepairContextHeader extends StatelessWidget {
  const _RepairContextHeader({
    required this.repair,
    required this.onBackToRepairs,
    required this.onEditRepair,
    required this.onChangeStatus,
    required this.onPrintRepair,
  });

  final Repair repair;
  final VoidCallback onBackToRepairs;
  final ValueChanged<Repair> onEditRepair;
  final ValueChanged<Repair> onChangeStatus;
  final ValueChanged<Repair> onPrintRepair;

  @override
  Widget build(BuildContext context) {
    const deviceFormatter = DeviceDisplayNameFormatter();
    final deviceDisplay = deviceFormatter.format(
      brand: repair.brand,
      model: repair.model,
      deviceType: repair.deviceType,
    );

    return SectionCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GhostButton(
                  label: 'Back to Repairs',
                  icon: Icons.arrow_back,
                  onPressed: onBackToRepairs,
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      repair.repairCode,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    StatusBadge(status: repair.status),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  deviceDisplay,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            alignment: WrapAlignment.end,
            children: [
              SecondaryButton(
                label: 'Edit Repair',
                icon: Icons.edit_outlined,
                onPressed: () => onEditRepair(repair),
              ),
              SecondaryButton(
                label: 'Change Status',
                icon: Icons.sync_alt,
                onPressed: () => onChangeStatus(repair),
              ),
              PrimaryButton(
                label: 'Print',
                icon: Icons.print_outlined,
                onPressed: () => onPrintRepair(repair),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LeftColumn extends StatelessWidget {
  const _LeftColumn({required this.state});

  final RepairDetailsState state;

  @override
  Widget build(BuildContext context) {
    final repair = state.repair;

    return Column(
      children: [
        SectionCard(
          title: 'Device Information',
          child: _DeviceInformation(repair: repair),
        ),
        const SizedBox(height: AppSpacing.lg),
        SectionCard(
          title: 'Reported Problem',
          child: _ReadOnlyParagraph(value: repair.reportedProblem),
        ),
        const SizedBox(height: AppSpacing.lg),
        SectionCard(
          title: 'Notes',
          child: _NotesSection(repair: repair),
        ),
        const SizedBox(height: AppSpacing.lg),
        SectionCard(
          title: 'Repair Timeline',
          child: _RepairTimeline(entries: state.timelineEntries),
        ),
      ],
    );
  }
}

class _RightColumn extends StatelessWidget {
  const _RightColumn({
    required this.state,
    required this.onCreateWarrantyReturn,
  });

  final RepairDetailsState state;
  final ValueChanged<Repair> onCreateWarrantyReturn;

  @override
  Widget build(BuildContext context) {
    final repair = state.repair;

    return Column(
      children: [
        SectionCard(
          title: 'Summary',
          child: _SummarySection(repair: repair),
        ),
        const SizedBox(height: AppSpacing.lg),
        SectionCard(
          title: 'Customer',
          child: _CustomerSection(repair: repair),
        ),
        const SizedBox(height: AppSpacing.lg),
        SectionCard(
          title: 'Price & Approval',
          child: _PriceApprovalSection(repair: repair),
        ),
        const SizedBox(height: AppSpacing.lg),
        SectionCard(
          title: 'Received Accessories',
          child: _ReadOnlyParagraph(value: repair.receivedAccessories),
        ),
        const SizedBox(height: AppSpacing.lg),
        SectionCard(
          title: 'Device Access',
          description: 'Internal only — not shown on printed tickets',
          child: _ReadOnlyParagraph(value: repair.deviceAccessInfo),
        ),
        const SizedBox(height: AppSpacing.lg),
        SectionCard(
          title: 'Warranty',
          child: _WarrantySection(
            state: state,
            onCreateWarrantyReturn: onCreateWarrantyReturn,
          ),
        ),
      ],
    );
  }
}

class _DeviceInformation extends StatelessWidget {
  const _DeviceInformation({required this.repair});

  final Repair repair;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final values = [
          _LabeledValue(label: 'Device Type', value: repair.deviceType),
          _LabeledValue(label: 'Brand', value: repair.brand),
          _LabeledValue(label: 'Model', value: repair.model),
        ];

        if (constraints.maxWidth < 640) {
          return Column(children: _withVerticalSpacing(values, AppSpacing.md));
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _withExpandedSpacing(values, AppSpacing.lg),
        );
      },
    );
  }
}

class _NotesSection extends StatelessWidget {
  const _NotesSection({required this.repair});

  final Repair repair;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _TextBlock(
          title: 'Internal Notes',
          subtitle: 'Internal only',
          value: repair.internalNotes,
        ),
        const SizedBox(height: AppSpacing.md),
        _TextBlock(
          title: 'Customer Message',
          subtitle: 'May later be shown to the customer in repair tracking',
          value: repair.customerMessage,
        ),
      ],
    );
  }
}

class _RepairTimeline extends StatelessWidget {
  const _RepairTimeline({required this.entries});

  final List<RepairTimelineEntry> entries;

  @override
  Widget build(BuildContext context) {
    const dateFormatter = RepairDetailsDateFormatter();

    return Column(
      children: [
        for (var index = 0; index < entries.length; index++) ...[
          _TimelineRow(entry: entries[index], dateFormatter: dateFormatter),
          if (index < entries.length - 1)
            const Padding(
              padding: EdgeInsets.only(left: 15),
              child: Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  height: AppSpacing.lg,
                  child: VerticalDivider(color: AppColors.border, width: 1),
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.entry, required this.dateFormatter});

  final RepairTimelineEntry entry;
  final RepairDetailsDateFormatter dateFormatter;

  @override
  Widget build(BuildContext context) {
    final icon = switch (entry.type) {
      RepairTimelineEntryType.received => Icons.check_circle_outline,
      RepairTimelineEntryType.readyForPickup => Icons.task_alt_outlined,
      RepairTimelineEntryType.delivered => Icons.inventory_2_outlined,
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xs),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.title,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                dateFormatter.format(entry.timestamp),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SummarySection extends StatelessWidget {
  const _SummarySection({required this.repair});

  final Repair repair;

  @override
  Widget build(BuildContext context) {
    const dateFormatter = RepairDetailsDateFormatter();

    return Column(
      children: [
        _SummaryRow(label: 'Code', value: Text(repair.repairCode)),
        _SummaryRow(
          label: 'Status',
          value: StatusBadge(status: repair.status),
        ),
        _SummaryRow(
          label: 'Received',
          value: Text(dateFormatter.format(repair.receivedAt)),
        ),
        _SummaryRow(
          label: 'Last Updated',
          value: Text(dateFormatter.format(repair.updatedAt)),
          showDivider: false,
        ),
      ],
    );
  }
}

class _CustomerSection extends StatelessWidget {
  const _CustomerSection({required this.repair});

  final Repair repair;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _LabeledValue(label: 'Customer Name', value: repair.customerName),
        const SizedBox(height: AppSpacing.md),
        _LabeledValue(label: 'Phone Number', value: repair.customerPhone),
      ],
    );
  }
}

class _PriceApprovalSection extends StatelessWidget {
  const _PriceApprovalSection({required this.repair});

  final Repair repair;

  @override
  Widget build(BuildContext context) {
    const priceFormatter = DzdPriceFormatter();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Proposed Repair Price',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        repair.priceAmount == null
            ? const EmptyValueText()
            : Text(
                priceFormatter.format(repair.priceAmount!),
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: Text(
                'Customer Decision',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ),
            PriceDecisionBadge(decision: repair.customerPriceDecision),
          ],
        ),
      ],
    );
  }
}

class _WarrantySection extends StatelessWidget {
  const _WarrantySection({
    required this.state,
    required this.onCreateWarrantyReturn,
  });

  final RepairDetailsState state;
  final ValueChanged<Repair> onCreateWarrantyReturn;

  @override
  Widget build(BuildContext context) {
    final repair = state.repair;

    if (repair.parentRepairId != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Warranty Return'),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            state.originalRepair == null
                ? 'Original repair could not be loaded'
                : 'Original repair: ${state.originalRepair!.repairCode}',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.history, size: 18, color: AppColors.textSecondary),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                'No previous repair linked',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        SecondaryButton(
          label: 'Create Warranty Return',
          icon: Icons.assignment_return_outlined,
          onPressed: state.canCreateWarrantyReturn
              ? () => onCreateWarrantyReturn(repair)
              : null,
        ),
      ],
    );
  }
}

class PriceDecisionBadge extends StatelessWidget {
  const PriceDecisionBadge({required this.decision, super.key});

  final CustomerPriceDecision decision;

  @override
  Widget build(BuildContext context) {
    final style = _PriceDecisionBadgeStyle.forDecision(decision);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.xxs,
        ),
        child: Text(
          style.label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: style.foreground,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _PriceDecisionBadgeStyle {
  const _PriceDecisionBadgeStyle({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  static _PriceDecisionBadgeStyle forDecision(CustomerPriceDecision decision) {
    return switch (decision) {
      CustomerPriceDecision.notRequested => const _PriceDecisionBadgeStyle(
        label: 'Not Requested',
        background: AppColors.softSurface,
        foreground: AppColors.textSecondary,
      ),
      CustomerPriceDecision.pending => const _PriceDecisionBadgeStyle(
        label: 'Pending',
        background: Color(0xFFFEF3C7),
        foreground: Color(0xFF92400E),
      ),
      CustomerPriceDecision.approved => const _PriceDecisionBadgeStyle(
        label: 'Approved',
        background: Color(0xFFDCFCE7),
        foreground: Color(0xFF166534),
      ),
      CustomerPriceDecision.rejected => const _PriceDecisionBadgeStyle(
        label: 'Rejected',
        background: Color(0xFFFEE2E2),
        foreground: Color(0xFFB91C1C),
      ),
    };
  }
}

class _LabeledValue extends StatelessWidget {
  const _LabeledValue({required this.label, this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final normalized = value?.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        normalized == null || normalized.isEmpty
            ? const EmptyValueText()
            : Text(
                normalized,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
      ],
    );
  }
}

class _TextBlock extends StatelessWidget {
  const _TextBlock({required this.title, required this.subtitle, this.value});

  final String title;
  final String subtitle;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xxs,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            Text(
              subtitle,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.softSurface,
            borderRadius: BorderRadius.circular(AppRadius.control),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: _ReadOnlyParagraph(value: value),
          ),
        ),
      ],
    );
  }
}

class _ReadOnlyParagraph extends StatelessWidget {
  const _ReadOnlyParagraph({this.value});

  final String? value;

  @override
  Widget build(BuildContext context) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return const EmptyValueText();
    }

    return Text(normalized, style: Theme.of(context).textTheme.bodyMedium);
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.showDivider = true,
  });

  final String label;
  final Widget value;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(bottom: BorderSide(color: AppColors.softSurface))
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Flexible(
            child: Align(alignment: Alignment.centerRight, child: value),
          ),
        ],
      ),
    );
  }
}

class _RepairDetailsLoadingState extends StatelessWidget {
  const _RepairDetailsLoadingState();

  @override
  Widget build(BuildContext context) {
    return const SectionCard(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xxl),
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}

class _RepairMissingState extends StatelessWidget {
  const _RepairMissingState({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Repair not found',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'The selected repair could not be loaded.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          SecondaryButton(
            label: 'Back to Repairs',
            icon: Icons.arrow_back,
            onPressed: onBack,
          ),
        ],
      ),
    );
  }
}

class _RepairDetailsErrorState extends StatelessWidget {
  const _RepairDetailsErrorState({required this.onRetry, required this.onBack});

  final VoidCallback onRetry;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Repair details could not be loaded.',
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
          Wrap(
            spacing: AppSpacing.xs,
            children: [
              SecondaryButton(label: 'Retry', onPressed: onRetry),
              GhostButton(
                label: 'Back to Repairs',
                icon: Icons.arrow_back,
                onPressed: onBack,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

List<Widget> _withExpandedSpacing(List<Widget> children, double spacing) {
  return [
    for (var index = 0; index < children.length; index++) ...[
      if (index > 0) SizedBox(width: spacing),
      Expanded(child: children[index]),
    ],
  ];
}

List<Widget> _withVerticalSpacing(List<Widget> children, double spacing) {
  return [
    for (var index = 0; index < children.length; index++) ...[
      if (index > 0) SizedBox(height: spacing),
      children[index],
    ],
  ];
}
