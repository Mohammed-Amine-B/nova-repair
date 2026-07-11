import 'dart:async';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_repair/database/app_database.dart';
import 'package:nova_repair/features/printing/application/local_printer_service.dart';
import 'package:nova_repair/features/printing/application/print_document_renderer.dart';
import 'package:nova_repair/features/printing/application/print_printer_target.dart';
import 'package:nova_repair/features/printing/application/print_repair_document_use_case.dart';
import 'package:nova_repair/features/printing/application/printer_preference_resolver.dart';
import 'package:nova_repair/features/printing/application/rendered_print_document.dart';
import 'package:nova_repair/features/printing/application/build_repair_print_data_use_case.dart';
import 'package:nova_repair/features/printing/domain/entities/customer_ticket_data.dart';
import 'package:nova_repair/features/printing/domain/entities/device_label_data.dart';
import 'package:nova_repair/features/printing/domain/entities/local_printer.dart';
import 'package:nova_repair/features/printing/domain/entities/print_result.dart';
import 'package:nova_repair/features/printing/domain/entities/repair_print_data.dart';
import 'package:nova_repair/features/printing/infrastructure/pdf/repair_pdf_document_renderer.dart';
import 'package:nova_repair/features/printing/infrastructure/printers/printing_local_printer_service.dart';
import 'package:nova_repair/features/printing/infrastructure/printers/printing_platform_client.dart';
import 'package:nova_repair/features/printing/infrastructure/qr/qr_code_generator.dart';
import 'package:nova_repair/features/printing/infrastructure/qr/qr_code_request.dart';
import 'package:nova_repair/features/printing/infrastructure/qr/qr_code_svg.dart';
import 'package:nova_repair/features/printing/presentation/print_document_mode.dart';
import 'package:nova_repair/features/printing/presentation/print_preview_request.dart';
import 'package:nova_repair/features/repairs/data/datasources/repair_code_sequence_local_data_source.dart';
import 'package:nova_repair/features/repairs/data/datasources/repair_local_data_source.dart';
import 'package:nova_repair/features/repairs/data/repositories/drift_repair_repository.dart';
import 'package:nova_repair/features/repairs/domain/customer_price_decision.dart';
import 'package:nova_repair/features/repairs/domain/entities/create_repair_input.dart';
import 'package:nova_repair/features/repairs/domain/entities/repair.dart';
import 'package:nova_repair/features/repairs/domain/repair_status.dart';
import 'package:nova_repair/features/settings/data/datasources/shop_settings_local_data_source.dart';
import 'package:nova_repair/features/settings/data/repositories/drift_shop_settings_repository.dart';
import 'package:nova_repair/features/settings/domain/entities/shop_settings.dart';
import 'package:pdf/pdf.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PrintingLocalPrinterService', () {
    test(
      'discovered printer models do not leak package-specific types',
      () async {
        final client = _FakePrintingPlatformClient(
          printers: const [
            PrintingPrinterSnapshot(
              id: 'printer-url',
              displayName: 'Office Receipt Printer',
              isDefault: true,
              isAvailable: true,
            ),
          ],
        );
        final service = PrintingLocalPrinterService(client);

        final printers = await service.listPrinters();

        expect(printers, hasLength(1));
        expect(printers.single, isA<LocalPrinter>());
        expect(printers.single.id, 'printer-url');
        expect(printers.single.displayName, 'Office Receipt Printer');
        expect(printers.single.isDefault, isTrue);
      },
    );

    test('system-default target maps to the default printer', () async {
      final client = _FakePrintingPlatformClient(
        printers: const [
          PrintingPrinterSnapshot(
            id: 'secondary',
            displayName: 'Secondary Printer',
            isDefault: false,
            isAvailable: true,
          ),
          PrintingPrinterSnapshot(
            id: 'default',
            displayName: 'Default Printer',
            isDefault: true,
            isAvailable: true,
          ),
        ],
      );
      final service = PrintingLocalPrinterService(client);

      final result = await service.printDocument(
        printerTarget: const PrintPrinterTarget.systemDefault(),
        document: _document(),
        copies: 1,
      );

      expect(result.status, PrintResultStatus.success);
      expect(client.printedPrinterIds, ['default']);
    });

    test(
      'available fallback is used when no explicit default exists',
      () async {
        final client = _FakePrintingPlatformClient(
          printers: const [
            PrintingPrinterSnapshot(
              id: 'available',
              displayName: 'Available Printer',
              isDefault: false,
              isAvailable: true,
            ),
          ],
        );
        final service = PrintingLocalPrinterService(client);

        final defaultPrinter = await service.getDefaultPrinter();

        expect(defaultPrinter?.id, 'available');
        expect(defaultPrinter?.displayName, 'Available Printer');
      },
    );

    test('no available printer fails safely without fake names', () async {
      final service = PrintingLocalPrinterService(
        _FakePrintingPlatformClient(printers: const []),
      );

      final result = await service.printDocument(
        printerTarget: const PrintPrinterTarget.systemDefault(),
        document: _document(),
        copies: 1,
      );

      expect(result.status, PrintResultStatus.failed);
      expect(result.failureKind, PrintFailureKind.noPrinterAvailable);
      expect(result.message, 'No printer is available.');
    });

    test('specific printer target uses exact available printer id', () async {
      final client = _FakePrintingPlatformClient(
        printers: const [
          PrintingPrinterSnapshot(
            id: 'default-id',
            displayName: 'Ticket Printer',
            isDefault: true,
            isAvailable: true,
          ),
          PrintingPrinterSnapshot(
            id: 'label-id',
            displayName: 'Ticket Printer',
            isDefault: false,
            isAvailable: true,
          ),
        ],
      );
      final service = PrintingLocalPrinterService(client);

      final result = await service.printDocument(
        printerTarget: const PrintPrinterTarget.printerId('label-id'),
        document: _document(),
        copies: 1,
      );

      expect(result.status, PrintResultStatus.success);
      expect(client.printedPrinterIds, ['label-id']);
    });

    test(
      'unavailable specific printer fails without falling back to default',
      () async {
        final client = _FakePrintingPlatformClient(
          printers: const [
            PrintingPrinterSnapshot(
              id: 'default-id',
              displayName: 'Default Printer',
              isDefault: true,
              isAvailable: true,
            ),
          ],
        );
        final service = PrintingLocalPrinterService(client);

        final result = await service.printDocument(
          printerTarget: const PrintPrinterTarget.printerId('missing-id'),
          document: _document(),
          copies: 1,
        );

        expect(result.status, PrintResultStatus.failed);
        expect(result.failureKind, PrintFailureKind.printerTargetUnavailable);
        expect(result.message, 'The selected printer is unavailable.');
        expect(client.printedPrinterIds, isEmpty);
      },
    );

    test(
      'copies are submitted safely when native copies are unavailable',
      () async {
        final client = _FakePrintingPlatformClient(
          printers: const [
            PrintingPrinterSnapshot(
              id: 'default',
              displayName: 'Default Printer',
              isDefault: true,
              isAvailable: true,
            ),
          ],
        );
        final service = PrintingLocalPrinterService(client);

        final result = await service.printDocument(
          printerTarget: const PrintPrinterTarget.systemDefault(),
          document: _document(),
          copies: 3,
        );

        expect(result.status, PrintResultStatus.success);
        expect(client.printedPrinterIds, ['default', 'default', 'default']);
      },
    );

    test(
      'printer cancellation and submission failures return safe results',
      () async {
        final cancellingClient = _FakePrintingPlatformClient(
          printers: const [
            PrintingPrinterSnapshot(
              id: 'default',
              displayName: 'Default Printer',
              isDefault: true,
              isAvailable: true,
            ),
          ],
          submitResult: false,
        );

        final cancelled = await PrintingLocalPrinterService(cancellingClient)
            .printDocument(
              printerTarget: const PrintPrinterTarget.systemDefault(),
              document: _document(),
              copies: 1,
            );

        expect(cancelled.status, PrintResultStatus.cancelled);

        final throwingClient = _FakePrintingPlatformClient(
          printers: const [
            PrintingPrinterSnapshot(
              id: 'default',
              displayName: 'Default Printer',
              isDefault: true,
              isAvailable: true,
            ),
          ],
          throwsOnSubmit: true,
        );

        final failed = await PrintingLocalPrinterService(throwingClient)
            .printDocument(
              printerTarget: const PrintPrinterTarget.systemDefault(),
              document: _document(),
              copies: 1,
            );

        expect(failed.status, PrintResultStatus.failed);
        expect(failed.failureKind, PrintFailureKind.printSubmissionFailed);
        expect(failed.message, 'The print job could not be sent.');
        expect(failed.message, isNot(contains('boom')));
      },
    );
  });

  group('RepairPdfDocumentRenderer', () {
    test(
      'customer ticket PDF contains approved fields and excludes sensitive fields',
      () async {
        final renderer = const RepairPdfDocumentRenderer(compress: false);
        final printData = _printData();
        final qrCode = const QrCodeGenerator().generateSvg(
          QrCodeRequest(payload: 'REP-0001', size: 192),
        );

        final result = await _renderCapturingPrintMessages(
          renderer: renderer,
          printData: printData,
          qrCode: qrCode,
          documentMode: PrintDocumentMode.customerTicket,
        );
        final document = result.document;
        final pdfText = String.fromCharCodes(document.bytes);

        expect(
          document.pageFormat,
          RepairPdfDocumentRenderer.customerTicketFormat,
        );
        expect(document.jobName, 'Nova Repair Ticket REP-0001');
        expect(document.bytes, isNotEmpty);
        _expectNoFontWarnings(result.printMessages);
        expect(pdfText, contains('/BaseFont/NotoSans'));
        expect(pdfText, contains('/ToUnicode'));
        _expectUnicodeMappings(pdfText, 'Nova Tech');
        expect(pdfText, isNot(contains('Repair Center')));
        _expectUnicodeMappings(pdfText, 'Phone: 0555 00 11 22');
        _expectUnicodeMappings(pdfText, 'Address: Chlef, Algeria');
        expect(pdfText, contains('REP-0001'));
        _expectUnicodeMappings(pdfText, 'Received Date');
        _expectUnicodeMappings(pdfText, 'Amina Customer');
        _expectUnicodeMappings(pdfText, '0555 123 456');
        _expectUnicodeMappings(pdfText, 'HP EliteBook 840');
        _expectUnicodeMappings(pdfText, 'Laptop');
        _expectUnicodeMappings(pdfText, 'Does not power on');
        _expectUnicodeMappings(pdfText, 'Charger and bag');
        _expectUnicodeMappings(pdfText, 'Keep this ticket.');
        _expectUnicodeMappings(pdfText, 'Warranty terms.');
        expect(pdfText, contains(' m '));
        expect(pdfText, isNot(contains('6500')));
        expect(pdfText, isNot(contains('pending')));
        expect(pdfText, isNot(contains('PIN 1234')));
        expect(pdfText, isNot(contains('Internal diagnostic note')));
        expect(pdfText, isNot(contains('Customer status message')));
      },
    );

    test('device label PDF contains only compact approved fields', () async {
      final renderer = const RepairPdfDocumentRenderer(compress: false);
      final printData = _printData();
      final qrCode = const QrCodeGenerator().generateSvg(
        QrCodeRequest(payload: 'REP-0001', size: 192),
      );

      final result = await _renderCapturingPrintMessages(
        renderer: renderer,
        printData: printData,
        qrCode: qrCode,
        documentMode: PrintDocumentMode.deviceLabel,
      );
      final document = result.document;
      final pdfText = String.fromCharCodes(document.bytes);

      expect(document.pageFormat, RepairPdfDocumentRenderer.deviceLabelFormat);
      expect(document.jobName, 'Nova Repair Label REP-0001');
      _expectNoFontWarnings(result.printMessages);
      expect(pdfText, contains('/BaseFont/NotoSans'));
      expect(pdfText, contains('/ToUnicode'));
      _expectUnicodeMappings(pdfText, 'Nova Tech');
      expect(pdfText, contains('REP-0001'));
      _expectUnicodeMappings(pdfText, 'HP EliteBook 840');
      _expectUnicodeMappings(pdfText, 'Amina Customer');
      _expectUnicodeMappings(pdfText, '0555 123 456');
      expect(pdfText, contains(' m '));
      expect(pdfText, isNot(contains('Does not power on')));
      expect(pdfText, isNot(contains('Charger and bag')));
      expect(pdfText, isNot(contains('6500')));
      expect(pdfText, isNot(contains('PIN 1234')));
      expect(pdfText, isNot(contains('Internal diagnostic note')));
      expect(pdfText, isNot(contains('Customer status message')));
      expect(pdfText, isNot(contains('Warranty terms.')));
    });

    test(
      'customer ticket renders Arabic, French, and mixed text without font warnings',
      () async {
        final renderer = const RepairPdfDocumentRenderer(compress: false);
        final printData = _multilingualPrintData();
        final qrCode = const QrCodeGenerator().generateSvg(
          QrCodeRequest(payload: 'REP-0002', size: 192),
        );

        final result = await _renderCapturingPrintMessages(
          renderer: renderer,
          printData: printData,
          qrCode: qrCode,
          documentMode: PrintDocumentMode.customerTicket,
        );
        final pdfText = String.fromCharCodes(result.document.bytes);

        expect(result.document.bytes, isNotEmpty);
        _expectNoFontWarnings(result.printMessages);
        expect(pdfText, contains('/BaseFont/NotoSans'));
        expect(pdfText, contains('/BaseFont/NotoSansArabic'));
        expect(pdfText, isNot(contains('Helvetica')));
        expect(pdfText, contains('REP-0002'));
        _expectUnicodeMappings(pdfText, 'Repair Center');
        _expectUnicodeMappings(pdfText, 'Réparation Téléphone Écran cassé');
        _expectUnicodeMappings(pdfText, '0555 99 88 77');
        _expectUnicodeMappings(pdfText, 'HP EliteBook 840');
        _expectArabicPresentationMappings(pdfText);
      },
    );

    test(
      'device label renders Arabic, French, and mixed text without font warnings',
      () async {
        final renderer = const RepairPdfDocumentRenderer(compress: false);
        final printData = _multilingualPrintData();
        final qrCode = const QrCodeGenerator().generateSvg(
          QrCodeRequest(payload: 'REP-0002', size: 192),
        );

        final result = await _renderCapturingPrintMessages(
          renderer: renderer,
          printData: printData,
          qrCode: qrCode,
          documentMode: PrintDocumentMode.deviceLabel,
        );
        final pdfText = String.fromCharCodes(result.document.bytes);

        expect(result.document.bytes, isNotEmpty);
        _expectNoFontWarnings(result.printMessages);
        expect(pdfText, contains('/BaseFont/NotoSans'));
        expect(pdfText, contains('/BaseFont/NotoSansArabic'));
        expect(pdfText, isNot(contains('Helvetica')));
        expect(pdfText, contains('REP-0002'));
        _expectArabicPresentationMappings(pdfText);
        _expectUnicodeMappings(pdfText, 'HP EliteBook 840');
        _expectUnicodeMappings(pdfText, '0555 99 88 77');
        expect(pdfText, isNot(contains('Repair Center')));
        expect(pdfText, isNot(contains('Écran cassé')));
        expect(pdfText, isNot(contains('الشاشة لا تعمل')));
      },
    );
  });

  group('PrintRepairDocumentUseCase', () {
    late AppDatabase database;
    late DateTime now;

    setUp(() {
      database = AppDatabase(NativeDatabase.memory());
      now = DateTime.utc(2026, 7, 5, 10);
    });

    tearDown(() async {
      await database.close();
    });

    test(
      'customer ticket request renders and prints through system default',
      () async {
        final repair = await _createRepair(database, now);
        await _saveSettings(database, now);
        final renderer = _RecordingRenderer();
        final printerService = _RecordingPrinterService(PrintResult.success());
        final useCase = PrintRepairDocumentUseCase(
          _buildUseCase(database, now),
          _settingsRepository(database),
          const PrinterPreferenceResolver(),
          const QrCodeGenerator(),
          renderer,
          printerService,
        );

        final result = await useCase(
          PrintPreviewRequest(
            repairId: repair.id!,
            documentMode: PrintDocumentMode.customerTicket,
            copies: 2,
          ),
        );

        expect(result.status, PrintResultStatus.success);
        expect(renderer.documentModes, [PrintDocumentMode.customerTicket]);
        expect(renderer.qrPayloads, [repair.repairCode]);
        expect(printerService.copies, [2]);
        expect(
          printerService.printerTargets.single,
          isA<SystemDefaultPrintPrinterTarget>(),
        );
      },
    );

    test('device label request uses label renderer mode', () async {
      final repair = await _createRepair(database, now);
      final renderer = _RecordingRenderer();
      final printerService = _RecordingPrinterService(PrintResult.success());
      final useCase = PrintRepairDocumentUseCase(
        _buildUseCase(database, now),
        _settingsRepository(database),
        const PrinterPreferenceResolver(),
        const QrCodeGenerator(),
        renderer,
        printerService,
      );

      await useCase(
        PrintPreviewRequest(
          repairId: repair.id!,
          documentMode: PrintDocumentMode.deviceLabel,
          copies: 1,
        ),
      );

      expect(renderer.documentModes, [PrintDocumentMode.deviceLabel]);
    });

    test(
      'customer ticket saved printer id resolves to specific target',
      () async {
        final repair = await _createRepair(database, now);
        await _saveSettings(
          database,
          now,
          customerTicketPrinterId: 'ticket-printer-id',
          deviceLabelPrinterId: 'label-printer-id',
        );
        final printerService = _RecordingPrinterService(PrintResult.success());
        final useCase = PrintRepairDocumentUseCase(
          _buildUseCase(database, now),
          _settingsRepository(database),
          const PrinterPreferenceResolver(),
          const QrCodeGenerator(),
          _RecordingRenderer(),
          printerService,
        );

        await useCase(
          PrintPreviewRequest(
            repairId: repair.id!,
            documentMode: PrintDocumentMode.customerTicket,
            copies: 1,
          ),
        );

        final target = printerService.printerTargets.single;
        expect(target, isA<SpecificPrintPrinterTarget>());
        expect((target as SpecificPrintPrinterTarget).id, 'ticket-printer-id');
      },
    );

    test('device label saved printer id resolves independently', () async {
      final repair = await _createRepair(database, now);
      await _saveSettings(
        database,
        now,
        customerTicketPrinterId: 'ticket-printer-id',
        deviceLabelPrinterId: 'label-printer-id',
      );
      final printerService = _RecordingPrinterService(PrintResult.success());
      final useCase = PrintRepairDocumentUseCase(
        _buildUseCase(database, now),
        _settingsRepository(database),
        const PrinterPreferenceResolver(),
        const QrCodeGenerator(),
        _RecordingRenderer(),
        printerService,
      );

      await useCase(
        PrintPreviewRequest(
          repairId: repair.id!,
          documentMode: PrintDocumentMode.deviceLabel,
          copies: 1,
        ),
      );

      final target = printerService.printerTargets.single;
      expect(target, isA<SpecificPrintPrinterTarget>());
      expect((target as SpecificPrintPrinterTarget).id, 'label-printer-id');
    });

    test('fresh settings are used for each print attempt', () async {
      final repair = await _createRepair(database, now);
      final printerService = _RecordingPrinterService(PrintResult.success());
      final useCase = PrintRepairDocumentUseCase(
        _buildUseCase(database, now),
        _settingsRepository(database),
        const PrinterPreferenceResolver(),
        const QrCodeGenerator(),
        _RecordingRenderer(),
        printerService,
      );

      await _saveSettings(database, now, customerTicketPrinterId: 'printer-a');
      await useCase(
        PrintPreviewRequest(
          repairId: repair.id!,
          documentMode: PrintDocumentMode.customerTicket,
          copies: 1,
        ),
      );

      await _saveSettings(database, now, customerTicketPrinterId: 'printer-b');
      await useCase(
        PrintPreviewRequest(
          repairId: repair.id!,
          documentMode: PrintDocumentMode.customerTicket,
          copies: 1,
        ),
      );

      final targets = printerService.printerTargets
          .whereType<SpecificPrintPrinterTarget>()
          .map((target) => target.id);
      expect(targets, ['printer-a', 'printer-b']);
    });

    test(
      'invalid copies and rendering failures return safe failures',
      () async {
        final repair = await _createRepair(database, now);
        final useCase = PrintRepairDocumentUseCase(
          _buildUseCase(database, now),
          _settingsRepository(database),
          const PrinterPreferenceResolver(),
          const QrCodeGenerator(),
          _RecordingRenderer(),
          _RecordingPrinterService(PrintResult.success()),
        );

        final invalidCopies = await useCase(
          PrintPreviewRequest(
            repairId: repair.id!,
            documentMode: PrintDocumentMode.customerTicket,
            copies: 0,
          ),
        );

        expect(invalidCopies.status, PrintResultStatus.failed);
        expect(invalidCopies.failureKind, PrintFailureKind.invalidRequest);

        final renderingFailure =
            await PrintRepairDocumentUseCase(
              _buildUseCase(database, now),
              _settingsRepository(database),
              const PrinterPreferenceResolver(),
              const QrCodeGenerator(),
              const _ThrowingRenderer(),
              _RecordingPrinterService(PrintResult.success()),
            )(
              PrintPreviewRequest(
                repairId: repair.id!,
                documentMode: PrintDocumentMode.customerTicket,
                copies: 1,
              ),
            );

        expect(renderingFailure.status, PrintResultStatus.failed);
        expect(
          renderingFailure.failureKind,
          PrintFailureKind.documentRenderingFailed,
        );
        expect(renderingFailure.message, isNot(contains('boom')));
      },
    );

    test('missing print data returns a safe failure', () async {
      final useCase = PrintRepairDocumentUseCase(
        _buildUseCase(database, now),
        _settingsRepository(database),
        const PrinterPreferenceResolver(),
        const QrCodeGenerator(),
        _RecordingRenderer(),
        _RecordingPrinterService(PrintResult.success()),
      );

      final result = await useCase(
        const PrintPreviewRequest(
          repairId: 404,
          documentMode: PrintDocumentMode.customerTicket,
          copies: 1,
        ),
      );

      expect(result.status, PrintResultStatus.failed);
      expect(result.failureKind, PrintFailureKind.documentRenderingFailed);
      expect(result.message, 'Print data could not be loaded.');
    });

    test('printer failure result is preserved safely', () async {
      final repair = await _createRepair(database, now);
      final useCase = PrintRepairDocumentUseCase(
        _buildUseCase(database, now),
        _settingsRepository(database),
        const PrinterPreferenceResolver(),
        const QrCodeGenerator(),
        _RecordingRenderer(),
        _RecordingPrinterService(
          PrintResult.failed(
            failureKind: PrintFailureKind.noPrinterAvailable,
            message: 'No available printer was found.',
          ),
        ),
      );

      final result = await useCase(
        PrintPreviewRequest(
          repairId: repair.id!,
          documentMode: PrintDocumentMode.customerTicket,
          copies: 1,
        ),
      );

      expect(result.status, PrintResultStatus.failed);
      expect(result.failureKind, PrintFailureKind.noPrinterAvailable);
      expect(result.message, 'No available printer was found.');
    });
  });
}

