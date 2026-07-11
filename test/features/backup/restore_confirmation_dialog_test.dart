import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_repair/app/app_shell.dart';
import 'package:nova_repair/app/theme/app_theme.dart';
import 'package:nova_repair/database/app_database.dart';
import 'package:nova_repair/database/database_lifecycle_manager.dart';
import 'package:nova_repair/database/database_provider.dart';
import 'package:nova_repair/features/backup/application/backup_file_dialog_service.dart';
import 'package:nova_repair/features/backup/application/local_backup_service.dart';
import 'package:nova_repair/features/backup/backup_providers.dart';
import 'package:nova_repair/features/backup/domain/entities/backup_metadata.dart';
import 'package:nova_repair/features/backup/infrastructure/backup_validator.dart';
import 'package:nova_repair/features/backup/presentation/backup_restore_controller.dart';
import 'package:nova_repair/features/backup/presentation/backup_restore_state.dart';
import 'package:nova_repair/features/backup/restore_confirmation_dialog.dart';
import 'package:nova_repair/features/printing/application/local_printer_service.dart';
import 'package:nova_repair/features/printing/application/print_printer_target.dart';
import 'package:nova_repair/features/printing/application/rendered_print_document.dart';
import 'package:nova_repair/features/printing/domain/entities/local_printer.dart';
import 'package:nova_repair/features/printing/domain/entities/print_result.dart';
import 'package:nova_repair/features/printing/printing_providers.dart';
import 'package:nova_repair/features/repairs/data/datasources/repair_code_sequence_local_data_source.dart';
import 'package:nova_repair/features/repairs/data/datasources/repair_local_data_source.dart';
import 'package:nova_repair/features/repairs/data/repositories/drift_repair_repository.dart';
import 'package:nova_repair/features/repairs/domain/entities/create_repair_input.dart';
import 'package:nova_repair/features/repairs/repair_providers.dart';
import 'package:nova_repair/features/settings/data/datasources/shop_settings_local_data_source.dart';
import 'package:nova_repair/features/settings/data/repositories/drift_shop_settings_repository.dart';
import 'package:nova_repair/features/settings/settings_providers.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tempDirectory;
  late File databaseFile;
  late DatabaseLifecycleManager lifecycleManager;
  late SelectedBackupFile selectedBackup;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp(
      'nova_repair_restore_dialog_test_',
    );
    databaseFile = File('${tempDirectory.path}/nova_repair.sqlite');
    lifecycleManager = _lifecycleManager(databaseFile);
    selectedBackup = _selectedBackup(
      '${tempDirectory.path}/Selected_Backup.nrbackup',
    );
  });

  tearDown(() async {
    await lifecycleManager.closeCurrentDatabase();
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  testWidgets('dialog renders approved content with basename only', (
    tester,
  ) async {
    await _setDesktopSurface(tester);

    await tester.pumpWidget(
      _dialogApp(
        lifecycleManager: lifecycleManager,
        backup: selectedBackup,
        backupService: _FakeRestoreBackupService(lifecycleManager),
      ),
    );
    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();

    expect(find.text('Restore Backup?'), findsOneWidget);
    expect(
      find.text('Current Nova Repair data will be replaced'),
      findsOneWidget,
    );
    expect(find.text('Backup File'), findsOneWidget);
    expect(find.text('Selected_Backup.nrbackup'), findsOneWidget);
    expect(find.textContaining(tempDirectory.path), findsNothing);
    expect(
      find.text(
        'Restoring this backup will replace the current Nova Repair data.',
      ),
      findsOneWidget,
    );
    expect(find.text('This action cannot be undone.'), findsOneWidget);
    expect(
      find.text(
        'Create a new backup first if you may need to return to the current data.',
      ),
      findsOneWidget,
    );
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Restore Data'), findsOneWidget);
  });

  testWidgets('cancel closes dialog without restore call', (tester) async {
    await _setDesktopSurface(tester);
    final service = _FakeRestoreBackupService(lifecycleManager);

    await tester.pumpWidget(
      _dialogApp(
        lifecycleManager: lifecycleManager,
        backup: selectedBackup,
        backupService: service,
      ),
    );
    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const Key('restore-confirmation-cancel-button')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Restore Backup?'), findsNothing);
    expect(service.restoreCalls, 0);
  });

  testWidgets('restore submission prevents duplicates and disables dismissal', (
    tester,
  ) async {
    await _setDesktopSurface(tester);
    final service = _BlockingRestoreBackupService(lifecycleManager);

    await tester.pumpWidget(
      _dialogApp(
        lifecycleManager: lifecycleManager,
        backup: selectedBackup,
        backupService: service,
      ),
    );
    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const Key('restore-confirmation-submit-button')),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const Key('restore-confirmation-submit-button')),
      warnIfMissed: false,
    );
    await tester.tap(
      find.byKey(const Key('restore-confirmation-cancel-button')),
      warnIfMissed: false,
    );
    await tester.tap(
      find.byKey(const Key('restore-confirmation-close-button')),
      warnIfMissed: false,
    );
    await tester.pump();

    expect(service.restoreCalls, 1);
    expect(find.text('Restoring...'), findsOneWidget);
    expect(find.text('Restore Backup?'), findsOneWidget);

    service.complete();
    await tester.pumpAndSettle();

    expect(find.text('Restore Backup?'), findsNothing);
  });

  testWidgets('failure keeps dialog open with safe error and allows retry', (
    tester,
  ) async {
    await _setDesktopSurface(tester);
    final service = _FakeRestoreBackupService(
      lifecycleManager,
      failUntilCall: 1,
    );

    await tester.pumpWidget(
      _dialogApp(
        lifecycleManager: lifecycleManager,
        backup: selectedBackup,
        backupService: service,
      ),
    );
    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const Key('restore-confirmation-submit-button')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Restore Backup?'), findsOneWidget);
    expect(
      find.text(
        'Backup could not be restored. Your previous data has been kept.',
      ),
      findsOneWidget,
    );
    expect(find.text('Selected_Backup.nrbackup'), findsOneWidget);

    await tester.tap(
      find.byKey(const Key('restore-confirmation-submit-button')),
    );
    await tester.pumpAndSettle();

    expect(service.restoreCalls, 2);
    expect(find.text('Restore Backup?'), findsNothing);
  });

  testWidgets(
    'app shell restore success clears selection and stays on backup page',
    (tester) async {
      await _setDesktopSurface(tester);
      final service = _FakeRestoreBackupService(lifecycleManager);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseLifecycleManagerProvider.overrideWithValue(
              lifecycleManager,
            ),
            repairRepositoryProvider.overrideWithValue(
              _repairRepository(lifecycleManager),
            ),
            shopSettingsRepositoryProvider.overrideWithValue(
              _settingsRepository(lifecycleManager),
            ),
            localPrinterServiceProvider.overrideWithValue(
              const _EmptyLocalPrinterService(),
            ),
            backupDataSummaryProvider.overrideWith(
              (ref) async => const BackupDataSummary(
                repairCount: 0,
                databaseSizeBytes: 0,
                lastUpdated: null,
              ),
            ),
            backupFileDialogServiceProvider.overrideWithValue(
              _FakeBackupFileDialogService(openPath: selectedBackup.filePath),
            ),
            localBackupServiceProvider.overrideWithValue(service),
          ],
          child: MaterialApp(theme: AppTheme.light(), home: const AppShell()),
        ),
      );
      await _pumpUntilVisible(tester, find.text('Dashboard'));

      await tester.tap(find.text('Settings'));
      await _pumpUntilVisible(
        tester,
        find.byKey(const Key('settings-backup-restore-card')),
      );
      await tester.tap(find.byKey(const Key('settings-backup-restore-card')));
      await _pumpUntilVisible(tester, find.text('Backup & Restore'));
      await tester.tap(find.byKey(const Key('backup-choose-file-button')));
      await _pumpUntilVisible(
        tester,
        find.textContaining('Selected: Selected_Backup.nrbackup'),
      );
      await tester.ensureVisible(
        find.byKey(const Key('backup-restore-button')),
      );
      await tester.tap(find.byKey(const Key('backup-restore-button')));
      await tester.pumpAndSettle();

      expect(find.text('Restore Backup?'), findsOneWidget);
      await tester.tap(
        find.byKey(const Key('restore-confirmation-submit-button')),
      );
      await tester.pumpAndSettle();

      expect(service.restoreCalls, 1);
      expect(find.text('Restore Backup?'), findsNothing);
      expect(find.text('Backup & Restore'), findsOneWidget);
      expect(find.text('Backup restored successfully.'), findsOneWidget);
      expect(find.text('No backup file selected'), findsOneWidget);
      expect(
        find.byKey(const Key('nova-sidebar-item-settings-selected')),
        findsOneWidget,
      );
    },
  );

  test('real restore workflow restores active database and schema 7', () async {
    final repairRepository = _repairRepository(lifecycleManager);
    final settingsRepository = _settingsRepository(lifecycleManager);
    final backupService = LocalBackupService(
      lifecycleManager,
      const BackupValidator(),
      now: () => DateTime.utc(2026, 7, 6, 12),
    );

    await settingsRepository.saveSettings(
      (await settingsRepository.getSettings()).copyWith(
        shopName: 'Before Backup',
      ),
    );
    await repairRepository.createRepair(
      CreateRepairInput(reportedProblem: 'Backed up repair'),
    );
    final backup = await backupService.createBackupFile(
      '${tempDirectory.path}/real_restore.nrbackup',
    );

    await settingsRepository.saveSettings(
      (await settingsRepository.getSettings()).copyWith(
        shopName: 'After Backup',
      ),
    );
    await repairRepository.createRepair(
      CreateRepairInput(reportedProblem: 'Temporary repair'),
    );

    await backupService.restoreBackup(backup.filePath);

    expect(await _liveRepairCount(lifecycleManager), 1);
    expect(await _liveShopName(lifecycleManager), 'Before Backup');
    final version = await lifecycleManager.database
        .customSelect('PRAGMA user_version')
        .getSingle();
    expect(version.read<int>('user_version'), 7);
  });
}

