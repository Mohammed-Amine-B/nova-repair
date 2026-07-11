# Prompt 027 — Printer Preference Execution Wiring

## Summary

Wired persisted printer preferences into real print execution. Customer-ticket prints now use `ShopSettings.defaultCustomerTicketPrinterId`, device-label prints use `ShopSettings.defaultDeviceLabelPrinterId`, and `null` preferences preserve the existing system-default printer behavior.

The print workflow now loads fresh settings at print time, resolves an effective app-owned printer target in the printing application layer, submits to a specific saved printer ID when configured, and fails safely if that saved printer is unavailable.

No new screen, Settings redesign, Print Preview redesign, Backup & Restore UI, printer management, print history, QR behavior change, schema change, or dependency change was added.

## Previous State Reviewed

Reports `docs/reports/001-project-foundation.md` through `docs/reports/026-settings-ui.md` were read.

Relevant starting state:

- Drift schema version was `5`.
- Settings persisted `defaultCustomerTicketPrinterId` and `defaultDeviceLabelPrinterId`.
- `null` already represented system default printer.
- `LocalPrinterService` and Windows print submission existed.
- `PrintRepairDocumentUseCase` rendered and printed real PDF documents.
- Print Preview still built requests with only `PrintPreviewPrinterTarget.systemDefault`.
- Saved printer preferences were displayed in Settings but were not used during print execution.

`design_reference/NOVA_REPAIR_UI_SPEC.md` was inspected. No visual redesign was required for this prompt.

## Existing Gap

Before this change, printer preferences were persisted but ignored by print execution.

Every Print Preview submission produced a request targeting the system default printer, regardless of:

- `ShopSettings.defaultCustomerTicketPrinterId`
- `ShopSettings.defaultDeviceLabelPrinterId`

This meant Settings could save preferences that real print jobs did not honor.

## Files Inspected

- Prompt 027 attachment text
- `docs/reports/001-project-foundation.md` through `docs/reports/026-settings-ui.md`
- `design_reference/NOVA_REPAIR_UI_SPEC.md`
- `lib/features/printing/application/print_repair_document_use_case.dart`
- `lib/features/printing/application/local_printer_service.dart`
- `lib/features/printing/infrastructure/printers/printing_local_printer_service.dart`
- `lib/features/printing/infrastructure/printers/printing_platform_client.dart`
- `lib/features/printing/presentation/print_preview_request.dart`
- `lib/features/printing/presentation/print_preview_controller.dart`
- `lib/features/printing/presentation/print_preview_page.dart`
- `lib/features/printing/presentation/widgets/print_preview_shell.dart`
- `lib/features/printing/printing_providers.dart`
- `lib/features/settings/domain/entities/shop_settings.dart`
- `lib/features/settings/domain/repositories/shop_settings_repository.dart`
- `lib/features/settings/settings_providers.dart`
- Existing printer integration, Print Preview, Settings, and app shell tests

## Files Created

- `lib/features/printing/application/print_printer_target.dart`
- `lib/features/printing/application/printer_preference_resolver.dart`
- `docs/reports/027-printer-preference-execution-wiring.md`

## Files Modified

- `lib/features/printing/application/local_printer_service.dart`
- `lib/features/printing/application/print_repair_document_use_case.dart`
- `lib/features/printing/infrastructure/printers/printing_local_printer_service.dart`
- `lib/features/printing/printing_providers.dart`
- `lib/features/printing/presentation/print_preview_request.dart`
- `lib/features/printing/presentation/print_preview_controller.dart`
- `lib/features/printing/presentation/print_preview_page.dart`
- `lib/features/printing/presentation/widgets/print_preview_shell.dart`
- `test/features/printing/infrastructure/printer_integration_test.dart`
- `test/features/printing/presentation/print_preview_test.dart`
- `test/features/settings/settings_page_test.dart`
- `test/app_shell_test.dart`

## Preference Resolution

Added `PrinterPreferenceResolver`.

Rules:

- Customer Ticket:
  - `defaultCustomerTicketPrinterId == null` -> system default
  - otherwise -> exact saved printer ID

- Device Label:
  - `defaultDeviceLabelPrinterId == null` -> system default
  - otherwise -> exact saved printer ID

Customer-ticket and device-label preferences are independent.

## Printer Target Model

Added app-owned `PrintPrinterTarget`:

- `PrintPrinterTarget.systemDefault()`
- `PrintPrinterTarget.printerId(String id)`

Package-specific printer objects are still isolated inside printer infrastructure.

`PrintPreviewRequest` was simplified to presentation intent only:

- `repairId`
- `documentMode`
- `copies`

It no longer carries a printer target because printer preference resolution is now owned by printing application coordination.

## System Default Behavior

For `PrintPrinterTarget.systemDefault()`, existing Prompt 023 behavior is preserved:

1. prefer the discovered available default printer
2. otherwise use the first available printer
3. fail if no printer is available

The user-safe no-printer message is:

`No printer is available.`

## Specific Printer Resolution

For `PrintPrinterTarget.printerId(id)`:

1. discover available printers through `LocalPrinterService` infrastructure
2. match by exact `LocalPrinter.id`
3. require the matched printer to be available
4. submit to that printer only

Display name is not used as an identifier. Partial matching is not used.

## Unavailable Printer Policy

If a saved printer ID is configured but unavailable, printing fails safely with:

`The selected printer is unavailable.`

