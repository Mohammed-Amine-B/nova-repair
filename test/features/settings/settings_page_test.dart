import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_repair/app/app.dart';
import 'package:nova_repair/app/theme/app_theme.dart';
import 'package:nova_repair/database/app_database.dart';
import 'package:nova_repair/database/database_provider.dart';
import 'package:nova_repair/features/printing/application/build_repair_print_data_use_case.dart';
import 'package:nova_repair/features/printing/application/local_printer_service.dart';
import 'package:nova_repair/features/printing/application/print_printer_target.dart';
import 'package:nova_repair/features/printing/application/rendered_print_document.dart';
import 'package:nova_repair/features/printing/domain/entities/local_printer.dart';
import 'package:nova_repair/features/printing/domain/entities/print_result.dart';
import 'package:nova_repair/features/printing/printing_providers.dart';
import 'package:nova_repair/features/settings/data/datasources/shop_settings_local_data_source.dart';
import 'package:nova_repair/features/settings/data/repositories/drift_shop_settings_repository.dart';
import 'package:nova_repair/features/settings/domain/entities/shop_settings.dart';
import 'package:nova_repair/features/settings/domain/repositories/shop_settings_repository.dart';
import 'package:nova_repair/features/settings/presentation/settings_controller.dart';
import 'package:nova_repair/features/settings/settings_providers.dart';
import 'package:nova_repair/features/settings/settings_page.dart';
import 'package:nova_repair/features/repairs/data/datasources/repair_code_sequence_local_data_source.dart';
import 'package:nova_repair/features/repairs/data/datasources/repair_local_data_source.dart';
import 'package:nova_repair/features/repairs/data/repositories/drift_repair_repository.dart';
import 'package:nova_repair/features/repairs/domain/entities/create_repair_input.dart';

