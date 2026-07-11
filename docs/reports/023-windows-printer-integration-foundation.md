# Prompt 023 — Windows Printer Integration Foundation

## Summary

Implemented the local printer integration foundation for the existing Print Preview request boundary. Print Preview now submits real print requests through an app-owned print use case, renders customer tickets and device labels as in-memory PDF print documents, resolves the system default local printer through a focused infrastructure service, sends jobs through the Flutter `printing` package, prevents duplicate submissions, and shows honest success or failure feedback.

No new screen, Print Preview redesign, Settings UI, printer preference persistence, print history, PDF export, Save as PDF, cloud printing, online tracking, schema change, or sample data was added.

## Previous State Reviewed

Reports `docs/reports/001-project-foundation.md` through `docs/reports/022-print-preview-ui.md` were read.

Relevant starting state:

- Print Preview already existed for customer tickets and device labels.
- `PrintPreviewRequest` already carried `repairId`, document mode, copy count, and `systemDefault` printer target.
- Print Preview still showed the temporary message `Printer integration is not available yet.`
- Print data and QR generation foundations already existed.
- No local printer discovery, print service, printable document renderer, OS print submission, PDF transport, or printer result model existed.

## Existing Printing Capability Review

Before this task:

- There was no `printing` or `pdf` dependency.
- Windows plugin registration did not include a printing plugin.
- Print Preview rendered Flutter preview widgets only.
- Pressing Print produced an informational boundary message and did not call a printer API.
- QR generation existed, but only for in-memory SVG output used by the preview.
- No printer model, printer service, printer result model, document renderer, or platform boundary existed.

## Files Inspected

- `docs/reports/001-project-foundation.md`
- `docs/reports/002-repair-domain-database.md`
- `docs/reports/003-shop-settings-foundation.md`
- `docs/reports/004-repair-creation-workflow.md`
- `docs/reports/005-repair-query-foundation.md`
- `docs/reports/006-repair-status-workflow.md`
- `docs/reports/007-customer-price-approval-workflow.md`
- `docs/reports/008-warranty-return-workflow.md`
- `docs/reports/009-repair-search-filter-logic.md`
- `docs/reports/010-ready-delayed-repair-logic.md`
- `docs/reports/011-ticket-print-data-foundation.md`
- `docs/reports/012-qr-generation-foundation.md`
- `docs/reports/013-local-backup-restore-foundation.md`
- `docs/reports/014-shared-ui-foundation.md`
- `docs/reports/015-dashboard-ui.md`
- `docs/reports/016-repairs-list-ui.md`
- `docs/reports/017-new-repair-ui.md`
- `docs/reports/018-repair-details-ui.md`
- `docs/reports/019-change-status-dialog.md`
- `docs/reports/020-repair-update-workflow-foundation.md`
- `docs/reports/021-edit-repair-ui.md`
- `docs/reports/022-print-preview-ui.md`
- Attached Prompt 023 request text
- `design_reference/NOVA_REPAIR_UI_SPEC.md`
- `pubspec.yaml`
- `lib/app/app_shell.dart`
- `lib/app/theme/app_colors.dart`
- `lib/app/widgets/buttons/app_buttons.dart`
- `lib/features/printing/application/build_repair_print_data_use_case.dart`
- `lib/features/printing/domain/entities/customer_ticket_data.dart`
- `lib/features/printing/domain/entities/device_label_data.dart`
- `lib/features/printing/domain/entities/repair_print_data.dart`
- `lib/features/printing/infrastructure/qr/qr_code_generator.dart`
- `lib/features/printing/infrastructure/qr/qr_code_request.dart`
- `lib/features/printing/infrastructure/qr/qr_code_svg.dart`
- `lib/features/printing/presentation/print_document_mode.dart`
- `lib/features/printing/presentation/print_preview_controller.dart`
- `lib/features/printing/presentation/print_preview_page.dart`
- `lib/features/printing/presentation/print_preview_request.dart`
- `lib/features/printing/presentation/print_preview_state.dart`
- `lib/features/printing/presentation/widgets/customer_ticket_preview.dart`
- `lib/features/printing/presentation/widgets/device_label_preview.dart`
- `lib/features/printing/presentation/widgets/print_preview_shell.dart`
- `lib/features/printing/presentation/widgets/qr_svg_view.dart`
- Existing printing, QR, Repair Details, New Repair, and app shell tests
- Local installed `qr`, `printing`, and `pdf` package APIs after dependency resolution

## Files Created

