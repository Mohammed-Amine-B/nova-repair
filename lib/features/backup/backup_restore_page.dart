import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/widgets/buttons/app_buttons.dart';
import '../../app/widgets/empty_value_text.dart';
import '../../app/widgets/page_header.dart';
import '../../app/widgets/section_card.dart';
import 'domain/entities/backup_metadata.dart';
import 'presentation/backup_restore_controller.dart';
import 'presentation/backup_restore_state.dart';

class BackupRestorePage extends ConsumerWidget {
  const BackupRestorePage({
    required this.onBackToSettings,
    required this.onRestoreRequested,
    super.key,
  });

  final VoidCallback onBackToSettings;
  final ValueChanged<SelectedBackupFile> onRestoreRequested;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(backupDataSummaryProvider);
    final state = ref.watch(backupRestoreControllerProvider);
    final controller = ref.read(backupRestoreControllerProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: GhostButton(
                  key: const Key('backup-restore-back-to-settings'),
                  label: 'Back to Settings',
                  icon: Icons.arrow_back,
                  onPressed: onBackToSettings,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const PageHeader(
                title: 'Backup & Restore',
                subtitle: 'Protect and recover your Nova Repair data',
              ),
              const SizedBox(height: AppSpacing.xl),
              summary.when(
                data: (data) => _CurrentDataSection(summary: data),
                loading: () => const _CurrentDataLoadingSection(),
                error: (_, _) => _CurrentDataErrorSection(
                  onRetry: () => ref.invalidate(backupDataSummaryProvider),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              if (state.successMessage != null) ...[
                _MessageBanner.success(
                  message: state.successMessage!,
                  detail: state.lastBackup?.fileName,
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              if (state.errorMessage != null) ...[
                _MessageBanner.error(message: state.errorMessage!),
                const SizedBox(height: AppSpacing.md),
              ],
              _CreateBackupSection(
                state: state,
                onCreateBackup: controller.createBackup,
              ),
              const SizedBox(height: AppSpacing.xl),
              _RestoreBackupSection(
                state: state,
                onChooseBackup: controller.chooseBackupFile,
                onRestore: state.selectedBackup == null
                    ? null
                    : () => onRestoreRequested(state.selectedBackup!),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CurrentDataSection extends StatelessWidget {
  const _CurrentDataSection({required this.summary});

  final BackupDataSummary summary;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Current Data',
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          0,
          AppSpacing.xl,
          AppSpacing.xl,
        ),
        child: _SummaryGrid(
          children: [
            _SummaryMetric(
              label: 'Repairs',
              value: summary.repairCount.toString(),
            ),
            _SummaryMetric(
              label: 'Database Size',
              value: BackupRestoreFormatters.fileSize(
                summary.databaseSizeBytes,
              ),
            ),
            _SummaryMetric(
              label: 'Last Updated',
              value: BackupRestoreFormatters.dateTime(summary.lastUpdated),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrentDataLoadingSection extends StatelessWidget {
  const _CurrentDataLoadingSection();

  @override
  Widget build(BuildContext context) {
    return const SectionCard(
      title: 'Current Data',
      child: SizedBox(
        height: 80,
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _CurrentDataErrorSection extends StatelessWidget {
  const _CurrentDataErrorSection({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Current Data',
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.danger),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Current data summary could not be loaded.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          SecondaryButton(
            label: 'Retry',
            icon: Icons.refresh,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

class _CreateBackupSection extends StatelessWidget {
  const _CreateBackupSection({
    required this.state,
    required this.onCreateBackup,
  });

  final BackupRestoreState state;
  final VoidCallback onCreateBackup;

  @override
  Widget build(BuildContext context) {
    final lastBackup = state.lastBackup;

    return SectionCard(
      title: 'Create Backup',
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          0,
          AppSpacing.xl,
          AppSpacing.xl,
        ),
        child: _ActionLayout(
          icon: Icons.file_upload_outlined,
          iconBackground: AppColors.primarySoft,
          iconColor: AppColors.primary,
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create a local backup of all Nova Repair data',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'The backup includes repairs, settings, and application data.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _SessionBackupBox(lastBackup: lastBackup),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                key: const Key('backup-create-button'),
                label: 'Create Backup',
                icon: Icons.save_outlined,
                isLoading: state.isCreatingBackup,
                onPressed: state.isCreatingBackup ? null : onCreateBackup,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RestoreBackupSection extends StatelessWidget {
  const _RestoreBackupSection({
    required this.state,
    required this.onChooseBackup,
    required this.onRestore,
  });

  final BackupRestoreState state;
  final VoidCallback onChooseBackup;
  final VoidCallback? onRestore;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Restore Backup',
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          0,
          AppSpacing.xl,
          AppSpacing.xl,
        ),
        child: _ActionLayout(
          icon: Icons.restore_outlined,
          iconBackground: AppColors.softSurface,
          iconColor: AppColors.textSecondary,
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Restore Nova Repair data from a previous backup file',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Select a valid backup file from your local storage to begin the restoration process.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SecondaryButton(
                key: const Key('backup-choose-file-button'),
                label: 'Choose Backup File',
                icon: Icons.file_open_outlined,
                isLoading: state.isSelectingBackup,
                onPressed: state.isSelectingBackup ? null : onChooseBackup,
              ),
              const SizedBox(height: AppSpacing.md),
              _SelectedBackupDisplay(selectedBackup: state.selectedBackup),
              const SizedBox(height: AppSpacing.xl),
              const _RestoreWarning(),
              const SizedBox(height: AppSpacing.xl),
              SecondaryButton(
                key: const Key('backup-restore-button'),
                label: 'Restore Backup',
                icon: Icons.restore,
                onPressed: onRestore,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SessionBackupBox extends StatelessWidget {
  const _SessionBackupBox({required this.lastBackup});

  final BackupMetadata? lastBackup;

  @override
  Widget build(BuildContext context) {
    final backup = lastBackup;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borderStrong),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.verified_user_outlined,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: backup == null
                ? const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Last Backup: No backup created in this session'),
                      EmptyValueText(),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Last Backup: ${BackupRestoreFormatters.dateTime(backup.createdAt)}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        backup.fileName,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontFamily: 'monospace',
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

class _SelectedBackupDisplay extends StatelessWidget {
  const _SelectedBackupDisplay({required this.selectedBackup});

  final SelectedBackupFile? selectedBackup;

  @override
  Widget build(BuildContext context) {
    final backup = selectedBackup;
    if (backup == null) {
      return Text(
        'No backup file selected',
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
      );
    }

    return Row(
      children: [
        const Icon(Icons.check_circle, color: AppColors.primary, size: 18),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            'Selected: ${backup.fileName}',
            key: const Key('backup-selected-file-name'),
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _RestoreWarning extends StatelessWidget {
  const _RestoreWarning();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        border: Border.all(color: const Color(0xFFFDE68A)),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_outlined, color: Color(0xFF92400E)),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Restoring a backup will replace the current Nova Repair data.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'Create a new backup first if you may need to return to the current data.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
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

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 720 ? 1 : 3;
        return GridView.count(
          crossAxisCount: columns,
          childAspectRatio: columns == 1 ? 6 : 3,
          crossAxisSpacing: AppSpacing.lg,
          mainAxisSpacing: AppSpacing.md,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: children,
        );
      },
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          value,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _ActionLayout extends StatelessWidget {
  const _ActionLayout({
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.content,
  });

  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final Widget content;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: iconBackground,
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          child: Icon(icon, color: iconColor, size: 32),
        ),
        const SizedBox(width: AppSpacing.xl),
        Expanded(child: content),
      ],
    );
  }
}

class _MessageBanner extends StatelessWidget {
  const _MessageBanner._({
    required this.message,
    required this.color,
    required this.background,
    required this.icon,
    this.detail,
  });

  factory _MessageBanner.success({required String message, String? detail}) {
    return _MessageBanner._(
      message: message,
      detail: detail,
      color: AppColors.success,
      background: const Color(0xFFF0FDF4),
      icon: Icons.check_circle_outline,
    );
  }

  factory _MessageBanner.error({required String message}) {
    return _MessageBanner._(
      message: message,
      color: AppColors.danger,
      background: AppColors.dangerSoft,
      icon: Icons.error_outline,
    );
  }

  final String message;
  final String? detail;
  final Color color;
  final Color background;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: color.withValues(alpha: 0.24)),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (detail != null)
                  Text(
                    detail!,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
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

class BackupRestoreFormatters {
  const BackupRestoreFormatters._();

  static String fileSize(int bytes) {
    const units = ['B', 'KB', 'MB', 'GB'];
    var value = bytes.toDouble();
    var unitIndex = 0;

    while (value >= 1024 && unitIndex < units.length - 1) {
      value /= 1024;
      unitIndex++;
    }

    if (unitIndex == 0) {
      return '$bytes B';
    }
    return '${value.toStringAsFixed(value >= 10 ? 0 : 1)} ${units[unitIndex]}';
  }

  static String dateTime(DateTime? value) {
    if (value == null) {
      return '—';
    }

    final local = value.toLocal();
    return '${_two(local.day)} ${_month(local.month)} ${local.year}, '
        '${_two(local.hour)}:${_two(local.minute)}';
  }

  static String _month(int month) {
    return const [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ][month - 1];
  }

  static String _two(int value) => value.toString().padLeft(2, '0');
}