RenderedPrintDocument _document() {
  return RenderedPrintDocument(
    bytes: Uint8List.fromList([1, 2, 3]),
    pageFormat: PdfPageFormat.a4,
    jobName: 'Test Job',
  );
}

Future<({RenderedPrintDocument document, List<String> printMessages})>
_renderCapturingPrintMessages({
  required RepairPdfDocumentRenderer renderer,
  required RepairPrintData printData,
  required QrCodeSvg qrCode,
  required PrintDocumentMode documentMode,
}) async {
  final printMessages = <String>[];
  final document = await runZoned(
    () {
      return renderer.render(
        printData: printData,
        qrCode: qrCode,
        documentMode: documentMode,
      );
    },
    zoneSpecification: ZoneSpecification(
      print: (self, parent, zone, line) {
        printMessages.add(line);
      },
    ),
  );

  return (document: document, printMessages: printMessages);
}

void _expectNoFontWarnings(List<String> printMessages) {
  expect(
    printMessages.where(_isFontWarning),
    isEmpty,
    reason: 'Printable PDFs must not use the built-in unsupported font path.',
  );
}

bool _isFontWarning(String message) {
  return message.contains('has no Unicode support') ||
      message.contains('Unable to find a font to draw');
}

void _expectUnicodeMappings(String pdfText, String text) {
  final upperPdfText = pdfText.toUpperCase();

  for (final rune in text.runes) {
    if (_ignoredMappedRune(rune)) {
      continue;
    }

    final hex = rune.toRadixString(16).padLeft(4, '0').toUpperCase();
    expect(
      upperPdfText,
      contains('<$hex>'),
      reason:
          'Expected the rendered PDF ToUnicode map to contain '
          'U+$hex for "${String.fromCharCode(rune)}".',
    );
  }
}

