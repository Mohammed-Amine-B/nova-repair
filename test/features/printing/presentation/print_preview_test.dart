import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_repair/app/app_shell.dart';
import 'package:nova_repair/app/theme/app_theme.dart';
import 'package:nova_repair/app/widgets/table/app_table_shell.dart';
import 'package:nova_repair/database/app_database.dart';
import 'package:nova_repair/database/database_provider.dart';
import 'package:nova_repair/features/dashboard/presentation/dashboard_controller.dart';
import 'package:nova_repair/features/printing/application/build_repair_print_data_use_case.dart';
import 'package:nova_repair/features/printing/application/local_printer_service.dart';
import 'package:nova_repair/features/printing/application/print_printer_target.dart';
import 'package:nova_repair/features/printing/application/print_repair_document_use_case.dart';
import 'package:nova_repair/features/printing/application/rendered_print_document.dart';
import 'package:nova_repair/features/printing/domain/entities/local_printer.dart';
import 'package:nova_repair/features/printing/domain/entities/print_result.dart';
import 'package:nova_repair/features/printing/domain/entities/repair_print_data.dart';
import 'package:nova_repair/features/printing/presentation/print_document_mode.dart';
import 'package:nova_repair/features/printing/presentation/print_preview_controller.dart';
import 'package:nova_repair/features/printing/presentation/print_preview_page.dart';
import 'package:nova_repair/features/printing/presentation/print_preview_request.dart';
import 'package:nova_repair/features/printing/presentation/print_preview_state.dart';
import 'package:nova_repair/features/printing/printing_providers.dart';
import 'package:nova_repair/features/repairs/data/datasources/repair_code_sequence_local_data_source.dart';
import 'package:nova_repair/features/repairs/data/datasources/repair_local_data_source.dart';
import 'package:nova_repair/features/repairs/data/repositories/drift_repair_repository.dart';
import 'package:nova_repair/features/repairs/domain/entities/create_repair_input.dart';
import 'package:nova_repair/features/repairs/domain/entities/repair.dart';
import 'package:nova_repair/features/repairs/presentation/repairs_list_controller.dart';
import 'package:nova_repair/features/settings/data/datasources/shop_settings_local_data_source.dart';
import 'package:nova_repair/features/settings/data/repositories/drift_shop_settings_repository.dart';
import 'package:nova_repair/features/settings/domain/entities/shop_settings.dart';

