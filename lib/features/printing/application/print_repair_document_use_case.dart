import 'build_repair_print_data_use_case.dart';
import 'local_printer_service.dart';
import 'print_document_renderer.dart';
import 'printer_preference_resolver.dart';
import '../domain/entities/print_result.dart';
import '../infrastructure/qr/qr_code_generator.dart';
import '../infrastructure/qr/qr_code_request.dart';
import '../presentation/print_document_mode.dart';
import '../presentation/print_preview_request.dart';
import '../presentation/print_preview_state.dart';
import '../../settings/domain/repositories/shop_settings_repository.dart';

class PrintRepairDocumentUseCase {
  const PrintRepairDocumentUseCase(
    this._buildPrintData,
    this._shopSettingsRepository,
    this._printerPreferenceResolver,
    this._qrCodeGenerator,
    this._renderer,
    this._printerService,
  );

  final BuildRepairPrintDataUseCase _buildPrintData;
  final ShopSettingsRepository _shopSettingsRepository;
  final PrinterPreferenceResolver _printerPreferenceResolver;
  final QrCodeGenerator _qrCodeGenerator;
  final PrintDocumentRenderer _renderer;
  final LocalPrinterService _printerService;

  Future<PrintResult> call(PrintPreviewRequest request) async {
    if (request.copies < PrintPreviewState.minCopies ||
        request.copies > PrintPreviewState.maxCopies) {
      return PrintResult.failed(
        failureKind: PrintFailureKind.invalidRequest,
        message: 'Copy count must be between 1 and 99.',
      );
    }

    final printData = await (() async {
      try {
        return await _buildPrintData(request.repairId);
      } catch (_) {
        return null;
      }
    })();

    if (printData == null) {
      return PrintResult.failed(
        failureKind: PrintFailureKind.documentRenderingFailed,
        message: 'Print data could not be loaded.',
      );
    }

    final settings = await (() async {
      try {
        return await _shopSettingsRepository.getSettings();
      } catch (_) {
        return null;
      }
    })();

    if (settings == null) {
      return PrintResult.failed(
        failureKind: PrintFailureKind.invalidRequest,
        message: 'Printer settings could not be loaded.',
      );
    }

    final printerTarget = _printerPreferenceResolver.resolve(
      documentMode: request.documentMode,
      settings: settings,
    );

    final qrPayload = switch (request.documentMode) {
      PrintDocumentMode.customerTicket =>
        printData.customerTicket.qrPayload ??
            printData.customerTicket.repairCode,
      PrintDocumentMode.deviceLabel => printData.deviceLabel.repairCode,
    };
    final qrCode = _qrCodeGenerator.generateSvg(
      QrCodeRequest(payload: qrPayload, size: 192),
    );

    final renderedDocument = await (() async {
      try {
        return await _renderer.render(
          printData: printData,
          qrCode: qrCode,
          documentMode: request.documentMode,
        );
      } catch (_) {
        return null;
      }
    })();

    if (renderedDocument == null) {
      return PrintResult.failed(
        failureKind: PrintFailureKind.documentRenderingFailed,
        message: 'The print document could not be prepared.',
      );
    }

    return _printerService.printDocument(
      printerTarget: printerTarget,
      document: renderedDocument,
      copies: request.copies,
    );
  }
}