- `lib/features/printing/domain/entities/local_printer.dart`
- `lib/features/printing/domain/entities/print_result.dart`
- `lib/features/printing/application/local_printer_service.dart`
- `lib/features/printing/application/print_document_renderer.dart`
- `lib/features/printing/application/print_repair_document_use_case.dart`
- `lib/features/printing/application/rendered_print_document.dart`
- `lib/features/printing/infrastructure/pdf/repair_pdf_document_renderer.dart`
- `lib/features/printing/infrastructure/printers/printing_local_printer_service.dart`
- `lib/features/printing/infrastructure/printers/printing_platform_client.dart`
- `test/features/printing/infrastructure/printer_integration_test.dart`
- `docs/reports/023-windows-printer-integration-foundation.md`

## Files Modified

- `.flutter-plugins-dependencies`
- `lib/app/app_shell.dart`
- `lib/app/theme/app_colors.dart`
- `lib/app/widgets/buttons/app_buttons.dart`
- `lib/features/printing/infrastructure/qr/qr_code_generator.dart`
- `lib/features/printing/printing_providers.dart`
- `lib/features/printing/presentation/print_preview_controller.dart`
- `lib/features/printing/presentation/print_preview_page.dart`
- `lib/features/printing/presentation/print_preview_state.dart`
- `lib/features/printing/presentation/widgets/print_preview_shell.dart`
- `pubspec.yaml`
- `pubspec.lock`
- `test/features/printing/infrastructure/qr/qr_code_generator_test.dart`
- `test/features/printing/presentation/print_preview_test.dart`
- `windows/flutter/generated_plugin_registrant.cc`
- `windows/flutter/generated_plugins.cmake`

## Dependency Decision

Added:

- `printing`: selected as the focused Flutter printing package because it supports printer discovery and print submission through platform plugins, including Windows plugin registration.
- `pdf`: selected because the `printing` package print API expects printable document bytes, and `pdf` is the companion package for generating those bytes in memory.

Changed:

- `qr` was changed from `^4.0.0` to `^3.0.2` because `printing`/`pdf` depend on `barcode`, which currently depends on `qr ^3.0.0`. The existing QR generator was adjusted to the `qr` 3.x API while preserving the same app-level QR behavior.

Resolved versions after dependency resolution:

- `printing 5.14.3`
- `pdf 3.12.0`
- `qr 3.0.2`

The first attempt to add `printing` and `pdf` failed because of the `qr` version conflict. The compatible dependency set above resolved successfully.

## Printer Architecture

The print flow now follows:

```text
Print Preview
↓
PrintPreviewRequest
↓
PrintRepairDocumentUseCase
↓
BuildRepairPrintDataUseCase + QrCodeGenerator
↓
PrintDocumentRenderer
↓
LocalPrinterService
↓
PrintingPlatformClient
↓
printing package / platform print system
```

App-owned abstractions:

- `LocalPrinter`
- `PrintResult`
- `LocalPrinterService`
- `PrintDocumentRenderer`
- `RenderedPrintDocument`
- `PrintRepairDocumentUseCase`

Infrastructure:

- `RepairPdfDocumentRenderer` renders in-memory PDF bytes.
- `PrintingLocalPrinterService` resolves printer targets and submits print jobs.
- `PrintingPlatformClient` isolates `printing` package types from the rest of the app.

Preview widgets and Repair Details do not import package-specific printer types.

## Printer Discovery

`LocalPrinterService.listPrinters()` exposes app-owned `LocalPrinter` values.

`PrintingLocalPrinterService` uses `Printing.listPrinters()` through `PrintingPlatformClient` and maps discovered printers to:

- stable identifier
- display name
- default flag
- availability flag

The app does not invent printer names or hard-code sample printer devices.

## System Default Printer

`PrintPreviewPrinterTarget.systemDefault` was preserved.

Resolution behavior:

1. Prefer the discovered printer marked default and available.
2. If no explicit default is available, fall back to the first available local printer.
3. If no available printer exists, return a structured `noPrinterAvailable` failure.

The current Print Preview UI still displays `Default Printer`; no printer dropdown or persistent printer preference was added.

## Document Rendering

Printable documents are rendered as in-memory PDF bytes through `RepairPdfDocumentRenderer`.

This PDF is only a transport format for the local print subsystem. The implementation does not expose PDF export, does not add Save as PDF, and does not persist generated PDF files.

The renderer produces:

- one customer-ticket document for `PrintDocumentMode.customerTicket`
- one compact device-label document for `PrintDocumentMode.deviceLabel`