void main() {
  late AppDatabase database;
  late DateTime now;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    now = DateTime.utc(2026, 7, 5, 10);
  });

  tearDown(() async {
    await database.close();
  });

  ProviderContainer container() {
    return ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
        dashboardClockProvider.overrideWithValue(() => now),
        repairsListClockProvider.overrideWithValue(() => now),
      ],
    );
  }

  Widget previewApp({
    required int repairId,
    PrintDocumentMode initialMode = PrintDocumentMode.customerTicket,
    VoidCallback? onBack,
    BuildRepairPrintDataUseCase? useCase,
    PrintRepairDocumentUseCase? printUseCase,
    LocalPrinterService? printerService,
  }) {
    final effectiveUseCase =
        useCase ??
        BuildRepairPrintDataUseCase(
          _repairRepository(database, () => now),
          _settingsRepository(database),
        );
    final effectivePrinterService =
        printerService ?? const _FakeLocalPrinterService(printers: []);

    return ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
        buildRepairPrintDataUseCaseProvider.overrideWithValue(effectiveUseCase),
        localPrinterServiceProvider.overrideWithValue(effectivePrinterService),
        if (printUseCase != null)
          printRepairDocumentUseCaseProvider.overrideWithValue(printUseCase),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: PrintPreviewPage(
            repairId: repairId,
            initialMode: initialMode,
            onBack: onBack ?? () {},
          ),
        ),
      ),
    );
  }

  group('PrintPreviewController', () {
    test(
      'loads print data by repair id and generates repair-code QR',
      () async {
        final testContainer = container();
        addTearDown(testContainer.dispose);
        final repair = await _createRepair(
          database,
          now,
          customerName: 'Amina',
          deviceType: 'Laptop',
          brand: 'HP',
          model: 'EliteBook',
        );
        await _saveSettings(database, now);

        final data = await testContainer.read(
          printPreviewDataProvider(repair.id!).future,
        );

        expect(data.printData.customerTicket.shopName, 'Nova Tech');
        expect(data.printData.customerTicket.shopPhone, '0555 00 11 22');
        expect(data.printData.customerTicket.shopAddress, 'Chlef, Algeria');
        expect(data.printData.customerTicket.repairCode, repair.repairCode);
        expect(data.printData.customerTicket.deviceType, 'Laptop');
        expect(data.qrCode.payload, repair.repairCode);
        expect(data.qrCode.svg, isNotEmpty);
      },
    );

    test('mode and copy controls stay bounded', () {
      final testContainer = ProviderContainer();
      addTearDown(testContainer.dispose);
      final controller = testContainer.read(
        printPreviewControllerProvider(
          PrintDocumentMode.customerTicket,
        ).notifier,
      );

      expect(
        testContainer
            .read(
              printPreviewControllerProvider(PrintDocumentMode.customerTicket),
            )
            .copies,
        1,
      );

      controller.decrementCopies();
      expect(
        testContainer
            .read(
              printPreviewControllerProvider(PrintDocumentMode.customerTicket),
            )
            .copies,
        PrintPreviewState.minCopies,
      );

      for (var i = 0; i < 150; i++) {
        controller.incrementCopies();
      }
      expect(
        testContainer
            .read(
              printPreviewControllerProvider(PrintDocumentMode.customerTicket),
            )
            .copies,
        PrintPreviewState.maxCopies,
      );

      controller.selectMode(PrintDocumentMode.deviceLabel);
      final state = testContainer.read(
        printPreviewControllerProvider(PrintDocumentMode.customerTicket),
      );
      expect(state.documentMode, PrintDocumentMode.deviceLabel);
      expect(state.copies, PrintPreviewState.maxCopies);
    });
  });

  group('PrintPreviewPage', () {
    testWidgets('renders customer ticket with real data and exclusions', (
      tester,
    ) async {
      await _setDesktopSurface(tester);
      await _saveSettings(database, now);
      final repair = await _createRepair(
        database,
        now,
        customerName: 'Amina Customer',
        customerPhone: '0555 123 456',
        deviceType: 'Laptop',
        brand: 'HP',
        model: 'EliteBook 840',
        reportedProblem: 'Does not power on',
        receivedAccessories: 'Charger and bag',
        deviceAccessInfo: 'PIN 1234',
        priceAmount: 6500,
        internalNotes: 'Internal diagnostic note',
        customerMessage: 'Customer status message',
      );

      await tester.pumpWidget(previewApp(repairId: repair.id!));
      await tester.pumpAndSettle();

      expect(find.text('Print Preview'), findsOneWidget);
      expect(find.text('Customer Ticket'), findsWidgets);
      expect(find.text('Device Label'), findsWidgets);
      expect(find.text('Default Printer'), findsOneWidget);
      expect(find.text('Receipt / A4'), findsOneWidget);
      expect(find.text('Nova Tech'), findsOneWidget);
      expect(find.text('Phone: 0555 00 11 22'), findsOneWidget);
      expect(find.text('Address: Chlef, Algeria'), findsOneWidget);
      expect(find.text(repair.repairCode), findsWidgets);
      expect(find.text('Received Date'), findsOneWidget);
      expect(find.text('Amina Customer'), findsOneWidget);
      expect(find.text('0555 123 456'), findsOneWidget);
      expect(find.text('HP EliteBook 840'), findsOneWidget);
      expect(find.text('Type: Laptop'), findsOneWidget);
      expect(find.text('Does not power on'), findsOneWidget);
      expect(find.text('Charger and bag'), findsOneWidget);
      expect(find.text('Scan to track your repair'), findsOneWidget);
      expect(
        find.bySemanticsLabel('QR code for ${repair.repairCode}'),
        findsOneWidget,
      );
      expect(find.text('6500'), findsNothing);
      expect(find.text('Pending'), findsNothing);
      expect(find.text('PIN 1234'), findsNothing);
      expect(find.text('Internal diagnostic note'), findsNothing);
      expect(find.text('Customer status message'), findsNothing);
      expect(find.text('REP-0042'), findsNothing);
      expect(find.text('Ahmed Benali'), findsNothing);
    });

    testWidgets('switches to device label and preserves copies', (
      tester,
    ) async {
      await _setDesktopSurface(tester);
      await _saveSettings(database, now);
      final repair = await _createRepair(
        database,
        now,
        customerName: 'Karim',
        customerPhone: '0666',
        deviceType: 'Phone',
        brand: 'Samsung',
        model: 'Galaxy S23',
        reportedProblem: 'Broken screen',
        receivedAccessories: 'Case',
        deviceAccessInfo: 'Pattern secret',
        priceAmount: 9000,
        internalNotes: 'Internal note',
        customerMessage: 'Visible message',
      );

      await tester.pumpWidget(previewApp(repairId: repair.id!));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Increase copies'));
      await tester.tap(find.byTooltip('Increase copies'));
      await tester.pumpAndSettle();
      expect(find.text('3'), findsOneWidget);

      await tester.tap(find.text('Device Label').first);
      await tester.pumpAndSettle();

      expect(find.text('Label'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('Nova Tech'), findsOneWidget);
      expect(find.text(repair.repairCode), findsWidgets);
      expect(find.text('Samsung Galaxy S23'), findsOneWidget);
      expect(find.text('Karim'), findsOneWidget);
      expect(find.text('0666'), findsOneWidget);
      expect(
        find.bySemanticsLabel('QR code for ${repair.repairCode}'),
        findsOneWidget,
      );
      expect(find.text('Broken screen'), findsNothing);
      expect(find.text('9000'), findsNothing);
      expect(find.text('Pattern secret'), findsNothing);
      expect(find.text('Internal note'), findsNothing);
      expect(find.text('Visible message'), findsNothing);
      expect(find.text('Case'), findsNothing);

      await tester.tap(find.text('Customer Ticket').first);
      await tester.pumpAndSettle();

      expect(find.text('Receipt / A4'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('Broken screen'), findsOneWidget);
    });

    testWidgets('copy controls are bounded and print invokes print service', (
      tester,
    ) async {
      await _setDesktopSurface(tester);
      final repair = await _createRepair(database, now);
      final printUseCase = _RecordingPrintUseCase();

      await tester.pumpWidget(
        previewApp(repairId: repair.id!, printUseCase: printUseCase),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Decrease copies'));
      await tester.pumpAndSettle();
      expect(find.text('1'), findsOneWidget);

      await tester.tap(find.byTooltip('Increase copies'));
      await tester.tap(find.text('Device Label').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Print'));
      await tester.pumpAndSettle();

      final request = printUseCase.requests.single;
      expect(request, isNotNull);
      expect(request.repairId, repair.id);
      expect(request.documentMode, PrintDocumentMode.deviceLabel);
      expect(request.copies, 2);
      expect(find.text('Print job sent successfully.'), findsOneWidget);
      expect(find.text('Printed successfully'), findsNothing);
    });

    testWidgets('printer display reflects configured printer preferences', (
      tester,
    ) async {
      await _setDesktopSurface(tester);
      await _saveSettings(
        database,
        now,
        customerTicketPrinterId: 'ticket-id',
        deviceLabelPrinterId: 'label-id',
      );
      final repair = await _createRepair(database, now);
      final printerService = _FakeLocalPrinterService(
        printers: const [
          LocalPrinter(
            id: 'ticket-id',
            displayName: 'Ticket Counter Printer',
            isDefault: false,
          ),
          LocalPrinter(
            id: 'label-id',
            displayName: 'Small Label Printer',
            isDefault: false,
          ),
        ],
      );

      await tester.pumpWidget(
        previewApp(repairId: repair.id!, printerService: printerService),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ticket Counter Printer'), findsOneWidget);

      await tester.tap(find.text('Device Label').first);
      await tester.pumpAndSettle();

      expect(find.text('Small Label Printer'), findsOneWidget);
    });

    testWidgets('printer display shows default printer for null preference', (
      tester,
    ) async {
      await _setDesktopSurface(tester);
      await _saveSettings(database, now);
      final repair = await _createRepair(database, now);

      await tester.pumpWidget(previewApp(repairId: repair.id!));
      await tester.pumpAndSettle();

      expect(find.text('Default Printer'), findsOneWidget);
    });

    testWidgets('printer display shows unavailable configured printer', (
      tester,
    ) async {
      await _setDesktopSurface(tester);
      await _saveSettings(database, now, customerTicketPrinterId: 'missing-id');
      final repair = await _createRepair(database, now);

      await tester.pumpWidget(
        previewApp(
          repairId: repair.id!,
          printerService: const _FakeLocalPrinterService(printers: []),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Unavailable printer'), findsOneWidget);
    });

    testWidgets('duplicate print submission is prevented', (tester) async {
      await _setDesktopSurface(tester);
      final repair = await _createRepair(database, now);
      final printUseCase = _RecordingPrintUseCase(
        pendingResult: PrintResult.success(),
      );

      await tester.pumpWidget(
        previewApp(repairId: repair.id!, printUseCase: printUseCase),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Print'));
      await tester.pump();
      await tester.tap(find.text('Print'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(printUseCase.requests, hasLength(1));
      expect(find.text('Print job sent successfully.'), findsOneWidget);
    });

    testWidgets(
      'print failure is shown honestly and preserves mode and copies',
      (tester) async {
        await _setDesktopSurface(tester);
        final repair = await _createRepair(database, now);
        final printUseCase = _RecordingPrintUseCase(
          result: PrintResult.failed(
            failureKind: PrintFailureKind.noPrinterAvailable,
            message: 'No available printer was found.',
          ),
        );

        await tester.pumpWidget(
          previewApp(repairId: repair.id!, printUseCase: printUseCase),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip('Increase copies'));
        await tester.tap(find.text('Device Label').first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Print'));
        await tester.pumpAndSettle();

        expect(
          printUseCase.requests.single.documentMode,
          PrintDocumentMode.deviceLabel,
        );
        expect(printUseCase.requests.single.copies, 2);
        expect(find.text('No available printer was found.'), findsOneWidget);
        expect(find.text('Label'), findsOneWidget);
        expect(find.text('2'), findsOneWidget);
      },
    );

    testWidgets('shows missing and error states without raw details', (
      tester,
    ) async {
      await _setDesktopSurface(tester);

      await tester.pumpWidget(previewApp(repairId: 999));
      await tester.pumpAndSettle();

      expect(find.text('Repair not found'), findsOneWidget);
      expect(find.text('Back'), findsOneWidget);

      await tester.pumpWidget(
        previewApp(repairId: 1, useCase: _ThrowingPrintDataUseCase()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Print data could not be loaded'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.textContaining('database boom'), findsNothing);
    });
  });

  group('AppShell print navigation', () {
    testWidgets(
      'Repair Details Print opens preview and Back returns to details',
      (tester) async {
        await _setDesktopSurface(tester);
        final repair = await _createRepair(
          database,
          now,
          customerName: 'Details Print',
        );

        await tester.pumpWidget(_shellApp(database: database, now: now));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Repairs'));
        await tester.pumpAndSettle();
        await tester.tap(_rowForText(repair.repairCode));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Print'));
        await tester.pumpAndSettle();

        expect(find.text('Print Preview'), findsOneWidget);
        expect(
          find.text('Review and print documents for ${repair.repairCode}'),
          findsOneWidget,
        );

        await tester.tap(find.byTooltip('Back'));
        await tester.pumpAndSettle();

        expect(find.text('Repair Details'), findsOneWidget);
        expect(find.text('Details Print'), findsOneWidget);
      },
    );

    testWidgets(
      'New Repair Save & Print opens preview and Back returns to details',
      (tester) async {
        await _setDesktopSurface(tester);

        await tester.pumpWidget(_shellApp(database: database, now: now));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Repairs'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('New Repair'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('new-repair-device-type')),
          'Laptop',
        );
        await tester.enterText(
          find.byKey(const Key('new-repair-reported-problem')),
          'Needs print ticket',
        );
        await tester.tap(find.text('Save & Print'));
        await tester.pumpAndSettle();

        expect(find.text('Print Preview'), findsOneWidget);
        expect(find.text('Needs print ticket'), findsOneWidget);

        await tester.tap(find.byTooltip('Back'));
        await tester.pumpAndSettle();

        expect(find.text('Repair Details'), findsOneWidget);
        expect(find.text('Needs print ticket'), findsOneWidget);
      },
    );
  });
}

Widget _shellApp({required AppDatabase database, required DateTime now}) {
  return ProviderScope(
    overrides: [
      appDatabaseProvider.overrideWithValue(database),
      dashboardClockProvider.overrideWithValue(() => now),
      repairsListClockProvider.overrideWithValue(() => now),
    ],
    child: MaterialApp(theme: AppTheme.light(), home: const AppShell()),
  );
}

Finder _rowForText(String text) {
  return find.ancestor(
    of: find.text(text).first,
    matching: find.byType(AppTableRowShell),
  );
}

Future<void> _setDesktopSurface(WidgetTester tester) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1440, 1000);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _saveSettings(
  AppDatabase database,
  DateTime now, {
  String? customerTicketPrinterId,
  String? deviceLabelPrinterId,
}) {
  return _settingsRepository(database).saveSettings(
    ShopSettings(
      shopName: 'Nova Tech',
      phoneNumber: '0555 00 11 22',
      address: 'Chlef, Algeria',
      ticketFooter: 'Keep this ticket until collection.',
      warrantyTerms: 'Warranty applies to repaired parts only.',
      defaultCustomerTicketPrinterId: customerTicketPrinterId,
      defaultDeviceLabelPrinterId: deviceLabelPrinterId,
      createdAt: now,
      updatedAt: now,
    ),
  );
}

Future<Repair> _createRepair(
  AppDatabase database,
  DateTime now, {
  String? customerName,
  String? customerPhone,
  String? deviceType = 'Laptop',
  String? brand,
  String? model,
  String reportedProblem = 'Reported problem',
  String? receivedAccessories,
  String? deviceAccessInfo,
  int? priceAmount,
  String? internalNotes,
  String? customerMessage,
}) {
  return _repairRepository(database, () => now).createRepair(
    CreateRepairInput(
      customerName: customerName,
      customerPhone: customerPhone,
      deviceType: deviceType,
      brand: brand,
      model: model,
      reportedProblem: reportedProblem,
      receivedAccessories: receivedAccessories,
      deviceAccessInfo: deviceAccessInfo,
      priceAmount: priceAmount,
      internalNotes: internalNotes,
      customerMessage: customerMessage,
      receivedAt: now,
    ),
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

DriftShopSettingsRepository _settingsRepository(AppDatabase database) {
  return DriftShopSettingsRepository(ShopSettingsLocalDataSource(database));
}

class _ThrowingPrintDataUseCase implements BuildRepairPrintDataUseCase {
  @override
  Future<RepairPrintData> call(int repairId) {
    throw StateError('database boom');
  }
}

class _RecordingPrintUseCase implements PrintRepairDocumentUseCase {
  _RecordingPrintUseCase({PrintResult? result, PrintResult? pendingResult})
    : _result = result ?? PrintResult.success(),
      _pendingResult = pendingResult;

  final PrintResult _result;
  final PrintResult? _pendingResult;
  final requests = <PrintPreviewRequest>[];

  @override
  Future<PrintResult> call(PrintPreviewRequest request) async {
    requests.add(request);
    final pendingResult = _pendingResult;
    if (pendingResult != null) {
      await Future<void>.delayed(const Duration(milliseconds: 80));
      return pendingResult;
    }

    return _result;
  }
}

class _FakeLocalPrinterService implements LocalPrinterService {
  const _FakeLocalPrinterService({required this.printers});

  final List<LocalPrinter> printers;

  @override
  Future<LocalPrinter?> getDefaultPrinter() async {
    for (final printer in printers) {
      if (printer.isDefault && printer.isAvailable) {
        return printer;
      }
    }
    return printers.where((printer) => printer.isAvailable).firstOrNull;
  }

  @override
  Future<List<LocalPrinter>> listPrinters() async => printers;

  @override
  Future<PrintResult> printDocument({
    required PrintPrinterTarget printerTarget,
    required RenderedPrintDocument document,
    required int copies,
  }) async {
    return PrintResult.success();
  }
}
