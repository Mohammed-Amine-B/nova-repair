# Prompt 026 — Settings UI

## Summary

Implemented the approved Settings UI using real persisted shop settings and real local printer discovery boundaries. The Settings screen now loads and saves shop information, displays selectable default printers for customer tickets and device labels, preserves hidden settings fields during save, exposes a Backup & Restore navigation boundary, and keeps the sidebar shop identity connected to current settings.

No Backup & Restore UI, printer management UI, printer discovery redesign, print execution preference wiring, database schema change, dependency change, or sample data was added.

## Previous State Reviewed

Reports `docs/reports/001-project-foundation.md` through `docs/reports/025-shop-settings-model-extension-foundation.md` were read.

Relevant starting state:

- Drift schema version was `5`.
- `ShopSettings` already persisted shop subtitle and default printer preference IDs.
- Settings still showed only a placeholder page.
- Real local printer discovery existed through `LocalPrinterService`.
- Print Preview and Windows print integration existed, but print requests still targeted the system default printer only.
- Backup and restore foundations existed without a Settings navigation surface.

The UI specification and approved Settings Stitch references were reviewed before implementation.

## Design References Used

- `design_reference/NOVA_REPAIR_UI_SPEC.md`
- `design_reference/stitch/stitch_nova_repair_dashboard_management/nova_repair_shop_settings/screen.png`
- `design_reference/stitch/stitch_nova_repair_dashboard_management/nova_repair_shop_settings/code.html`
- `design_reference/stitch/stitch_nova_repair_dashboard_management/nova_repair_design_system/DESIGN.md`

The screenshot was treated as the strongest visual reference, with HTML used only as supporting layout reference.

## Files Inspected

- Prompt 026 attachment text
- `docs/reports/001-project-foundation.md` through `docs/reports/025-shop-settings-model-extension-foundation.md`
- `design_reference/NOVA_REPAIR_UI_SPEC.md`
- Settings Stitch screenshot and code reference
- `pubspec.yaml`
- `lib/features/settings/settings_page.dart`
- `lib/features/settings/domain/entities/shop_settings.dart`
- `lib/features/settings/domain/repositories/shop_settings_repository.dart`
- `lib/features/settings/data/repositories/drift_shop_settings_repository.dart`
- `lib/features/settings/settings_providers.dart`
- `lib/features/printing/domain/entities/local_printer.dart`
- `lib/features/printing/application/local_printer_service.dart`
- `lib/features/printing/printing_providers.dart`
- `lib/features/printing/presentation/print_preview_request.dart`
- `lib/features/printing/presentation/print_preview_controller.dart`
- `lib/features/printing/infrastructure/printers/printing_local_printer_service.dart`
- `lib/app/app_shell.dart`
- `lib/app/widgets/nova_sidebar.dart`
- Existing Settings, app shell, print preview, print data, backup, and shared UI tests

## Files Created

- `lib/features/settings/presentation/settings_state.dart`
- `lib/features/settings/presentation/settings_controller.dart`
- `test/features/settings/settings_page_test.dart`
- `docs/reports/026-settings-ui.md`

## Files Modified

- `lib/features/settings/settings_page.dart`
- `lib/app/app_shell.dart`
- `lib/app/widgets/nova_sidebar.dart`
- `test/app/widgets/shared_ui_foundation_test.dart`
- `test/app_shell_test.dart`

## Settings Layout

The Settings screen uses the shared `PageHeader` with:

- Title: `Settings`
- Subtitle: `Manage shop information and application preferences`

Content is centered with a maximum width of `960` and uses compact desktop spacing.

Sections:

- `Shop Information`
- `Printing Defaults`
- `Data`
- one `Save Changes` primary action at the bottom

No tabs, account settings, license settings, QR settings, online settings, printer-management screen, or Backup UI was added.

## Data Loading

Settings load fresh data through:

- `settingsLoadProvider`
- `ShopSettingsRepository.getSettings()`

Printer discovery loads through:

- `settingsPrintersProvider`
- `LocalPrinterService.listPrinters()`

The UI does not use hard-coded printer names or fake settings data.

## Shop Information

Editable fields:

- Shop Name, required
- Shop Subtitle, optional
- Phone Number, optional
- Address, optional

Validation:

