import '../domain/entities/backup_metadata.dart';

class BackupDataSummary {
  const BackupDataSummary({
    required this.repairCount,
    required this.databaseSizeBytes,
    required this.lastUpdated,
  });

  final int repairCount;
  final int databaseSizeBytes;
  final DateTime? lastUpdated;
}

class SelectedBackupFile {
  const SelectedBackupFile({
    required this.filePath,
    required this.fileName,
    required this.metadata,
  });

  final String filePath;
  final String fileName;
  final BackupMetadata metadata;
}

class BackupRestoreState {
  const BackupRestoreState({
    this.isCreatingBackup = false,
    this.isSelectingBackup = false,
    this.lastBackup,
    this.selectedBackup,
    this.successMessage,
    this.errorMessage,
  });

  final bool isCreatingBackup;
  final bool isSelectingBackup;
  final BackupMetadata? lastBackup;
  final SelectedBackupFile? selectedBackup;
  final String? successMessage;
  final String? errorMessage;

  BackupRestoreState copyWith({
    bool? isCreatingBackup,
    bool? isSelectingBackup,
    BackupMetadata? lastBackup,
    SelectedBackupFile? selectedBackup,
    bool clearSelectedBackup = false,
    String? successMessage,
    bool clearSuccessMessage = false,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return BackupRestoreState(
      isCreatingBackup: isCreatingBackup ?? this.isCreatingBackup,
      isSelectingBackup: isSelectingBackup ?? this.isSelectingBackup,
      lastBackup: lastBackup ?? this.lastBackup,
      selectedBackup: clearSelectedBackup
          ? null
          : selectedBackup ?? this.selectedBackup,
      successMessage: clearSuccessMessage
          ? null
          : successMessage ?? this.successMessage,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
    );
  }
}