void _expectArabicPresentationMappings(String pdfText) {
  expect(
    RegExp(r'<FE[0-9A-F]{2}>').hasMatch(pdfText.toUpperCase()),
    isTrue,
    reason:
        'Expected the rendered PDF ToUnicode map to contain Arabic '
        'presentation forms generated by the pdf package RTL path.',
  );
}

bool _ignoredMappedRune(int rune) {
  return rune == 0x20 || rune == 0x0a || rune == 0x0d;
}

RepairPrintData _printData() {
  final receivedAt = DateTime.utc(2026, 7, 5, 10);
  return RepairPrintData(
    customerTicket: CustomerTicketData(
      shopName: 'Nova Tech',
      shopSubtitle: null,
      shopPhone: '0555 00 11 22',
      shopAddress: 'Chlef, Algeria',
      logoPath: null,
      ticketFooter: 'Keep this ticket.',
      warrantyTerms: 'Warranty terms.',
      repairCode: 'REP-0001',
      receivedAt: receivedAt,
      status: RepairStatus.received,
      customerName: 'Amina Customer',
      customerPhone: '0555 123 456',
      deviceDisplayName: 'HP EliteBook 840',
      deviceType: 'Laptop',
      reportedProblem: 'Does not power on',
      receivedAccessories: 'Charger and bag',
      priceAmount: 6500,
      customerPriceDecision: CustomerPriceDecision.pending,
      isWarrantyReturn: false,
      originalRepairCode: null,
    ),
    deviceLabel: DeviceLabelData(
      repairCode: 'REP-0001',
      receivedAt: receivedAt,
      deviceDisplayName: 'HP EliteBook 840',
      customerName: 'Amina Customer',
      customerPhone: '0555 123 456',
      reportedProblem: 'Does not power on',
    ),
  );
}