- blank shop name is rejected
- optional blank fields are saved as `null`
- text normalization remains owned by the existing `ShopSettings` domain entity

No email, website, tax ID, currency, locale, business hours, or logo picker was added.

## Printing Defaults

Editable printer preferences:

- Customer Ticket Printer
- Device Label Printer

Each selector shows:

- `Default Printer`
- discovered `LocalPrinter.displayName` values
- an unavailable saved printer option when the persisted ID is not currently discovered

The Settings UI consumes only the app-level `LocalPrinter` abstraction and does not expose printing package types.

## System Default Semantics

`Default Printer` is a UI option only.

Persisted value:

- `null` means system default printer

No sentinel value such as `Default Printer`, `SYSTEM_DEFAULT`, or an empty string is persisted.

## Saved Printer Preferences

When a saved printer ID matches a discovered printer, that printer is selected.

When a saved printer ID is unavailable, the dropdown keeps a visible option:

- `Unavailable printer (<id>)`

The ID is preserved during save unless the user chooses another option. The Settings UI does not delete unavailable printer preferences automatically.

## Printer Discovery Error

Printer discovery failure does not block shop information editing.

The UI shows:

- `Printers could not be loaded. Saved printer preferences are preserved.`
- `Retry`

Save can still proceed and preserves the currently loaded printer IDs.

## Data Section

The Data section contains a single Backup & Restore card:

- Title: `Backup & Restore`
- Description: `Create backups and restore Nova Repair data`
- trailing chevron

The card calls `onOpenBackupRestore`.

No Backup UI, restore dialog, file picker, backup execution, or restore execution was implemented.

## Settings State

Added:

- `SettingsState`
- `SettingsController`
- `settingsLoadProvider`
- `settingsPrintersProvider`
- `settingsControllerProvider`

The controller tracks:

- shop name validation error
- save progress
- save success message
- save error message

Text field values remain owned by page-local `TextEditingController`s.

## Save Workflow

Save flow:

1. Validate shop name.
2. Build an updated `ShopSettings` from the current loaded settings through `copyWith`.
3. Apply visible field changes.
4. Persist through `ShopSettingsRepository.saveSettings`.
5. Show success or failure feedback.
6. Prevent duplicate save submissions while saving.

The UI does not write directly to Drift.

## Save Success and Failure

On success, the screen shows:

- `Settings saved successfully.`

On failure, the screen shows:

- `Settings could not be saved. Please try again.`

Raw exceptions, stack traces, SQL details, and plugin details are not shown.

## Hidden Settings Preservation

The save workflow preserves settings not exposed by this screen:

- `logoPath`
- `repairCodePrefix`
- `repairCodeNumberWidth`
- `ticketFooter`
- `warrantyTerms`
- `createdAt`

`updatedAt` remains owned by the existing settings repository save behavior.

## Printer Execution Integration Decision

Saved printer preferences are not wired into print execution in this prompt.

Reason:

- `PrintPreviewRequest` currently supports only `PrintPreviewPrinterTarget.systemDefault`.
- Cleanly using persisted printer IDs requires a focused print-request and printer-service change.

The Settings UI persists and displays preferences now. Actual print execution continues using the existing system-default behavior.

## Shop Subtitle Print Freshness

The screen saves `shopSubtitle` through the real settings repository.

Existing print data loading remains on-demand through `BuildRepairPrintDataUseCase`, so future print data uses the saved subtitle without manual UI-to-print state pushing. Tests cover this behavior.

## Navigation Integration

The existing Settings sidebar destination now opens the real `SettingsPage`.

The app shell provides the Backup & Restore callback boundary and intentionally leaves it as a no-op until the approved Backup UI prompt.

The sidebar shop identity now reads real settings through `settingsLoadProvider`, using `ShopSettings.defaultShopName` only as a loading fallback.

## Shared Widgets Reused

Reused:

- `PageHeader`
- `FormSection`
- `AppTextField`
- `SectionCard`
- `PrimaryButton`
- `SecondaryButton`
- shared theme colors, spacing, and radius tokens

No duplicate sidebar, app shell, form field system, or UI kit was created.

## Architecture Changes

Added a focused Settings presentation layer only.

No new settings repository was created.

No printer settings repository was created.

No backend workflow, print workflow, backup workflow, or schema behavior was changed.

