import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/widgets/buttons/app_buttons.dart';
import 'presentation/backup_restore_state.dart';
import 'presentation/restore_confirmation_controller.dart';

Future<bool> showRestoreConfirmationDialog({
  required BuildContext context,
  required SelectedBackupFile backup,
}) async {
  final restored = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => RestoreConfirmationDialog(backup: backup),
  );

  return restored ?? false;
}

class RestoreConfirmationDialog extends ConsumerWidget {
  const RestoreConfirmationDialog({required this.backup, super.key});

  final SelectedBackupFile backup;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(restoreConfirmationControllerProvider);
    final controller = ref.read(restoreConfirmationControllerProvider.notifier);
    final theme = Theme.of(context);

    return PopScope(
      canPop: !state.isRestoring,
      child: Dialog(
        insetPadding: const EdgeInsets.all(AppSpacing.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.dialog),
              border: Border.all(color: AppColors.border),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 24,
                  offset: Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.dangerSoft,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: const Icon(
                          Icons.warning_amber_rounded,
                          color: AppColors.danger,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Restore Backup?',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xxs),
                            Text(
                              'Current Nova Repair data will be replaced',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        key: const Key('restore-confirmation-close-button'),
                        tooltip: 'Close',
                        onPressed: state.isRestoring
                            ? null
                            : () => Navigator.of(context).pop(false),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    0,
                    AppSpacing.xl,
                    AppSpacing.xl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _BackupFileSummary(fileName: backup.fileName),
                      const SizedBox(height: AppSpacing.md),
                      const _RestoreWarningBlock(),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Create a new backup first if you may need to return to the current data.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      if (state.errorMessage != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        _RestoreError(message: state.errorMessage!),
                      ],
                    ],
                  ),
                ),
                DecoratedBox(
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
                          key: const Key('restore-confirmation-cancel-button'),
                          label: 'Cancel',
                          onPressed: state.isRestoring
                              ? null
                              : () => Navigator.of(context).pop(false),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        ElevatedButton(
                          key: const Key('restore-confirmation-submit-button'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.danger,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: state.isRestoring
                              ? null
                              : () async {
                                  final restored = await controller.restore(
                                    backup,
                                  );
                                  if (restored && context.mounted) {
                                    Navigator.of(context).pop(true);
                                  }
                                },
                          child: state.isRestoring
                              ? const _RestoringButtonContent()
                              : const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.restore, size: 18),
                                    SizedBox(width: AppSpacing.xs),
                                    Text('Restore Data'),
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
        ),
      ),
    );
  }
}

class _BackupFileSummary extends StatelessWidget {
  const _BackupFileSummary({required this.fileName});

  final String fileName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.softSurface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Backup File',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              const Icon(
                Icons.description_outlined,
                color: AppColors.textSecondary,
                size: 18,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  fileName,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RestoreWarningBlock extends StatelessWidget {
  const _RestoreWarningBlock();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.dangerSoft,
        border: Border.all(color: const Color(0xFFFECACA)),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.report_problem_outlined, color: AppColors.danger),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Restoring this backup will replace the current Nova Repair data.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF991B1B),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'This action cannot be undone.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF991B1B),
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

class _RestoreError extends StatelessWidget {
  const _RestoreError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.dangerSoft,
        border: Border.all(color: const Color(0xFFFECACA)),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.danger,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _RestoringButtonContent extends StatelessWidget {
  const _RestoringButtonContent();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox.square(
          dimension: 16,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        ),
        SizedBox(width: AppSpacing.xs),
        Text('Restoring...'),
      ],
    );
  }
}