RepairPrintData _multilingualPrintData() {
  final receivedAt = DateTime.utc(2026, 7, 5, 10);
  return RepairPrintData(
    customerTicket: CustomerTicketData(
      shopName: 'ورشة نوفا Réparation',
      shopSubtitle: 'Repair Center',
      shopPhone: '0555 99 88 77',
      shopAddress: 'حي السلام، Chlef',
      logoPath: null,
      ticketFooter: 'Merci - Téléphone réparé',
      warrantyTerms: 'Garantie: Écran cassé',
      repairCode: 'REP-0002',
      receivedAt: receivedAt,
      status: RepairStatus.received,
      customerName: 'أمين Benali',
      customerPhone: '0555 99 88 77',
      deviceDisplayName: 'HP EliteBook 840 جهاز',
      deviceType: 'Téléphone',
      reportedProblem: 'الشاشة لا تعمل - Écran cassé',
      receivedAccessories: 'شاحن USB-C',
      priceAmount: 6500,
      customerPriceDecision: CustomerPriceDecision.pending,
      isWarrantyReturn: false,
      originalRepairCode: null,
    ),
    deviceLabel: DeviceLabelData(
      repairCode: 'REP-0002',
      receivedAt: receivedAt,
      deviceDisplayName: 'HP EliteBook 840 جهاز',
      customerName: 'أمين Benali',
      customerPhone: '0555 99 88 77',
      reportedProblem: 'الشاشة لا تعمل - Écran cassé',
    ),
  );
}

