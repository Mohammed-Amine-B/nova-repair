import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../../database/database_provider.dart';
import '../../repairs/repair_providers.dart';
import '../../settings/settings_providers.dart';
import '../application/backup_file_dialog_service.dart';
import '../backup_providers.dart';
import 'backup_restore_state.dart';

final backupRestoreClockProvider = Provider<DateTime Function()>((ref) {
  return DateTime.now;
});

final backupFileDialogServiceProvider = Provider<BackupFileDialogService>((
  ref,
) {
  return const BackupFileDialogService();
});

final backupDataSummaryProvider = FutureProvider.autoDispose<BackupDataSummary>(
  (ref) async {
    final repairRepository = ref.watch(repairRepositoryProvider);
    final settingsRepository = ref.watch(shopSettingsRepositoryProvider);
    final databaseFile = await ref
        .watch(databaseLifecycleManagerProvider)
        .resolveDatabaseFile();

    final repairCount = await repairRepository.getRepairCount();
    final latestRepairUpdatedAt = await repairRepository
        .getLatestRepairUpdatedAt();
    final settings = await settingsRepository.getSettings();
    final databaseStat = await (() async {
      if (!await databaseFile.exists()) {
        return null;
      }
      return databaseFile.stat();
    })();

    final lastUpdated = _latestDateTime([
      latestRepairUpdatedAt,
      settings.updatedAt,
      databaseStat?.modified,
    ]);

    return BackupDataSummary(
      repairCount: repairCount,
      databaseSizeBytes: databaseStat?.size ?? 0,
      lastUpdated: lastUpdated,
    );
  },
);

final backupRestoreControllerProvider =
    NotifierProvider.autoDispose<BackupRestoreController, BackupRestoreState>(
      BackupRestoreController.new,
    );

class BackupRestoreController extends Notifier<BackupRestoreState> {
  @override
  BackupRestoreState build() {
    return const BackupRestoreState();
  }

  String suggestedBackupFileName() {
    final now = ref.read(backupRestoreClockProvider)().toLocal();
    return 'NovaRepair_Backup_${_four(now.year)}-${_two(now.month)}-'
        '${_two(now.day)}.nrbackup';
  }

  Future<void> createBackup() async {
    if (state.isCreatingBackup) {
      return;
    }

    state = state.copyWith(
      isCreatingBackup: true,
      clearSuccessMessage: true,
      clearErrorMessage: true,
    );

    try {
      final destinationPath = await ref
          .read(backupFileDialogServiceProvider)
          .chooseBackupSavePath(suggestedName: suggestedBackupFileName());

      if (destinationPath == null) {
        state = state.copyWith(isCreatingBackup: false);
        return;
      }

      final metadata = await ref
          .read(localBackupServiceProvider)
          .createBackupFile(destinationPath);

      state = state.copyWith(
        isCreatingBackup: false,
        lastBackup: metadata,
        successMessage: 'Backup created successfully.',
      );
    } catch (_) {
      state = state.copyWith(
        isCreatingBackup: false,
        errorMessage: 'Backup could not be created. Please try again.',
      );
    }
  }

  Future<void> chooseBackupFile() async {
    if (state.isSelectingBackup) {
      return;
    }

    state = state.copyWith(
      isSelectingBackup: true,
      clearSuccessMessage: true,
      clearErrorMessage: true,
    );

    try {
      final selectedPath = await ref
          .read(backupFileDialogServiceProvider)
          .chooseBackupOpenPath();

      if (selectedPath == null) {
        state = state.copyWith(isSelectingBackup: false);
        return;
      }

      final metadata = await ref
          .read(localBackupServiceProvider)
          .validateBackup(selectedPath);

      state = state.copyWith(
        isSelectingBackup: false,
        selectedBackup: SelectedBackupFile(
          filePath: selectedPath,
          fileName: p.basename(selectedPath),
          metadata: metadata,
        ),
      );
    } catch (_) {
      state = state.copyWith(
        isSelectingBackup: false,
        clearSelectedBackup: true,
        errorMessage: 'The selected backup file is not valid.',
      );
    }
  }

  void clearSelectedBackupAfterRestore() {
    state = state.copyWith(
      clearSelectedBackup: true,
      successMessage: 'Backup restored successfully.',
      clearErrorMessage: true,
    );
  }
}

DateTime? _latestDateTime(Iterable<DateTime?> values) {
  DateTime? latest;
  for (final value in values) {
    if (value == null) {
      continue;
    }
    final utcValue = value.toUtc();
    if (latest == null || utcValue.isAfter(latest)) {
      latest = utcValue;
    }
  }
  return latest;
}

String _four(int value) => value.toString().padLeft(4, '0');

String _two(int value) => value.toString().padLeft(2, '0');
