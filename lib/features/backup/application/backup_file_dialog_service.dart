import 'package:file_selector/file_selector.dart';

class BackupFileDialogService {
  const BackupFileDialogService();

  static const _backupTypeGroup = XTypeGroup(
    label: 'Nova Repair backups',
    extensions: ['nrbackup', 'sqlite'],
  );

  Future<String?> chooseBackupSavePath({required String suggestedName}) async {
    final location = await getSaveLocation(
      suggestedName: suggestedName,
      acceptedTypeGroups: const [_backupTypeGroup],
    );

    return location?.path;
  }

  Future<String?> chooseBackupOpenPath() async {
    final file = await openFile(acceptedTypeGroups: const [_backupTypeGroup]);

    return file?.path;
  }
}