class _FakePrintingPlatformClient implements PrintingPlatformClient {
  _FakePrintingPlatformClient({
    required this.printers,
    this.submitResult = true,
    this.throwsOnSubmit = false,
  });

  final List<PrintingPrinterSnapshot> printers;
  final bool submitResult;
  final bool throwsOnSubmit;
  final printedPrinterIds = <String>[];

  @override
  Future<List<PrintingPrinterSnapshot>> listPrinters() async {
    return printers;
  }

  @override
  Future<bool> directPrintPdf({
    required PrintingPrinterSnapshot printer,
    required Uint8List bytes,
    required PdfPageFormat pageFormat,
    required String jobName,
  }) async {
    if (throwsOnSubmit) {
      throw StateError('platform boom');
    }

    printedPrinterIds.add(printer.id);
    return submitResult;
  }
}

class _RecordingRenderer implements PrintDocumentRenderer {
  final documentModes = <PrintDocumentMode>[];
  final qrPayloads = <String>[];

  @override
  Future<RenderedPrintDocument> render({
    required RepairPrintData printData,
    required QrCodeSvg qrCode,
    required PrintDocumentMode documentMode,
  }) async {
    documentModes.add(documentMode);
    qrPayloads.add(qrCode.payload);
    return _document();
  }
}