Widget _dialogApp({
  required DatabaseLifecycleManager lifecycleManager,
  required SelectedBackupFile backup,
  required LocalBackupService backupService,
}) {
  return ProviderScope(
    overrides: [
      databaseLifecycleManagerProvider.overrideWithValue(lifecycleManager),
      localBackupServiceProvider.overrideWithValue(backupService),
    ],
    child: MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return Center(
              child: ElevatedButton(
                onPressed: () {
                  showRestoreConfirmationDialog(
                    context: context,
                    backup: backup,
                  );
                },
                child: const Text('Open Dialog'),
              ),
            );
          },
        ),
      ),
    ),
  );
}

SelectedBackupFile _selectedBackup(String filePath) {
  return SelectedBackupFile(
    filePath: filePath,
    fileName: p.basename(filePath),
    metadata: BackupMetadata(
      filePath: filePath,
      fileName: p.basename(filePath),
      createdAt: DateTime.utc(2026, 7, 6, 12),
      fileSizeBytes: 4096,
      schemaVersion: 5,
      repairCount: 2,
    ),
  );
}

DatabaseLifecycleManager _lifecycleManager(File databaseFile) {
  AppDatabase open(File file) => AppDatabase(openNativeDatabaseFile(file));

  return DatabaseLifecycleManager(
    resolveDatabaseFile: () async => databaseFile,
    openDatabase: open,
    initialDatabase: open(databaseFile),
  );
}

