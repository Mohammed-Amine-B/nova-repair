import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../database/database_provider.dart';
import 'application/local_backup_service.dart';
import 'infrastructure/backup_validator.dart';

final backupValidatorProvider = Provider<BackupValidator>((ref) {
  return const BackupValidator();
});

final localBackupServiceProvider = Provider<LocalBackupService>((ref) {
  return LocalBackupService(
    ref.watch(databaseLifecycleManagerProvider),
    ref.watch(backupValidatorProvider),
  );
});