Rendering failures are converted into a safe `documentRenderingFailed` result.

## Customer Ticket Print Layout

Included fields:

- shop name
- shop phone when present
- shop address when present
- visible repair code
- `Received Date`
- customer name
- customer phone
- device display name
- device type
- reported problem
- received accessories
- real QR code
- visible repair code near the QR
- ticket footer when present
- warranty terms when present

Excluded fields:

- proposed price
- customer price decision
- device access information
- internal notes
- customer-visible message
- internal database ID
- tracking URL
- tracking token

## Device Label Print Layout

Included fields:

- shop name
- visible repair code
- device display name
- customer name when present
- customer phone when present
- real QR code

Excluded fields:

- reported problem
- received accessories
- proposed price
- customer price decision
- device access information
- internal notes
- customer-visible message
- warranty information
- internal database ID
- tracking URL
- tracking token

## QR Printing

The printed QR uses the existing `QrCodeGenerator`.

Payload:

- visible repair code only, such as `REP-0001`

The payload is not a tracking URL, random token, online endpoint, customer account reference, or cloud identifier.

The QR is embedded into the PDF as vector SVG content. No QR files are persisted.

## Paper/Layout Strategy

Customer Ticket:

- Uses `PdfPageFormat.roll80`, a practical 80mm receipt-style format.
- The layout is simple and can still be handled by standard printer drivers that support fallback scaling.

Device Label:

- Uses a compact explicit format of approximately `60mm × 40mm` with small margins.

Actual printer support for exact paper sizes remains driver-dependent. The app does not claim every printer can honor the requested physical dimensions.

## Print Execution

`PrintRepairDocumentUseCase` executes the request:

1. Validate copies are within `1..99`.
2. Load fresh print data by repair ID.
3. Generate QR SVG from the visible repair code.
4. Render the requested document mode.
5. Resolve the printer target through `LocalPrinterService`.
6. Submit the rendered document.
7. Return `PrintResult`.

The print use case does not print stale preview widget state.

## Copies

Copy count remains valid only from `1` to `99`.

Invalid copy counts return `PrintFailureKind.invalidRequest`.

The current `printing` API path used here does not expose a native copy-count option for direct print submission, so `PrintingLocalPrinterService` submits one print job per requested copy. This avoids creating a large multi-copy PDF document in memory.

## Print Result and Errors

`PrintResultStatus`:

- `success`
- `cancelled`
- `failed`

Failure kinds:

- `invalidRequest`
- `noPrinterAvailable`
- `printerTargetUnavailable`
- `documentRenderingFailed`
- `printSubmissionFailed`

Messages are user-safe and do not include platform stack traces, SQL details, or sensitive repair contents.

Success wording is:

`Print job sent successfully.`

This intentionally confirms job submission, not guaranteed physical paper output.

## Print Preview Integration

The temporary message `Printer integration is not available yet.` was removed.

Pressing Print now:

1. Builds the current `PrintPreviewRequest`.
2. Calls `PrintRepairDocumentUseCase`.
3. Disables the Print button while submission is in progress.
4. Prevents duplicate submissions.
5. Preserves selected document mode and copy count.
6. Shows a success message only after the print subsystem reports success.
7. Shows a safe error message when printing fails.
8. Remains on Print Preview.

Back navigation remains available while submitting; the implementation does not block Back because the chosen API submission is short-lived and cancellation is owned by the platform print layer.

## Settings Preparation

The infrastructure is ready for future printer preference work:

- `LocalPrinterService.listPrinters()` can feed future Settings UI.
- `LocalPrinter.id` and `displayName` provide app-owned values for future persistence decisions.
- `PrintPreviewPrinterTarget.systemDefault` remains the only active target in this prompt.

No shop settings fields, printer settings tables, Settings UI, or persisted printer selection was added.

## Database Schema

Schema version remains `4`.

No tables, columns, indexes, migrations, generated Drift files, print history tables, printer preference tables, document snapshot tables, QR tables, or tracking tables were added.

## Dependencies

Added:

- `printing`: local printer discovery and print submission foundation.
- `pdf`: in-memory printable document rendering for the print subsystem.

Changed:

- `qr`: changed to `^3.0.2` for compatibility with the selected printing stack.
- `pubspec.lock` updated by dependency resolution.
- Windows plugin generated files updated to register the `printing` plugin.

Removed: none.

## Tests Added