## Database Schema

Schema version remains `5`.

No tables, columns, indexes, migrations, generated Drift files, printer cache tables, or settings history tables were added.

## Dependencies

None.

No package dependencies were added, removed, or changed.

## Tests Added

- `test/features/settings/settings_page_test.dart`
  - loads persisted settings and discovered printers
  - saves visible fields and preserves hidden settings
  - rejects blank shop name
  - saves blank optional fields as `null`
  - maps `Default Printer` to persisted `null`
  - preserves unavailable saved printer IDs
  - handles printer discovery failure without blocking shop edits
  - retries printer discovery
  - handles save failure without losing entered values
  - invokes Backup & Restore callback boundary
  - confirms saved subtitle appears in fresh print data
  - confirms app shell Settings destination opens the real Settings page
  - confirms duplicate save submissions are prevented

Updated:

- `test/app_shell_test.dart`
  - overrides printer discovery for shell smoke tests
  - expects the real Settings page

- `test/app/widgets/shared_ui_foundation_test.dart`
  - supplies real sidebar shop identity inputs after removing hard-coded sidebar shop text

## Validation Commands

- `dart format lib/features/settings lib/app/app_shell.dart`
- `flutter analyze`
- `dart format test/features/settings/settings_page_test.dart`
- `flutter test test/features/settings/settings_page_test.dart`
- `dart format lib/app/app_shell.dart lib/app/widgets/nova_sidebar.dart test/app/widgets/shared_ui_foundation_test.dart test/features/settings/settings_page_test.dart`
- `flutter analyze`
- `flutter test test/features/settings/settings_page_test.dart`
- `flutter test test/app/widgets/shared_ui_foundation_test.dart`
- `flutter test test/app_shell_test.dart`
- `flutter analyze`
- `flutter test test/features/printing/presentation/print_preview_test.dart`
- `flutter test test/features/settings/domain/shop_settings_domain_test.dart test/features/settings/data/shop_settings_persistence_test.dart`
- `flutter test test/features/printing/application/build_repair_print_data_use_case_test.dart`
- `flutter test test/features/backup/local_backup_service_test.dart`
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

Static analysis: initially found use of an unavailable `AsyncValue.valueOrNull` getter and a deprecated `DropdownButtonFormField.value` argument. After fixes, `flutter analyze` reported no issues.

Focused Settings tests: initially failed because some Settings controls were below the default widget-test viewport. After switching the tests to a desktop-sized surface and using scroll-aware helpers, `flutter test test/features/settings/settings_page_test.dart` passed.

App shell tests: initially timed out because the real printer service was reached during shell smoke tests. After overriding `localPrinterServiceProvider` in the shell tests, `flutter test test/app_shell_test.dart` passed.

Affected tests passed:

- `flutter test test/app/widgets/shared_ui_foundation_test.dart`
- `flutter test test/features/printing/presentation/print_preview_test.dart`
- `flutter test test/features/settings/domain/shop_settings_domain_test.dart test/features/settings/data/shop_settings_persistence_test.dart`
- `flutter test test/features/printing/application/build_repair_print_data_use_case_test.dart`
- `flutter test test/features/backup/local_backup_service_test.dart`

All tests: `flutter test` passed all tests.

Windows build: attempted but not executed successfully because the current host is not Windows. Flutter returned: `"build windows" only supported on Windows hosts.`

Repository status check: `git status --short` failed because the working directory did not appear to be a Git repository.

## Issues or Limitations

- Windows build validation remains blocked by the current non-Windows environment.
- Physical printer discovery was not validated against real printer hardware in automated tests.
- Saved unavailable printer IDs display by ID because no friendly historical printer name is persisted.
- Saved printer preferences are not yet used by print execution; current Print Preview still emits system-default print requests.
- Backup & Restore UI is deferred.
- Printer management, printer installation, printer capability editing, and printer troubleshooting UI are deferred.
- Settings does not expose logo, repair code numbering, ticket footer, or warranty terms editing yet.
- The working directory did not appear to be a Git repository when `git status --short` was attempted.

## Next Safe Step

The next safe product step is Backup & Restore UI implementation using the approved Stitch reference and existing backup foundation.

Before relying on saved printer defaults for production print jobs, a small focused printer-preference execution wiring step is still required.