DriftRepairRepository _repairRepository(DatabaseLifecycleManager manager) {
  return DriftRepairRepository(
    manager.database,
    RepairLocalDataSource(manager.database),
    RepairCodeSequenceLocalDataSource(manager.database),
    ShopSettingsLocalDataSource(manager.database),
    now: () => DateTime.utc(2026, 7, 6, 12),
  );
}

DriftShopSettingsRepository _settingsRepository(
  DatabaseLifecycleManager manager,
) {
  return DriftShopSettingsRepository(
    ShopSettingsLocalDataSource(manager.database),
    now: () => DateTime.utc(2026, 7, 6, 12),
  );
}

Future<int> _liveRepairCount(DatabaseLifecycleManager manager) async {
  final row = await manager.database
      .customSelect('SELECT COUNT(*) AS value FROM repairs')
      .getSingle();
  return row.read<int>('value');
}

Future<String> _liveShopName(DatabaseLifecycleManager manager) async {
  final row = await manager.database
      .customSelect('SELECT shop_name AS value FROM shop_settings WHERE id = 1')
      .getSingle();
  return row.read<String>('value');
}

Future<void> _setDesktopSurface(WidgetTester tester) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1440, 1000);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _pumpUntilVisible(
  WidgetTester tester,
  Finder finder, {
  int maxPumps = 30,
}) async {
  for (var i = 0; i < maxPumps; i += 1) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }
}

