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
import 'package:nova_repair/features/backup/backup_restore_page.dart';
import 'package:nova_repair/features/backup/backup_providers.dart';
import 'package:nova_repair/features/backup/domain/entities/backup_metadata.dart';
import 'package:nova_repair/features/backup/infrastructure/backup_validator.dart';
import 'package:nova_repair/features/backup/presentation/backup_restore_controller.dart';
import 'package:nova_repair/features/backup/presentation/backup_restore_state.dart';
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
  late DateTime now;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp(
      'nova_repair_backup_ui_test_',
    );
    databaseFile = File('${tempDirectory.path}/nova_repair.sqlite');
    lifecycleManager = _lifecycleManager(databaseFile);
    now = DateTime.utc(2026, 7, 5, 10);
  });

  tearDown(() async {
    await lifecycleManager.closeCurrentDatabase();
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  test('current data summary reads real database state', () async {
    await _seedData(lifecycleManager, now);
    final container = ProviderContainer(
      overrides: [
        databaseLifecycleManagerProvider.overrideWithValue(lifecycleManager),
        repairRepositoryProvider.overrideWithValue(
          _repairRepository(lifecycleManager, DateTime.now),
        ),
        shopSettingsRepositoryProvider.overrideWithValue(
          _settingsRepository(lifecycleManager, DateTime.now),
        ),
      ],
    );
    addTearDown(container.dispose);

    final summary = await container.read(backupDataSummaryProvider.future);

    expect(summary.repairCount, 2);
    expect(summary.databaseSizeBytes, greaterThan(0));
    expect(summary.lastUpdated, isNotNull);
    expect(
      summary.lastUpdated!.isBefore(DateTime.utc(2026, 7, 5, 10)),
      isFalse,
    );
  });

  test(
    'create backup file writes the selected path with real service',
    () async {
      await _seedData(lifecycleManager, now);
      final backupPath = '${tempDirectory.path}/Chosen_Backup.nrbackup';
      final service = LocalBackupService(
        lifecycleManager,
        const BackupValidator(),
        now: () => DateTime.utc(2026, 7, 6, 12),
      );

      final metadata = await service.createBackupFile(backupPath);

      expect(await File(backupPath).exists(), isTrue);
      expect(metadata.filePath, backupPath);
      expect(metadata.fileName, 'Chosen_Backup.nrbackup');
      expect(metadata.repairCount, 2);
    },
  );

  testWidgets('shows current data from real database state', (tester) async {
    await _setDesktopSurface(tester);
    await _seedData(lifecycleManager, now);

    await tester.pumpWidget(
      _pageApp(
        lifecycleManager: lifecycleManager,
        summary: const BackupDataSummary(
          repairCount: 2,
          databaseSizeBytes: 24 * 1024,
          lastUpdated: null,
        ),
      ),
    );
    await _pumpUntilVisible(tester, find.text('REPAIRS'));

    expect(find.text('Backup & Restore'), findsOneWidget);
    expect(
      find.text('Protect and recover your Nova Repair data'),
      findsOneWidget,
    );
    expect(find.text('REPAIRS'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('DATABASE SIZE'), findsOneWidget);
    expect(find.textContaining('KB'), findsWidgets);
    expect(find.text('LAST UPDATED'), findsOneWidget);
    expect(find.text('—'), findsWidgets);
    expect(find.text('248'), findsNothing);
    expect(find.text('18.4 MB'), findsNothing);
    expect(find.text('Today, 16:40'), findsNothing);
  });

  testWidgets('creates backup through save dialog boundary', (tester) async {
    await _setDesktopSurface(tester);
    await _seedData(lifecycleManager, now);
    final backupPath = '${tempDirectory.path}/Chosen_Backup.nrbackup';
    final dialog = _FakeBackupFileDialogService(savePath: backupPath);
    final backupService = _FakeLocalBackupService(lifecycleManager);

    await tester.pumpWidget(
      _pageApp(
        lifecycleManager: lifecycleManager,
        fileDialog: dialog,
        backupService: backupService,
      ),
    );
    await _pumpUntilVisible(
      tester,
      find.byKey(const Key('backup-create-button')),
    );

    await tester.tap(find.byKey(const Key('backup-create-button')));
    await _pumpUntilVisible(tester, find.text('Backup created successfully.'));

    expect(
      dialog.suggestedNames.single,
      'NovaRepair_Backup_2026-07-06.nrbackup',
    );
    expect(backupService.createdPaths.single, backupPath);
    expect(find.text('Backup created successfully.'), findsOneWidget);
    expect(find.text('Chosen_Backup.nrbackup'), findsWidgets);
  });

  test('create backup failure records safe error', () async {
    final existingPath = '${tempDirectory.path}/existing.nrbackup';
    await File(existingPath).writeAsString('already exists');

    final container = ProviderContainer(
      overrides: [
        databaseLifecycleManagerProvider.overrideWithValue(lifecycleManager),
        backupFileDialogServiceProvider.overrideWithValue(
          _FakeBackupFileDialogService(savePath: existingPath),
        ),
        localBackupServiceProvider.overrideWithValue(
          _FakeLocalBackupService(lifecycleManager, failCreate: true),
        ),
        backupRestoreClockProvider.overrideWithValue(
          () => DateTime.utc(2026, 7, 6),
        ),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      backupRestoreControllerProvider,
      (_, _) {},
    );
    addTearDown(subscription.close);

    await container
        .read(backupRestoreControllerProvider.notifier)
        .createBackup();
    final state = container.read(backupRestoreControllerProvider);

    expect(
      state.errorMessage,
      'Backup could not be created. Please try again.',
    );
    expect(state.successMessage, isNull);
  });

  test('duplicate backup creation is prevented', () async {
    final dialog = _BlockingBackupFileDialogService();
    final container = ProviderContainer(
      overrides: [
        databaseLifecycleManagerProvider.overrideWithValue(lifecycleManager),
        backupFileDialogServiceProvider.overrideWithValue(dialog),
        backupRestoreClockProvider.overrideWithValue(
          () => DateTime.utc(2026, 7, 6),
        ),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      backupRestoreControllerProvider,
      (_, _) {},
    );
    addTearDown(subscription.close);

    final controller = container.read(backupRestoreControllerProvider.notifier);
    final firstCreate = controller.createBackup();
    await Future<void>.delayed(Duration.zero);
    final secondCreate = controller.createBackup();

    expect(dialog.saveCalls, 1);
    dialog.complete(null);
    await secondCreate;
    await firstCreate;
  });

  testWidgets(
    'valid selected backup displays file name only and enables boundary',
    (tester) async {
      await _setDesktopSurface(tester);
      await _seedData(lifecycleManager, now);
      final metadata = _backupMetadata(
        filePath: '${tempDirectory.path}/Valid_Selected_Backup.nrbackup',
      );
      final backupService = _FakeLocalBackupService(
        lifecycleManager,
        validateMetadata: metadata,
      );
      SelectedBackupFile? restoreRequest;

      await tester.pumpWidget(
        _pageApp(
          lifecycleManager: lifecycleManager,
          fileDialog: _FakeBackupFileDialogService(openPath: metadata.filePath),
          backupService: backupService,
          onRestoreRequested: (backup) => restoreRequest = backup,
        ),
      );
      await _pumpUntilVisible(
        tester,
        find.byKey(const Key('backup-choose-file-button')),
      );

      await tester.tap(find.byKey(const Key('backup-choose-file-button')));
      await _pumpUntilVisible(
        tester,
        find.textContaining('Selected: Valid_Selected_Backup.nrbackup'),
      );

      expect(
        find.textContaining('Selected: Valid_Selected_Backup.nrbackup'),
        findsOneWidget,
      );
      expect(find.textContaining(tempDirectory.path), findsNothing);

      await tester.ensureVisible(
        find.byKey(const Key('backup-restore-button')),
      );
      await tester.tap(find.byKey(const Key('backup-restore-button')));
      await _pumpBackupFrame(tester);

      expect(restoreRequest?.filePath, metadata.filePath);
    },
  );

  test('invalid selected backup is rejected safely', () async {
    final invalidPath = '${tempDirectory.path}/invalid.nrbackup';
    await File(invalidPath).writeAsString('not a backup');

    final container = ProviderContainer(
      overrides: [
        databaseLifecycleManagerProvider.overrideWithValue(lifecycleManager),
        backupFileDialogServiceProvider.overrideWithValue(
          _FakeBackupFileDialogService(openPath: invalidPath),
        ),
        localBackupServiceProvider.overrideWithValue(
          _FakeLocalBackupService(lifecycleManager, failValidate: true),
        ),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      backupRestoreControllerProvider,
      (_, _) {},
    );
    addTearDown(subscription.close);

    await container
        .read(backupRestoreControllerProvider.notifier)
        .chooseBackupFile();
    final state = container.read(backupRestoreControllerProvider);

    expect(state.errorMessage, 'The selected backup file is not valid.');
    expect(state.selectedBackup, isNull);
  });

  testWidgets('warning and empty selected file state render', (tester) async {
    await _setDesktopSurface(tester);

    await tester.pumpWidget(_pageApp(lifecycleManager: lifecycleManager));
    await _pumpUntilVisible(tester, find.text('No backup file selected'));

    expect(
      find.text(
        'Restoring a backup will replace the current Nova Repair data.',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'Create a new backup first if you may need to return to the current data.',
      ),
      findsOneWidget,
    );
    expect(find.text('No backup file selected'), findsOneWidget);
  });

  testWidgets('app shell navigates Settings to Backup and back', (
    tester,
  ) async {
    await _setDesktopSurface(tester);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseLifecycleManagerProvider.overrideWithValue(lifecycleManager),
          repairRepositoryProvider.overrideWithValue(
            _repairRepository(lifecycleManager, DateTime.now),
          ),
          shopSettingsRepositoryProvider.overrideWithValue(
            _settingsRepository(lifecycleManager, DateTime.now),
          ),
          localPrinterServiceProvider.overrideWithValue(
            const _EmptyLocalPrinterService(),
          ),
          backupFileDialogServiceProvider.overrideWithValue(
            _FakeBackupFileDialogService(),
          ),
          backupDataSummaryProvider.overrideWith((ref) async => _testSummary()),
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

    expect(find.text('Backup & Restore'), findsOneWidget);
    expect(
      find.byKey(const Key('nova-sidebar-item-settings-selected')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('backup-restore-back-to-settings')));
    await _pumpUntilVisible(tester, find.text('Shop Information'));

    expect(find.text('Shop Information'), findsOneWidget);
  });
}

Widget _pageApp({
  required DatabaseLifecycleManager lifecycleManager,
  BackupFileDialogService? fileDialog,
  LocalBackupService? backupService,
  BackupDataSummary? summary,
  ValueChanged<SelectedBackupFile>? onRestoreRequested,
}) {
  return ProviderScope(
    overrides: [
      databaseLifecycleManagerProvider.overrideWithValue(lifecycleManager),
      repairRepositoryProvider.overrideWithValue(
        _repairRepository(lifecycleManager, DateTime.now),
      ),
      shopSettingsRepositoryProvider.overrideWithValue(
        _settingsRepository(lifecycleManager, DateTime.now),
      ),
      backupFileDialogServiceProvider.overrideWithValue(
        fileDialog ?? _FakeBackupFileDialogService(),
      ),
      if (backupService != null)
        localBackupServiceProvider.overrideWithValue(backupService),
      backupDataSummaryProvider.overrideWith(
        (ref) async => summary ?? _testSummary(),
      ),
      backupRestoreClockProvider.overrideWithValue(
        () => DateTime.utc(2026, 7, 6),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: BackupRestorePage(
          onBackToSettings: () {},
          onRestoreRequested: onRestoreRequested ?? (_) {},
        ),
      ),
    ),
  );
}

Future<void> _seedData(DatabaseLifecycleManager manager, DateTime now) async {
  final repairRepository = _repairRepository(manager, () => now);
  final settingsRepository = _settingsRepository(manager, () => now);

  final settings = await settingsRepository.getSettings();
  await settingsRepository.saveSettings(
    settings.copyWith(shopName: 'Backup Test Shop', updatedAt: now),
  );
  await repairRepository.createRepair(
    CreateRepairInput(reportedProblem: 'First repair', receivedAt: now),
  );
  await repairRepository.createRepair(
    CreateRepairInput(reportedProblem: 'Second repair', receivedAt: now),
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

DriftRepairRepository _repairRepository(
  DatabaseLifecycleManager manager,
  DateTime Function() now,
) {
  return DriftRepairRepository(
    manager.database,
    RepairLocalDataSource(manager.database),
    RepairCodeSequenceLocalDataSource(manager.database),
    ShopSettingsLocalDataSource(manager.database),
    now: now,
  );
}

DriftShopSettingsRepository _settingsRepository(
  DatabaseLifecycleManager manager,
  DateTime Function() now,
) {
  return DriftShopSettingsRepository(
    ShopSettingsLocalDataSource(manager.database),
    now: now,
  );
}

Future<void> _setDesktopSurface(WidgetTester tester) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1440, 1000);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

BackupDataSummary _testSummary() {
  return const BackupDataSummary(
    repairCount: 0,
    databaseSizeBytes: 0,
    lastUpdated: null,
  );
}

Future<void> _pumpBackupFrame(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 100));
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

class _FakeBackupFileDialogService extends BackupFileDialogService {
  _FakeBackupFileDialogService({this.savePath, this.openPath});

  final String? savePath;
  final String? openPath;
  final suggestedNames = <String>[];

  @override
  Future<String?> chooseBackupSavePath({required String suggestedName}) async {
    suggestedNames.add(suggestedName);
    return savePath;
  }

  @override
  Future<String?> chooseBackupOpenPath() async {
    return openPath;
  }
}

class _BlockingBackupFileDialogService extends BackupFileDialogService {
  final Completer<String?> _completer = Completer<String?>();
  int saveCalls = 0;

  void complete(String? path) {
    if (!_completer.isCompleted) {
      _completer.complete(path);
    }
  }

  @override
  Future<String?> chooseBackupSavePath({required String suggestedName}) {
    saveCalls += 1;
    return _completer.future;
  }
}

class _FakeLocalBackupService extends LocalBackupService {
  _FakeLocalBackupService(
    DatabaseLifecycleManager manager, {
    this.validateMetadata,
    this.failCreate = false,
    this.failValidate = false,
  }) : super(manager, const BackupValidator());

  final BackupMetadata? validateMetadata;
  final bool failCreate;
  final bool failValidate;
  final createdPaths = <String>[];

  @override
  Future<BackupMetadata> createBackupFile(String destinationFilePath) async {
    createdPaths.add(destinationFilePath);
    if (failCreate) {
      throw StateError('create failed');
    }

    return _backupMetadata(filePath: destinationFilePath);
  }

  @override
  Future<BackupMetadata> validateBackup(String backupFilePath) async {
    if (failValidate) {
      throw StateError('invalid backup');
    }

    return validateMetadata ?? _backupMetadata(filePath: backupFilePath);
  }
}

BackupMetadata _backupMetadata({required String filePath}) {
  return BackupMetadata(
    filePath: filePath,
    fileName: p.basename(filePath),
    createdAt: DateTime.utc(2026, 7, 6, 12),
    fileSizeBytes: 4096,
    schemaVersion: 5,
    repairCount: 2,
  );
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
