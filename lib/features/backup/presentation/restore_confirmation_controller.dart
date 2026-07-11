import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../backup_providers.dart';
import '../domain/errors/backup_exception.dart';
import 'backup_restore_state.dart';
import 'restore_confirmation_state.dart';

final restoreConfirmationControllerProvider =
    NotifierProvider.autoDispose<
      RestoreConfirmationController,
      RestoreConfirmationState
    >(RestoreConfirmationController.new);

class RestoreConfirmationController extends Notifier<RestoreConfirmationState> {
  @override
  RestoreConfirmationState build() {
    return const RestoreConfirmationState();
  }

  Future<bool> restore(SelectedBackupFile backup) async {
    if (state.isRestoring) {
      return false;
    }

    state = state.copyWith(isRestoring: true, clearErrorMessage: true);

    try {
      await ref.read(localBackupServiceProvider).restoreBackup(backup.filePath);
      state = state.copyWith(isRestoring: false, clearErrorMessage: true);
      return true;
    } on RestoreRollbackException {
      state = state.copyWith(
        isRestoring: false,
        errorMessage: 'Backup could not be restored. Please try again.',
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        isRestoring: false,
        errorMessage:
            'Backup could not be restored. Your previous data has been kept.',
      );
      return false;
    }
  }
}