There is no silent fallback to system default or another printer. This protects customer and device information from being printed to an unexpected location.

## Settings Freshness

`PrintRepairDocumentUseCase` loads settings fresh for every print attempt through `ShopSettingsRepository.getSettings()`.

Tests confirm:

1. save ticket printer A
2. print
3. change setting to printer B
4. print again
5. printer B is used without app restart

## Print Execution Flow

Updated flow:

1. validate copy count
2. load fresh print data
3. load fresh shop settings
4. resolve effective printer target from document mode and settings
5. generate QR from the visible repair code
6. render the PDF document
7. resolve the effective printer through `LocalPrinterService`
8. submit the print job
9. return `PrintResult`

The QR payload remains the visible repair code only.

## Print Preview Display

Print Preview still has no printer selector.

The read-only printer display now reflects the effective configured printer where possible:

- null preference -> `Default Printer`
- saved available printer -> real `LocalPrinter.displayName`
- saved unavailable printer -> `Unavailable printer`

If printer display resolution itself fails, the preview shows the safe unavailable label instead of raw plugin details.

## Error Handling

Focused safe messages:

- configured printer unavailable: `The selected printer is unavailable.`
- no printer available: `No printer is available.`
- print submission failure: `The print job could not be sent.`

Raw printer driver errors, platform exceptions, stack traces, and plugin details are not surfaced to the UI.

## Architecture Changes

Added:

- `PrintPrinterTarget`
- `PrinterPreferenceResolver`
- application-layer settings lookup inside `PrintRepairDocumentUseCase`
- specific-printer submission support in `PrintingLocalPrinterService`
- effective printer label loading for Print Preview display

No new repository was created.

No schema change was made.

No Settings UI or Print Preview redesign was made.

## Database Schema

Schema version remains `5`.

No tables, columns, indexes, migrations, generated Drift files, printer tables, print history tables, or printer capability caches were added.

## Dependencies

None.

No package dependencies were added, removed, or changed.

## Tests Added

Updated `test/features/printing/infrastructure/printer_integration_test.dart`:

- system-default target still uses the default printer
- no available printer fails safely
- exact specific printer ID is used
- display name is not used as identifier
- unavailable specific printer fails without fallback
- customer-ticket saved ID resolves to ticket printer target
- device-label saved ID resolves to label printer target
- ticket and label printer preferences remain independent
- fresh settings are used for each print attempt
- copies remain preserved

Updated `test/features/printing/presentation/print_preview_test.dart`:

- print requests remain focused on repair ID, document mode, and copies
- configured ticket printer label renders
- configured label printer label renders
- `Default Printer` renders for null preference
- `Unavailable printer` renders for unavailable saved preference
- duplicate submission prevention remains working
- success and failure feedback remain unchanged

Updated test fakes in:

- `test/features/settings/settings_page_test.dart`
- `test/app_shell_test.dart`

## Validation Commands

- `dart format lib/features/printing test/features/printing test/app_shell_test.dart test/features/settings/settings_page_test.dart`
- `flutter analyze`
- `flutter test test/features/printing/infrastructure/printer_integration_test.dart`
- `flutter test test/features/printing/presentation/print_preview_test.dart`
- `dart format test/features/printing/presentation/print_preview_test.dart`
- `flutter test test/features/printing/presentation/print_preview_test.dart`
- `flutter analyze`
- `flutter test test/features/settings/settings_page_test.dart`
- `flutter test test/app_shell_test.dart`
- `flutter pub get`
- `dart format .`
- `flutter analyze`
- `flutter test`
- `flutter build windows`
- `git status --short`

## Validation Results

Dependency resolution: succeeded. `flutter pub get` completed successfully. Flutter reported that 17 packages have newer versions incompatible with dependency constraints.

Code generation: not run because no Drift schema or generated-code inputs changed.

Formatting: succeeded. `dart format .` completed successfully.

Static analysis: initially failed because the printer integration test import was too aggressively removed after `PrintPreviewRequest` was simplified. After restoring the correct import, `flutter analyze` reported no issues.

Focused printer integration tests: `flutter test test/features/printing/infrastructure/printer_integration_test.dart` passed.

Focused Print Preview tests: initially failed because one test changed ProviderScope override counts and reused a cached provider result after changing settings. After stabilizing the test harness and splitting default/unavailable display cases, `flutter test test/features/printing/presentation/print_preview_test.dart` passed.

Affected tests:

- `flutter test test/features/settings/settings_page_test.dart` passed.
- `flutter test test/app_shell_test.dart` passed.

All tests: `flutter test` passed all tests.

Windows build: attempted but not executed successfully because the current host is not Windows. Flutter returned: `"build windows" only supported on Windows hosts.`

Repository status check: `git status --short` failed because the working directory did not appear to be a Git repository.

## Issues or Limitations

- Windows build validation remains blocked by the current non-Windows environment.
- Physical printer validation was not performed.
- Actual printer-driver behavior still depends on the Windows print subsystem and the installed printer drivers.
- Print Preview displays `Unavailable printer` rather than the raw saved printer ID.
- Settings still does not provide printer management, printer installation, test-page printing, or printer troubleshooting UI.
- Backup & Restore UI remains deferred.
- The working directory did not appear to be a Git repository when `git status --short` was attempted.

## Next Safe Step

The next safe step is Backup & Restore UI implementation using the approved Stitch reference and existing backup/restore foundation.