class _ThrowingRenderer implements PrintDocumentRenderer {
  const _ThrowingRenderer();

  @override
  Future<RenderedPrintDocument> render({
    required RepairPrintData printData,
    required QrCodeSvg qrCode,
    required PrintDocumentMode documentMode,
  }) {
    throw StateError('render boom');
  }
}

class _RecordingPrinterService implements LocalPrinterService {
  _RecordingPrinterService(this.result);

  final PrintResult result;
  final printerTargets = <PrintPrinterTarget>[];
  final copies = <int>[];

  @override
  Future<LocalPrinter?> getDefaultPrinter() async {
    return const LocalPrinter(
      id: 'default',
      displayName: 'Default Printer',
      isDefault: true,
    );
  }

  @override
  Future<List<LocalPrinter>> listPrinters() async {
    return [await getDefaultPrinter()].whereType<LocalPrinter>().toList();
  }

  @override
  Future<PrintResult> printDocument({
    required PrintPrinterTarget printerTarget,
    required RenderedPrintDocument document,
    required int copies,
  }) async {
    printerTargets.add(printerTarget);
    this.copies.add(copies);
    return result;
  }
}

BuildRepairPrintDataUseCase _buildUseCase(AppDatabase database, DateTime now) {
  return BuildRepairPrintDataUseCase(
    _repairRepository(database, () => now),
    _settingsRepository(database),
  );
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
      ticketFooter: 'Keep this ticket.',
      warrantyTerms: 'Warranty terms.',
      defaultCustomerTicketPrinterId: customerTicketPrinterId,
      defaultDeviceLabelPrinterId: deviceLabelPrinterId,
      createdAt: now,
      updatedAt: now,
    ),
  );
}

Future<Repair> _createRepair(AppDatabase database, DateTime now) {
  return _repairRepository(database, () => now).createRepair(
    CreateRepairInput(
      customerName: 'Amina Customer',
      customerPhone: '0555 123 456',
      deviceType: 'Laptop',
      brand: 'HP',
      model: 'EliteBook 840',
      reportedProblem: 'Does not power on',
      receivedAccessories: 'Charger and bag',
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
