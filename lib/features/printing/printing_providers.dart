import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../online_tracking/application/build_public_tracking_url.dart';
import '../online_tracking/online_tracking_providers.dart';
import '../repairs/repair_providers.dart';
import '../settings/settings_providers.dart';
import 'application/build_repair_print_data_use_case.dart';
import 'application/build_repair_qr_payload.dart';
import 'application/local_printer_service.dart';
import 'application/print_document_renderer.dart';
import 'application/print_repair_document_use_case.dart';
import 'application/printer_preference_resolver.dart';
import 'infrastructure/pdf/repair_pdf_document_renderer.dart';
import 'infrastructure/printers/printing_local_printer_service.dart';
import 'infrastructure/printers/printing_platform_client.dart';
import 'infrastructure/qr/qr_code_generator.dart';

final qrCodeGeneratorProvider = Provider<QrCodeGenerator>((ref) {
  return const QrCodeGenerator();
});

final buildRepairPrintDataUseCaseProvider =
    Provider<BuildRepairPrintDataUseCase>((ref) {
      return BuildRepairPrintDataUseCase(
        ref.watch(repairRepositoryProvider),
        ref.watch(shopSettingsRepositoryProvider),
        qrPayloadBuilder: ref.watch(buildRepairQrPayloadProvider),
      );
    });

final buildRepairQrPayloadProvider = Provider<BuildRepairQrPayload>((ref) {
  return BuildRepairQrPayload(
    trackingUrlBuilder: BuildPublicTrackingUrl(
      config: ref.watch(onlineTrackingWebConfigProvider),
    ),
  );
});

final printDocumentRendererProvider = Provider<PrintDocumentRenderer>((ref) {
  return const RepairPdfDocumentRenderer();
});

final printerPreferenceResolverProvider = Provider<PrinterPreferenceResolver>((
  ref,
) {
  return const PrinterPreferenceResolver();
});

final printingPlatformClientProvider = Provider<PrintingPlatformClient>((ref) {
  return const PrintingPackagePlatformClient();
});

final localPrinterServiceProvider = Provider<LocalPrinterService>((ref) {
  return PrintingLocalPrinterService(ref.watch(printingPlatformClientProvider));
});

final printRepairDocumentUseCaseProvider = Provider<PrintRepairDocumentUseCase>(
  (ref) {
    return PrintRepairDocumentUseCase(
      ref.watch(buildRepairPrintDataUseCaseProvider),
      ref.watch(shopSettingsRepositoryProvider),
      ref.watch(printerPreferenceResolverProvider),
      ref.watch(qrCodeGeneratorProvider),
      ref.watch(printDocumentRendererProvider),
      ref.watch(localPrinterServiceProvider),
    );
  },
);