void main() {
  group('SettingsPage', () {
    late AppDatabase database;
    late _FakeLocalPrinterService printerService;
    late DateTime now;

    setUp(() {
      database = AppDatabase(_inMemoryDatabase());
      printerService = _FakeLocalPrinterService(
        printers: const [
          LocalPrinter(
            id: 'ticket-printer-id',
            displayName: 'Receipt Printer',
            isDefault: true,
          ),
          LocalPrinter(
            id: 'label-printer-id',
            displayName: 'Label Printer',
            isDefault: false,
          ),
        ],
      );
      now = DateTime.utc(2026, 7, 6, 9);
    });

    tearDown(() async {
      await database.close();
    });

    testWidgets('loads persisted settings and discovered printers', (
      tester,
    ) async {
      await _saveSettings(
        database,
        now,
        shopName: 'Nova Workshop',
        shopSubtitle: 'Repair Desk',
        phoneNumber: '0555000000',
        address: 'Chlef',
        customerTicketPrinterId: 'ticket-printer-id',
        deviceLabelPrinterId: 'label-printer-id',
      );

      await _pumpSettingsPage(tester, database, printerService);

      expect(find.text('Settings'), findsWidgets);
      expect(
        find.text('Manage shop information and application preferences'),
        findsOneWidget,
      );
      expect(find.text('Shop Information'), findsOneWidget);
      expect(find.text('Printing Defaults'), findsOneWidget);
      expect(find.text('Data'), findsOneWidget);
      expect(find.text('Common Problems'), findsOneWidget);
      expect(
        find.text('Manage frequently used repair problems'),
        findsOneWidget,
      );
      expect(find.text('Nova Workshop'), findsOneWidget);
      expect(find.text('Repair Desk'), findsOneWidget);
      expect(find.text('0555000000'), findsOneWidget);
      expect(find.text('Chlef'), findsOneWidget);
      expect(find.text('Receipt Printer'), findsOneWidget);
      expect(find.text('Label Printer'), findsOneWidget);
      expect(find.text('TechFix Repair'), findsNothing);

      await tester.tap(
        _dropdownIn(const Key('settings-customer-ticket-printer-dropdown')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Default Printer'), findsOneWidget);
      expect(find.text('Receipt Printer'), findsWidgets);
      expect(find.text('Label Printer'), findsWidgets);
    });

    testWidgets('saves visible fields and preserves hidden settings', (
      tester,
    ) async {
      await _saveSettings(
        database,
        now,
        shopName: 'Old Shop',
        shopSubtitle: 'Old Subtitle',
        phoneNumber: '0500000000',
        address: 'Old Address',
        customerTicketPrinterId: null,
        deviceLabelPrinterId: null,
      );

      await _pumpSettingsPage(tester, database, printerService);
      await tester.enterText(
        _textFieldIn(const Key('settings-shop-name-field')),
        ' Updated Shop ',
      );
      await tester.enterText(
        _textFieldIn(const Key('settings-shop-subtitle-field')),
        ' Service Center ',
      );
      await tester.enterText(
        _textFieldIn(const Key('settings-phone-number-field')),
        ' 0666000000 ',
      );
      await tester.enterText(
        _textFieldIn(const Key('settings-address-field')),
        ' Algiers ',
      );
      await _chooseDropdownValue(
        tester,
        const Key('settings-customer-ticket-printer-dropdown'),
        'Receipt Printer',
      );
      await _chooseDropdownValue(
        tester,
        const Key('settings-device-label-printer-dropdown'),
        'Label Printer',
      );

      await _tapVisible(tester, find.byKey(const Key('settings-save-button')));
      await tester.pumpAndSettle();

      final saved = await _settingsRepository(
        database,
        () => now,
      ).getSettings();

      expect(find.text('Settings saved successfully.'), findsOneWidget);
      expect(saved.shopName, 'Updated Shop');
      expect(saved.shopSubtitle, 'Service Center');
      expect(saved.phoneNumber, '0666000000');
      expect(saved.address, 'Algiers');
      expect(saved.defaultCustomerTicketPrinterId, 'ticket-printer-id');
      expect(saved.defaultDeviceLabelPrinterId, 'label-printer-id');
      expect(saved.logoPath, '/logos/hidden.png');
      expect(saved.repairCodePrefix, 'FIX');
      expect(saved.repairCodeNumberWidth, 6);
      expect(saved.ticketFooter, 'Hidden footer');
      expect(saved.warrantyTerms, 'Hidden warranty');
    });

    testWidgets('validates shop name and saves blank optional fields as null', (
      tester,
    ) async {
      await _saveSettings(
        database,
        now,
        shopName: 'Nova Workshop',
        shopSubtitle: 'Repair Desk',
        phoneNumber: '0555000000',
        address: 'Chlef',
        customerTicketPrinterId: 'ticket-printer-id',
        deviceLabelPrinterId: 'label-printer-id',
      );

      await _pumpSettingsPage(tester, database, printerService);
      await tester.enterText(
        _textFieldIn(const Key('settings-shop-name-field')),
        '   ',
      );
      await _tapVisible(tester, find.byKey(const Key('settings-save-button')));
      await tester.pump();

      expect(find.text('Shop name is required.'), findsOneWidget);

      await tester.enterText(
        _textFieldIn(const Key('settings-shop-name-field')),
        'Nova Workshop',
      );
      await tester.enterText(
        _textFieldIn(const Key('settings-shop-subtitle-field')),
        '   ',
      );
      await tester.enterText(
        _textFieldIn(const Key('settings-phone-number-field')),
        '   ',
      );
      await tester.enterText(
        _textFieldIn(const Key('settings-address-field')),
        '   ',
      );
      await _chooseDropdownValue(
        tester,
        const Key('settings-customer-ticket-printer-dropdown'),
        'Default Printer',
      );
      await _chooseDropdownValue(
        tester,
        const Key('settings-device-label-printer-dropdown'),
        'Default Printer',
      );
      await _tapVisible(tester, find.byKey(const Key('settings-save-button')));
      await tester.pumpAndSettle();

      final saved = await _settingsRepository(
        database,
        () => now,
      ).getSettings();

      expect(saved.shopSubtitle, isNull);
      expect(saved.phoneNumber, isNull);
      expect(saved.address, isNull);
      expect(saved.defaultCustomerTicketPrinterId, isNull);
      expect(saved.defaultDeviceLabelPrinterId, isNull);
    });

    testWidgets(
      'printer discovery failure keeps shop editing usable and retry works',
      (tester) async {
        await _saveSettings(
          database,
          now,
          shopName: 'Nova Workshop',
          customerTicketPrinterId: 'saved-ticket-id',
          deviceLabelPrinterId: 'saved-label-id',
        );
        printerService.failDiscovery = true;

        await _pumpSettingsPage(tester, database, printerService);

        expect(
          find.text('Unavailable printer (saved-ticket-id)'),
          findsOneWidget,
        );
        expect(
          find.text('Unavailable printer (saved-label-id)'),
          findsOneWidget,
        );
        expect(
          find.text(
            'Printers could not be loaded. Saved printer preferences are preserved.',
          ),
          findsOneWidget,
        );

        await tester.enterText(
          _textFieldIn(const Key('settings-shop-name-field')),
          'Edited While Printers Fail',
        );
        await _tapVisible(
          tester,
          find.byKey(const Key('settings-save-button')),
        );
        await tester.pumpAndSettle();

        var saved = await _settingsRepository(
          database,
          () => now,
        ).getSettings();
        expect(saved.shopName, 'Edited While Printers Fail');
        expect(saved.defaultCustomerTicketPrinterId, 'saved-ticket-id');
        expect(saved.defaultDeviceLabelPrinterId, 'saved-label-id');

        printerService
          ..failDiscovery = false
          ..printers = const [
            LocalPrinter(
              id: 'saved-ticket-id',
              displayName: 'Recovered Ticket Printer',
              isDefault: false,
            ),
            LocalPrinter(
              id: 'saved-label-id',
              displayName: 'Recovered Label Printer',
              isDefault: false,
            ),
          ];

        await tester.tap(find.text('Retry'));
        await tester.pumpAndSettle();

        expect(find.text('Recovered Ticket Printer'), findsOneWidget);
        expect(find.text('Recovered Label Printer'), findsOneWidget);
        saved = await _settingsRepository(database, () => now).getSettings();
        expect(saved.defaultCustomerTicketPrinterId, 'saved-ticket-id');
      },
    );

    testWidgets('save failure preserves entered values', (tester) async {
      final repository = _FakeShopSettingsRepository(
        initialSettings: ShopSettings(
          shopName: 'Nova Workshop',
          shopSubtitle: 'Repair Desk',
          createdAt: now,
          updatedAt: now,
        ),
      )..failSave = true;

      await _setDesktopSurface(tester);
      await tester.pumpWidget(
        _testApp(
          ProviderScope(
            overrides: [
              shopSettingsRepositoryProvider.overrideWithValue(repository),
              localPrinterServiceProvider.overrideWithValue(printerService),
            ],
            child: SettingsPage(
              onOpenBackupRestore: () {},
              onOpenCommonProblems: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        _textFieldIn(const Key('settings-shop-name-field')),
        'Unsaved Shop',
      );
      await _tapVisible(tester, find.byKey(const Key('settings-save-button')));
      await tester.pumpAndSettle();

      expect(
        find.text('Settings could not be saved. Please try again.'),
        findsOneWidget,
      );
      expect(find.text('Unsaved Shop'), findsOneWidget);
    });

    testWidgets('Backup & Restore card invokes callback boundary', (
      tester,
    ) async {
      var opened = false;

      await _pumpSettingsPage(
        tester,
        database,
        printerService,
        onOpenBackupRestore: () => opened = true,
      );

      await _tapVisible(
        tester,
        find.byKey(const Key('settings-backup-restore-card')),
      );
      await tester.pump();

      expect(opened, isTrue);
    });

    testWidgets('Common Problems card invokes callback boundary', (
      tester,
    ) async {
      var opened = false;

      await _pumpSettingsPage(
        tester,
        database,
        printerService,
        onOpenCommonProblems: () => opened = true,
      );

      await _tapVisible(
        tester,
        find.byKey(const Key('settings-common-problems-card')),
      );
      await tester.pump();

      expect(opened, isTrue);
    });

    testWidgets('fresh print data uses saved shop subtitle', (tester) async {
      await _pumpSettingsPage(tester, database, printerService);
      await tester.enterText(
        _textFieldIn(const Key('settings-shop-name-field')),
        'Print Shop',
      );
      await tester.enterText(
        _textFieldIn(const Key('settings-shop-subtitle-field')),
        'Printed Subtitle',
      );
      await _tapVisible(tester, find.byKey(const Key('settings-save-button')));
      await tester.pumpAndSettle();

      final repairRepository = _repairRepository(database, () => now);
      final repair = await repairRepository.createRepair(
        CreateRepairInput(reportedProblem: 'Does not power on'),
      );
      final printData = await BuildRepairPrintDataUseCase(
        repairRepository,
        _settingsRepository(database, () => now),
      ).call(repair.id!);

      expect(printData.customerTicket.shopSubtitle, 'Printed Subtitle');
    });

    testWidgets('AppShell Settings destination opens the real Settings page', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(database),
            localPrinterServiceProvider.overrideWithValue(printerService),
          ],
          child: const NovaRepairApp(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      expect(
        find.text('Manage shop information and application preferences'),
        findsOneWidget,
      );
      expect(find.text('Shop Information'), findsOneWidget);
      expect(find.text('Backup & Restore'), findsOneWidget);
    });
  });

  test('SettingsController prevents duplicate saves', () async {
    final now = DateTime.utc(2026, 7, 6, 9);
    final repository = _CompleterShopSettingsRepository(
      initialSettings: ShopSettings(
        shopName: 'Nova Workshop',
        createdAt: now,
        updatedAt: now,
      ),
    );
    final container = ProviderContainer(
      overrides: [shopSettingsRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    final currentSettings = await repository.getSettings();
    final controller = container.read(settingsControllerProvider.notifier);

    final firstSave = controller.save(
      currentSettings: currentSettings,
      shopName: 'Nova Workshop',
      shopSubtitle: '',
      phoneNumber: '',
      address: '',
      defaultCustomerTicketPrinterId: null,
      defaultDeviceLabelPrinterId: null,
    );
    final secondSave = await controller.save(
      currentSettings: currentSettings,
      shopName: 'Nova Workshop',
      shopSubtitle: '',
      phoneNumber: '',
      address: '',
      defaultCustomerTicketPrinterId: null,
      defaultDeviceLabelPrinterId: null,
    );

    expect(secondSave, isNull);
    expect(repository.saveCalls, 1);

    repository.completeSave();
    expect(await firstSave, isA<ShopSettings>());
  });
}

Future<void> _pumpSettingsPage(
  WidgetTester tester,
  AppDatabase database,
  _FakeLocalPrinterService printerService, {
  VoidCallback? onOpenBackupRestore,
  VoidCallback? onOpenCommonProblems,
}) async {
  await _setDesktopSurface(tester);
  await tester.pumpWidget(
    _testApp(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          localPrinterServiceProvider.overrideWithValue(printerService),
        ],
        child: SettingsPage(
          onOpenBackupRestore: onOpenBackupRestore ?? () {},
          onOpenCommonProblems: onOpenCommonProblems ?? () {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Widget _testApp(Widget child) {
  return MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(body: child),
  );
}

Finder _textFieldIn(Key key) {
  return find.descendant(of: find.byKey(key), matching: find.byType(TextField));
}

Future<void> _chooseDropdownValue(
  WidgetTester tester,
  Key dropdownKey,
  String label,
) async {
  final dropdown = _dropdownIn(dropdownKey);
  await _tapVisible(tester, dropdown);
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

Finder _dropdownIn(Key key) {
  return find.descendant(
    of: find.byKey(key),
    matching: find.byType(DropdownButtonFormField<String>),
  );
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
}

Future<void> _setDesktopSurface(WidgetTester tester) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1440, 1200);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _saveSettings(
  AppDatabase database,
  DateTime now, {
  required String shopName,
  String? shopSubtitle,
  String? phoneNumber,
  String? address,
  String? customerTicketPrinterId,
  String? deviceLabelPrinterId,
}) {
  return _settingsRepository(database, () => now).saveSettings(
    ShopSettings(
      shopName: shopName,
      shopSubtitle: shopSubtitle,
      phoneNumber: phoneNumber,
      address: address,
      logoPath: '/logos/hidden.png',
      repairCodePrefix: 'FIX',
      repairCodeNumberWidth: 6,
      ticketFooter: 'Hidden footer',
      warrantyTerms: 'Hidden warranty',
      defaultCustomerTicketPrinterId: customerTicketPrinterId,
      defaultDeviceLabelPrinterId: deviceLabelPrinterId,
      createdAt: now,
      updatedAt: now,
    ),
  );
}

DriftShopSettingsRepository _settingsRepository(
  AppDatabase database,
  DateTime Function() now,
) {
  return DriftShopSettingsRepository(
    ShopSettingsLocalDataSource(database),
    now: now,
  );
}

DriftRepairRepository _repairRepository(
  AppDatabase database,
  DateTime Function() now,
) {
  return DriftRepairRepository(
    database,
    RepairLocalDataSource(database),
    RepairCodeSequenceLocalDataSource(database),
    ShopSettingsLocalDataSource(database),
    now: now,
  );
}

NativeDatabase _inMemoryDatabase() {
  return NativeDatabase.memory(
    setup: (database) {
      database.execute('PRAGMA foreign_keys = ON');
    },
  );
}

class _FakeLocalPrinterService implements LocalPrinterService {
  _FakeLocalPrinterService({required this.printers});

  List<LocalPrinter> printers;
  bool failDiscovery = false;

  @override
  Future<LocalPrinter?> getDefaultPrinter() async {
    final discovered = await listPrinters();
    for (final printer in discovered) {
      if (printer.isDefault && printer.isAvailable) {
        return printer;
      }
    }
    return discovered.where((printer) => printer.isAvailable).firstOrNull;
  }

  @override
  Future<List<LocalPrinter>> listPrinters() async {
    if (failDiscovery) {
      throw StateError('Printer discovery failed');
    }
    return printers;
  }

  @override
  Future<PrintResult> printDocument({
    required PrintPrinterTarget printerTarget,
    required RenderedPrintDocument document,
    required int copies,
  }) {
    return Future.value(PrintResult.success());
  }
}

class _FakeShopSettingsRepository implements ShopSettingsRepository {
  _FakeShopSettingsRepository({required ShopSettings initialSettings})
    : _settings = initialSettings;

  ShopSettings _settings;
  bool failSave = false;

  @override
  Future<ShopSettings> getSettings() async => _settings;

  @override
  Future<ShopSettings> saveSettings(ShopSettings settings) async {
    if (failSave) {
      throw StateError('Save failed');
    }
    _settings = settings;
    return settings;
  }
}

class _CompleterShopSettingsRepository implements ShopSettingsRepository {
  _CompleterShopSettingsRepository({required ShopSettings initialSettings})
    : _settings = initialSettings;

  ShopSettings _settings;
  int saveCalls = 0;
  final _saveCompleter = Completer<ShopSettings>();

  @override
  Future<ShopSettings> getSettings() async => _settings;

  @override
  Future<ShopSettings> saveSettings(ShopSettings settings) {
    saveCalls++;
    _settings = settings;
    return _saveCompleter.future;
  }

  void completeSave() {
    if (!_saveCompleter.isCompleted) {
      _saveCompleter.complete(_settings);
    }
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) {
      return null;
    }
    return iterator.current;
  }
}
