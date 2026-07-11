import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/widgets/buttons/app_buttons.dart';
import '../../app/widgets/form/app_text_field.dart';
import '../../app/widgets/status_badge.dart';
import 'domain/entities/repair.dart';
import 'domain/repair_status.dart';
import 'domain/services/device_display_name_formatter.dart';
import 'presentation/change_status_dialog_controller.dart';
import 'presentation/repair_status_option_presentation.dart';

Future<Repair?> showChangeStatusDialog({
  required BuildContext context,
  required Repair repair,
}) {
  return showDialog<Repair>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.56),
    builder: (context) => ChangeStatusDialog(repair: repair),
  );
}

class ChangeStatusDialog extends ConsumerStatefulWidget {
  const ChangeStatusDialog({required this.repair, super.key});

  final Repair repair;

  @override
  ConsumerState<ChangeStatusDialog> createState() => _ChangeStatusDialogState();
}

class _ChangeStatusDialogState extends ConsumerState<ChangeStatusDialog> {
  late final TextEditingController _customerMessageController;

  @override
  void initState() {
    super.initState();
    _customerMessageController = TextEditingController(
      text: widget.repair.customerMessage ?? '',
    );
  }

  @override
  void dispose() {
    _customerMessageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = changeStatusDialogControllerProvider(widget.repair);
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);
    const deviceFormatter = DeviceDisplayNameFormatter();
    final deviceDisplay = deviceFormatter.format(
      brand: widget.repair.brand,
      model: widget.repair.model,
      deviceType: widget.repair.deviceType,
    );

    return Dialog(
      insetPadding: const EdgeInsets.all(AppSpacing.xxl),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 760),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.dialog),
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x26000000),
                blurRadius: 24,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _DialogHeader(
                repair: widget.repair,
                deviceDisplay: deviceDisplay,
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _CurrentStatusPanel(status: widget.repair.status),
                      const SizedBox(height: AppSpacing.xl),
                      Text(
                        'Select New Status'.toUpperCase(),
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      for (final option in repairStatusOptionPresentations) ...[
                        StatusOptionTile(
                          status: option.status,
                          description: option.description,
                          isCurrent: option.status == widget.repair.status,
                          isSelected: option.status == state.selectedStatus,
                          isEnabled: controller.isSelectable(option.status),
                          onTap: () => controller.selectStatus(option.status),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                      ],
                      const SizedBox(height: AppSpacing.md),
                      AppTextArea(
                        key: const Key('change-status-customer-message'),
                        label: 'Customer Message',
                        helperText:
                            'This may later be shown to the customer in repair tracking',
                        controller: _customerMessageController,
                        onChanged: controller.updateCustomerMessage,
                        enabled: !state.isSubmitting,
                        minLines: 3,
                      ),
                      if (state.submissionError != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        _InlineError(message: state.submissionError!),
                      ],
                    ],
                  ),
                ),
              ),
              _DialogFooter(
                canSubmit: state.canSubmit,
                isSubmitting: state.isSubmitting,
                onCancel: () => Navigator.of(context).pop(),
                onSubmit: () async {
                  final updatedRepair = await controller.submit();
                  if (!context.mounted || updatedRepair == null) {
                    return;
                  }

                  Navigator.of(context).pop(updatedRepair);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DialogHeader extends StatelessWidget {
  const _DialogHeader({required this.repair, required this.deviceDisplay});

  final Repair repair;
  final String deviceDisplay;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Change Repair Status',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    '${repair.repairCode} — $deviceDisplay',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Close',
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrentStatusPanel extends StatelessWidget {
  const _CurrentStatusPanel({required this.status});

  final RepairStatus status;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Current Status'.toUpperCase(),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            StatusBadge(status: status),
          ],
        ),
      ),
    );
  }
}

class StatusOptionTile extends StatelessWidget {
  const StatusOptionTile({
    required this.status,
    required this.description,
    required this.isCurrent,
    required this.isSelected,
    required this.isEnabled,
    required this.onTap,
    super.key,
  });

  final RepairStatus status;
  final String description;
  final bool isCurrent;
  final bool isSelected;
  final bool isEnabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.status(status);
    final effectiveForeground = isSelected
        ? colors.foreground
        : isEnabled
        ? AppColors.textPrimary
        : AppColors.textMuted;
    final effectiveDescriptionColor = isSelected
        ? colors.foreground.withValues(alpha: 0.78)
        : isEnabled
        ? AppColors.textSecondary
        : AppColors.textMuted;

    return Semantics(
      button: isEnabled,
      enabled: isEnabled,
      selected: isSelected,
      label: status.displayLabel,
      child: InkWell(
        key: Key('status-option-${status.databaseValue}'),
        onTap: isEnabled ? onTap : null,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isSelected
                ? colors.background
                : isCurrent || !isEnabled
                ? AppColors.softSurface
                : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: isSelected ? colors.foreground : AppColors.borderStrong,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Opacity(
            opacity: isEnabled || isCurrent ? 1 : 0.62,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StatusOptionIndicator(colors: colors, isSelected: isSelected),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              status.displayLabel,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: effectiveForeground,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ),
                          if (isCurrent)
                            Text(
                              'Current'.toUpperCase(),
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: effectiveDescriptionColor,
                        ),
                      ),
                    ],
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

class _StatusOptionIndicator extends StatelessWidget {
  const _StatusOptionIndicator({
    required this.colors,
    required this.isSelected,
  });

  final StatusBadgeColors colors;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    if (isSelected) {
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: colors.foreground,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: const Icon(Icons.check, color: AppColors.surface, size: 16),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: colors.foreground.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.dangerSoft,
        borderRadius: BorderRadius.circular(AppRadius.control),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.24)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline, color: AppColors.danger, size: 18),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.danger,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DialogFooter extends StatelessWidget {
  const _DialogFooter({
    required this.canSubmit,
    required this.isSubmitting,
    required this.onCancel,
    required this.onSubmit,
  });

  final bool canSubmit;
  final bool isSubmitting;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.softSurface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            GhostButton(
              label: 'Cancel',
              onPressed: isSubmitting ? null : onCancel,
            ),
            const SizedBox(width: AppSpacing.xs),
            PrimaryButton(
              key: const Key('change-status-submit'),
              label: 'Update Status',
              icon: Icons.sync,
              isLoading: isSubmitting,
              onPressed: canSubmit ? onSubmit : null,
            ),
          ],
        ),
      ),
    );
  }
}
