import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/widgets/buttons/app_buttons.dart';
import '../../../app/widgets/section_card.dart';
import '../../repairs/domain/errors/repair_status_workflow_exception.dart';
import 'print_document_mode.dart';
import 'print_preview_controller.dart';
import 'widgets/customer_ticket_preview.dart';
import 'widgets/device_label_preview.dart';
import 'widgets/print_preview_shell.dart';

class PrintPreviewPage extends ConsumerWidget {
  const PrintPreviewPage({
    required this.repairId,
    required this.initialMode,
    required this.onBack,
    super.key,
  });

  final int repairId;
  final PrintDocumentMode initialMode;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final previewState = ref.watch(printPreviewControllerProvider(initialMode));
    final controller = ref.read(
      printPreviewControllerProvider(initialMode).notifier,
    );
    final data = ref.watch(printPreviewDataProvider(repairId));
    final printerDisplay = ref.watch(
      printPreviewPrinterDisplayProvider(previewState.documentMode),
    );

    return data.when(
      data: (loaded) {
        final printData = loaded.printData;
        final repairCode = printData.customerTicket.repairCode;
        final preview = switch (previewState.documentMode) {
          PrintDocumentMode.customerTicket => CustomerTicketPreview(
            ticket: printData.customerTicket,
            qrCode: loaded.customerTicketQrCode,
          ),
          PrintDocumentMode.deviceLabel => DeviceLabelPreview(
            label: printData.deviceLabel,
            ticket: printData.customerTicket,
            qrCode: loaded.deviceLabelQrCode,
          ),
        };

        return PrintPreviewShell(
          repairCode: repairCode,
          documentMode: previewState.documentMode,
          copies: previewState.copies,
          printerLabel: printerDisplay.maybeWhen(
            data: (display) => display.label,
            error: (_, _) => 'Unavailable printer',
            orElse: () => 'Default Printer',
          ),
          isSubmitting: previewState.isSubmitting,
          successMessage: previewState.successMessage,
          errorMessage: previewState.errorMessage,
          onBack: onBack,
          onModeSelected: controller.selectMode,
          onIncrementCopies: controller.incrementCopies,
          onDecrementCopies: controller.decrementCopies,
          onPrint: () {
            controller.submitPrint(repairId);
          },
          preview: preview,
        );
      },
      loading: () => _PrintPreviewLoadingState(onBack: onBack),
      error: (error, stackTrace) {
        if (error is RepairNotFoundException) {
          return _PrintPreviewSimpleState(
            title: 'Repair not found',
            message: 'The repair could not be found.',
            onBack: onBack,
          );
        }

        return _PrintPreviewSimpleState(
          title: 'Print data could not be loaded',
          message: 'Try again or return to the repair details.',
          onBack: onBack,
          onRetry: () {
            ref.invalidate(printPreviewDataProvider(repairId));
          },
        );
      },
    );
  }
}

class _PrintPreviewLoadingState extends StatelessWidget {
  const _PrintPreviewLoadingState({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PrintPreviewHeader(repairCode: 'Loading', onBack: onBack),
        const Expanded(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.xxl),
            child: SectionCard(
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
        ),
      ],
    );
  }
}

class _PrintPreviewSimpleState extends StatelessWidget {
  const _PrintPreviewSimpleState({
    required this.title,
    required this.message,
    required this.onBack,
    this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback onBack;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PrintPreviewHeader(repairCode: 'Unavailable', onBack: onBack),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: SectionCard(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      message,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.xs,
                      children: [
                        if (onRetry != null)
                          SecondaryButton(
                            label: 'Retry',
                            icon: Icons.refresh,
                            onPressed: onRetry,
                          ),
                        GhostButton(
                          label: 'Back',
                          icon: Icons.arrow_back,
                          onPressed: onBack,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PrintPreviewHeader extends StatelessWidget {
  const _PrintPreviewHeader({required this.repairCode, required this.onBack});

  final String repairCode;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
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
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(
                'Review and print documents for $repairCode',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
