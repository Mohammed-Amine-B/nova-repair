import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/repair_print_data.dart';
import '../domain/entities/print_result.dart';
import '../infrastructure/qr/qr_code_request.dart';
import '../infrastructure/qr/qr_code_svg.dart';
import '../printing_providers.dart';
import '../../settings/settings_providers.dart';
import 'print_document_mode.dart';
import 'print_preview_request.dart';
import 'print_preview_state.dart';

class PrintPreviewData {
  const PrintPreviewData({
    required this.printData,
    required this.customerTicketQrCode,
    required this.deviceLabelQrCode,
  });

  final RepairPrintData printData;
  final QrCodeSvg customerTicketQrCode;
  final QrCodeSvg deviceLabelQrCode;

  QrCodeSvg get qrCode => customerTicketQrCode;
}

class PrintPreviewPrinterDisplay {
  const PrintPreviewPrinterDisplay({
    required this.label,
    this.isUnavailable = false,
  });

  final String label;
  final bool isUnavailable;
}

final printPreviewDataProvider = FutureProvider.autoDispose
    .family<PrintPreviewData, int>((ref, repairId) async {
      final printData = await ref.watch(buildRepairPrintDataUseCaseProvider)(
        repairId,
      );
      final qrCodeGenerator = ref.watch(qrCodeGeneratorProvider);
      final customerTicketQrCode = qrCodeGenerator.generateSvg(
        QrCodeRequest(
          payload:
              printData.customerTicket.qrPayload ??
              printData.customerTicket.repairCode,
          size: 128,
        ),
      );
      final deviceLabelQrCode = qrCodeGenerator.generateSvg(
        QrCodeRequest(payload: printData.deviceLabel.repairCode, size: 128),
      );

      return PrintPreviewData(
        printData: printData,
        customerTicketQrCode: customerTicketQrCode,
        deviceLabelQrCode: deviceLabelQrCode,
      );
    });

final printPreviewPrinterDisplayProvider = FutureProvider.autoDispose
    .family<PrintPreviewPrinterDisplay, PrintDocumentMode>((ref, mode) async {
      final settings = await ref
          .watch(shopSettingsRepositoryProvider)
          .getSettings();
      final printerId = switch (mode) {
        PrintDocumentMode.customerTicket =>
          settings.defaultCustomerTicketPrinterId,
        PrintDocumentMode.deviceLabel => settings.defaultDeviceLabelPrinterId,
      };

      if (printerId == null) {
        return const PrintPreviewPrinterDisplay(label: 'Default Printer');
      }

      final printers = await ref
          .watch(localPrinterServiceProvider)
          .listPrinters();
      for (final printer in printers) {
        if (printer.id == printerId && printer.isAvailable) {
          return PrintPreviewPrinterDisplay(label: printer.displayName);
        }
      }

      return const PrintPreviewPrinterDisplay(
        label: 'Unavailable printer',
        isUnavailable: true,
      );
    });

final printPreviewControllerProvider = NotifierProvider.autoDispose
    .family<PrintPreviewController, PrintPreviewState, PrintDocumentMode>(
      PrintPreviewController.new,
    );

class PrintPreviewController extends Notifier<PrintPreviewState> {
  PrintPreviewController(this.initialMode);

  final PrintDocumentMode initialMode;

  @override
  PrintPreviewState build() {
    return PrintPreviewState(documentMode: initialMode);
  }

  void selectMode(PrintDocumentMode mode) {
    state = state.copyWith(documentMode: mode, clearFeedback: true);
  }

  void incrementCopies() {
    if (state.copies >= PrintPreviewState.maxCopies) {
      return;
    }

    state = state.copyWith(copies: state.copies + 1, clearFeedback: true);
  }

  void decrementCopies() {
    if (state.copies <= PrintPreviewState.minCopies) {
      return;
    }

    state = state.copyWith(copies: state.copies - 1, clearFeedback: true);
  }

  PrintPreviewRequest buildRequest(int repairId) {
    return PrintPreviewRequest(
      repairId: repairId,
      documentMode: state.documentMode,
      copies: state.copies,
    );
  }

  Future<PrintResult> submitPrint(int repairId) async {
    if (state.isSubmitting) {
      return PrintResult.failed(
        failureKind: PrintFailureKind.invalidRequest,
        message: 'A print job is already being submitted.',
      );
    }

    final request = buildRequest(repairId);
    state = state.copyWith(isSubmitting: true, clearFeedback: true);

    final result = await ref.read(printRepairDocumentUseCaseProvider)(request);

    state = state.copyWith(
      isSubmitting: false,
      successMessage: result.isSuccess ? result.message : null,
      errorMessage: result.isSuccess ? null : result.message,
    );

    return result;
  }
}
