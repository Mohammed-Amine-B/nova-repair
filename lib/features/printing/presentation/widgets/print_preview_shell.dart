import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/widgets/buttons/app_buttons.dart';
import '../print_document_mode.dart';

class PrintPreviewShell extends StatelessWidget {
  const PrintPreviewShell({
    required this.repairCode,
    required this.documentMode,
    required this.copies,
    required this.printerLabel,
    required this.onBack,
    required this.onModeSelected,
    required this.onIncrementCopies,
    required this.onDecrementCopies,
    required this.onPrint,
    required this.preview,
    required this.isSubmitting,
    this.successMessage,
    this.errorMessage,
    super.key,
  });

  final String repairCode;
  final PrintDocumentMode documentMode;
  final int copies;
  final String printerLabel;
  final VoidCallback onBack;
  final ValueChanged<PrintDocumentMode> onModeSelected;
  final VoidCallback onIncrementCopies;
  final VoidCallback onDecrementCopies;
  final VoidCallback onPrint;
  final Widget preview;
  final bool isSubmitting;
  final String? successMessage;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Back',
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back),
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Print Preview',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Review and print documents for $repairCode',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: Row(
            children: [
              _ControlsPanel(
                documentMode: documentMode,
                copies: copies,
                printerLabel: printerLabel,
                isSubmitting: isSubmitting,
                successMessage: successMessage,
                errorMessage: errorMessage,
                onModeSelected: onModeSelected,
                onIncrementCopies: onIncrementCopies,
                onDecrementCopies: onDecrementCopies,
                onBack: onBack,
                onPrint: onPrint,
              ),
              Expanded(
                child: _PreviewWorkspace(
                  documentMode: documentMode,
                  preview: preview,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ControlsPanel extends StatelessWidget {
  const _ControlsPanel({
    required this.documentMode,
    required this.copies,
    required this.printerLabel,
    required this.onModeSelected,
    required this.onIncrementCopies,
    required this.onDecrementCopies,
    required this.onBack,
    required this.onPrint,
    required this.isSubmitting,
    this.successMessage,
    this.errorMessage,
  });

  final PrintDocumentMode documentMode;
  final int copies;
  final String printerLabel;
  final ValueChanged<PrintDocumentMode> onModeSelected;
  final VoidCallback onIncrementCopies;
  final VoidCallback onDecrementCopies;
  final VoidCallback onBack;
  final VoidCallback onPrint;
  final bool isSubmitting;
  final String? successMessage;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _PanelHeading('Document'),
                  for (final mode in PrintDocumentMode.values) ...[
                    _DocumentModeOption(
                      mode: mode,
                      selected: mode == documentMode,
                      onTap: () => onModeSelected(mode),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  const _PanelHeading('Print Settings'),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Copies',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      _CopiesControl(
                        copies: copies,
                        onIncrement: onIncrementCopies,
                        onDecrement: onDecrementCopies,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _ReadOnlySetting(label: 'Printer', value: printerLabel),
                  const SizedBox(height: AppSpacing.lg),
                  _ReadOnlySetting(
                    label: 'Paper Size',
                    value: documentMode.paperLabel,
                  ),
                  if (successMessage != null) ...[
                    const SizedBox(height: AppSpacing.lg),
                    _InfoMessage(
                      message: successMessage!,
                      color: AppColors.success,
                      icon: Icons.check_circle_outline,
                    ),
                  ],
                  if (errorMessage != null) ...[
                    const SizedBox(height: AppSpacing.lg),
                    _InfoMessage(
                      message: errorMessage!,
                      color: AppColors.danger,
                      icon: Icons.error_outline,
                    ),
                  ],
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SecondaryButton(label: 'Back', onPressed: onBack),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: PrimaryButton(
                    label: 'Print',
                    icon: Icons.print_outlined,
                    isLoading: isSubmitting,
                    onPressed: isSubmitting ? null : onPrint,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewWorkspace extends StatelessWidget {
  const _PreviewWorkspace({required this.documentMode, required this.preview});

  final PrintDocumentMode documentMode;
  final Widget preview;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.primarySoft,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.lg),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.softSurface,
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xxs),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final mode in PrintDocumentMode.values)
                      _PreviewTab(mode: mode, selected: mode == documentMode),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Center(child: preview),
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentModeOption extends StatelessWidget {
  const _DocumentModeOption({
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  final PrintDocumentMode mode;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.control),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySoft : AppColors.surface,
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.borderStrong,
          ),
          borderRadius: BorderRadius.circular(AppRadius.control),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mode.label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    mode.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_circle_outline,
                color: AppColors.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

class _CopiesControl extends StatelessWidget {
  const _CopiesControl({
    required this.copies,
    required this.onIncrement,
    required this.onDecrement,
  });

  final int copies;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borderStrong),
        borderRadius: BorderRadius.circular(AppRadius.control),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Decrease copies',
            constraints: const BoxConstraints.tightFor(width: 36, height: 32),
            padding: EdgeInsets.zero,
            onPressed: onDecrement,
            icon: const Icon(Icons.remove, size: 16),
          ),
          Container(
            width: 42,
            height: 32,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              border: Border.symmetric(
                vertical: BorderSide(color: AppColors.borderStrong),
              ),
            ),
            child: Text(
              copies.toString(),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(
            tooltip: 'Increase copies',
            constraints: const BoxConstraints.tightFor(width: 36, height: 32),
            padding: EdgeInsets.zero,
            onPressed: onIncrement,
            icon: const Icon(Icons.add, size: 16),
          ),
        ],
      ),
    );
  }
}

class _ReadOnlySetting extends StatelessWidget {
  const _ReadOnlySetting({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PanelHeading(label),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            border: Border.all(color: AppColors.borderStrong),
            borderRadius: BorderRadius.circular(AppRadius.control),
          ),
          child: Text(value),
        ),
      ],
    );
  }
}

class _PreviewTab extends StatelessWidget {
  const _PreviewTab({required this.mode, required this.selected});

  final PrintDocumentMode mode;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: selected ? AppColors.surface : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.control),
      ),
      child: Text(
        mode.label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: selected ? AppColors.primary : AppColors.textSecondary,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }
}

class _InfoMessage extends StatelessWidget {
  const _InfoMessage({
    required this.message,
    required this.color,
    required this.icon,
  });

  final String message;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(AppRadius.control),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PanelHeading extends StatelessWidget {
  const _PanelHeading(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