class _FakeRestoreBackupService extends LocalBackupService {
  _FakeRestoreBackupService(
    DatabaseLifecycleManager manager, {
    this.failUntilCall = 0,
  }) : super(manager, const BackupValidator());

  final int failUntilCall;
  int restoreCalls = 0;

  @override
  Future<BackupMetadata> validateBackup(String backupFilePath) async {
    return BackupMetadata(
      filePath: backupFilePath,
      fileName: p.basename(backupFilePath),
      createdAt: DateTime.utc(2026, 7, 6, 12),
      fileSizeBytes: 4096,
      schemaVersion: 5,
      repairCount: 2,
    );
  }

  @override
  Future<BackupMetadata> restoreBackup(String backupFilePath) async {
    restoreCalls += 1;
    if (restoreCalls <= failUntilCall) {
      throw StateError('restore failed');
    }

    return BackupMetadata(
      filePath: backupFilePath,
      fileName: p.basename(backupFilePath),
      createdAt: DateTime.utc(2026, 7, 6, 12),
      fileSizeBytes: 4096,
      schemaVersion: 5,
      repairCount: 2,
    );
  }
}

class _BlockingRestoreBackupService extends LocalBackupService {
  _BlockingRestoreBackupService(DatabaseLifecycleManager manager)
    : super(manager, const BackupValidator());

  final Completer<BackupMetadata> _completer = Completer<BackupMetadata>();
  int restoreCalls = 0;

  void complete() {
    if (!_completer.isCompleted) {
      _completer.complete(
        BackupMetadata(
          filePath: 'completed.nrbackup',
          fileName: 'completed.nrbackup',
          createdAt: DateTime.utc(2026, 7, 6, 12),
          fileSizeBytes: 4096,
          schemaVersion: 5,
          repairCount: 2,
        ),
      );
    }
  }

  @override
  Future<BackupMetadata> restoreBackup(String backupFilePath) {
    restoreCalls += 1;
    return _completer.future;
  }
}

class _FakeBackupFileDialogService extends BackupFileDialogService {
  const _FakeBackupFileDialogService({this.openPath});

  final String? openPath;

  @override
  Future<String?> chooseBackupOpenPath() async {
    return openPath;
  }
}

class _EmptyLocalPrinterService implements LocalPrinterService {
  const _EmptyLocalPrinterService();

  @override
  Future<LocalPrinter?> getDefaultPrinter() async {
    return null;
  }

  @override
  Future<List<LocalPrinter>> listPrinters() async {
    return const [];
  }

  @override
  Future<PrintResult> printDocument({
    required PrintPrinterTarget printerTarget,
    required RenderedPrintDocument document,
    required int copies,
  }) async {
    return PrintResult.failed(
      failureKind: PrintFailureKind.noPrinterAvailable,
      message: 'No printer is available.',
    );
  }
}