- `test/features/printing/infrastructure/printer_integration_test.dart`
  - Printer discovery maps package data into app-owned `LocalPrinter` models.
  - System-default printer target maps to the discovered default printer.
  - Available-printer fallback works when no explicit default exists.
  - No-printer state fails safely.
  - Copy count submits repeated print jobs when native copies are unavailable.
  - Printer cancellation and submission failures return safe results.
  - Customer-ticket PDF contains approved fields and excludes sensitive fields.
  - Device-label PDF contains only compact approved fields and excludes unapproved fields.
  - Print use case renders customer tickets and device labels through the right mode.
  - Print use case forwards copies and system-default target.
  - Invalid copies fail safely.
  - Missing print data and rendering failures return safe failures.
  - Printer failure results are preserved safely.

Updated:

- `test/features/printing/presentation/print_preview_test.dart`
  - Print invokes the real print service boundary.
  - Duplicate submission is prevented.
  - Success feedback appears only after successful submission.
  - Failure feedback is honest and preserves mode/copies.

- `test/features/printing/infrastructure/qr/qr_code_generator_test.dart`
  - Adjusted to the compatible `qr` 3.x package API while preserving app-level behavior.

## Validation Commands

- `flutter pub add printing:^5.14.2 pdf:^3.11.3 qr:^3.0.2`
- `dart format lib/features/printing/application/print_repair_document_use_case.dart test/features/printing/infrastructure/printer_integration_test.dart`
- `flutter test test/features/printing/infrastructure/printer_integration_test.dart`
- `flutter analyze`
- `flutter test test/features/printing/presentation/print_preview_test.dart`
- `flutter test test/features/printing/infrastructure/qr/qr_code_generator_test.dart`
- `flutter pub get`
- `dart format .`
- `flutter analyze`
- `flutter test`
- `flutter build windows`
- `git status --short`

Earlier attempted command:

- `flutter pub add printing pdf`

## Validation Results

Dependency resolution:

- Initial `flutter pub add printing pdf` failed because the existing `qr ^4.0.0` constraint conflicted with the `printing`/`pdf` stack through `barcode`.
- `flutter pub add printing:^5.14.2 pdf:^3.11.3 qr:^3.0.2` succeeded.
- Final `flutter pub get` succeeded.
- Flutter reported 17 packages with newer versions incompatible with current constraints.

Code generation:

- Not run because no Drift schema or generated-code inputs changed.

Formatting:

- `dart format .` succeeded.

Static analysis:

- `flutter analyze` reported no issues.

Focused printer integration tests:

- `flutter test test/features/printing/infrastructure/printer_integration_test.dart` passed.
- The PDF package printed Helvetica Unicode-support notices during PDF-rendering tests. The tests still passed. This is a package/font limitation to revisit if printed multilingual text becomes a requirement.

Focused Print Preview tests:

- `flutter test test/features/printing/presentation/print_preview_test.dart` passed.

QR tests:

- `flutter test test/features/printing/infrastructure/qr/qr_code_generator_test.dart` passed.

All tests:

- `flutter test` passed all tests.

Actual Windows platform validation:

- `flutter build windows` was attempted but could not run because the current host is not Windows. Flutter returned: `"build windows" only supported on Windows hosts.`

Printer hardware validation:

- Not performed. Automated tests use fakes for platform printer APIs and do not require a physical printer.

Repository status check:

- `git status --short` failed because the working directory did not appear to be a Git repository.

## Issues or Limitations

- Windows build validation remains blocked by the current non-Windows environment.
- Physical printer testing was not performed.
- Driver behavior, exact paper sizing, margins, and printable area remain printer-dependent.
- The device label uses an explicit `60mm × 40mm` layout, but not every printer or driver will support that exact size.
- The customer ticket uses an 80mm receipt-style PDF format, but standard printers may scale or adapt it based on driver settings.
- The current direct-print path submits one print job per copy because native copy-count support is not exposed by the selected API path.
- Default printer selection is resolved at print time; no printer preference persistence exists yet.
- Settings UI is deferred.
- Customer-ticket printer and device-label printer settings are deferred.
- PDF export and Save as PDF remain out of scope.
- Print history and document snapshots are not persisted.
- Cloud printing, online tracking, tracking URLs, and tracking tokens remain out of scope.
- The PDF renderer currently uses default PDF fonts. Package warnings indicate limited Unicode support for those built-in fonts.

## Next Safe Step

The next safe step is Settings UI implementation using the approved Stitch reference.

Before implementation, inspect whether Shop Settings needs focused model changes for:

- shop subtitle
- default customer-ticket printer
- default device-label printer

Do not implement Settings UI in this prompt.
