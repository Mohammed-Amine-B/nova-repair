# Prompt 022 — Print Preview UI

## Summary

Implemented the approved Print Preview UI for customer tickets and device labels. The app now opens Print Preview from Repair Details and from New Repair's Save & Print flow, loads fresh print data by repair ID, renders two preview modes, generates a real QR code from the visible repair code only, and exposes a focused print request boundary without invoking OS printing.

No OS printer discovery, Windows print APIs, PDF generation, Save as PDF, print history, tracking URL generation, online tracking, Settings UI, Backup UI, schema changes, dependency changes, or fake sample data were added.

## Previous State Reviewed

Reports `docs/reports/001-project-foundation.md` through `docs/reports/021-edit-repair-ui.md` were read.

Relevant starting state:

- Repair Details existed with an `onPrintRepair(Repair repair)` callback boundary.
- New Repair existed with a Save & Print callback boundary.
- The printing feature already had `BuildRepairPrintDataUseCase`, `RepairPrintData`, `CustomerTicketData`, and `DeviceLabelData`.
- QR generation already existed as an in-memory SVG generator.
- There was no Print Preview UI, printer selection, OS print integration, PDF output, or QR embedding in a screen.

The UI specification and approved Print Preview Stitch references were reviewed.

## Design References Used

- `design_reference/NOVA_REPAIR_UI_SPEC.md`
- `design_reference/stitch/stitch_nova_repair_dashboard_management/nova_repair_print_preview_refined/screen.png`
- `design_reference/stitch/stitch_nova_repair_dashboard_management/nova_repair_print_preview_refined/code.html`
- `design_reference/stitch/stitch_nova_repair_dashboard_management/nova_repair_print_preview_device_label/screen.png` 
- `design_reference/stitch/stitch_nova_repair_dashboard_management/nova_repair_print_preview_device_label/code.html`
- `design_reference/stitch/stitch_nova_repair_dashboard_management/nova_repair_design_system/DESIGN.md`

Screenshots were treated as the strongest visual references. The HTML files were used only as supporting layout references and were not copied into Flutter architecture.

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
- Attached Prompt 022 request text
- `design_reference/NOVA_REPAIR_UI_SPEC.md`
- Approved Print Preview ticket and device-label Stitch references
- `lib/app/app_shell.dart`
- `lib/features/repairs/repair_details_page.dart`
- `lib/features/repairs/new_repair_page.dart`
- `lib/features/printing/application/build_repair_print_data_use_case.dart`
- `lib/features/printing/domain/entities/customer_ticket_data.dart`
- `lib/features/printing/domain/entities/device_label_data.dart`
- `lib/features/printing/domain/entities/repair_print_data.dart`
- `lib/features/printing/infrastructure/qr/qr_code_generator.dart`
- `lib/features/printing/infrastructure/qr/qr_code_svg.dart`
- `test/features/printing/application/build_repair_print_data_use_case_test.dart`
- Existing Repair Details, New Repair, Dashboard, Repairs List, QR, and app shell tests

## Files Created

- `lib/features/printing/presentation/print_document_mode.dart`
- `lib/features/printing/presentation/print_preview_request.dart`
- `lib/features/printing/presentation/print_preview_state.dart`
- `lib/features/printing/presentation/print_preview_controller.dart`
- `lib/features/printing/presentation/print_preview_formatters.dart`
- `lib/features/printing/presentation/print_preview_page.dart`
- `lib/features/printing/presentation/widgets/print_preview_shell.dart`
- `lib/features/printing/presentation/widgets/customer_ticket_preview.dart`
- `lib/features/printing/presentation/widgets/device_label_preview.dart`
- `lib/features/printing/presentation/widgets/qr_svg_view.dart`
- `test/features/printing/presentation/print_preview_test.dart`
- `docs/reports/022-print-preview-ui.md`

## Files Modified

- `lib/app/app_shell.dart`
- `lib/features/printing/application/build_repair_print_data_use_case.dart`
- `lib/features/printing/domain/entities/customer_ticket_data.dart`
- `test/features/printing/application/build_repair_print_data_use_case_test.dart`

## Print Preview Layout

The Print Preview screen uses a desktop-first layout:

- Top header with Back action, title, and repair-specific subtitle.
- Left controls panel for document mode, copies, printer, paper size, Back, and Print.
- Right preview workspace with a segmented document-mode tab and centered document preview.

The preview workspace scrolls when needed. No routing package or new app shell was introduced.

## Document Modes

Added `PrintDocumentMode` with:

- `customerTicket`
- `deviceLabel`

Both modes are rendered by the same Print Preview screen and share the same controls. Switching modes updates the preview without reloading fake data.

## Customer Ticket Preview

The customer ticket preview renders real `CustomerTicketData`:

- shop name
- shop phone
- shop address
- visible repair code
- received date
- customer name
- customer phone
- device display name
- device type
- reported problem
- received accessories
- QR code
- repair code under QR
- ticket footer
- warranty terms

The ticket intentionally excludes:

- proposed price
- customer price decision
- device access information
- internal notes
- customer-visible message
- tracking URL
- tracking token

The ticket label is `Received Date`, not `Return Date`.

## Device Label Preview

The device label preview renders compact real data:

- shop name
- visible repair code
- QR code
- device display name
- customer name
- customer phone

The label intentionally excludes:

- reported problem body
- received accessories
- proposed price
- customer price decision
- internal notes
- customer-visible message
- device access information
- warranty terms
- tracking URL
- tracking token

## QR Behavior

Print Preview uses the existing `QrCodeGenerator`.

Payload:

- the visible repair code only, such as `REP-0001`

The QR payload is not:

- a tracking URL
- a tracking token
- an online endpoint
- a customer account reference

`QrSvgView` renders the existing generated SVG QR matrix in Flutter with `CustomPaint`. No widget QR package, raster image package, file persistence, network access, or PDF layer was added.

## Controls

Implemented controls:

- document type selector
- copies selector
- printer display
- paper size display
- Back
- Print

Copies:

- minimum `1`
- maximum `99`

Printer:

- fixed display value `Default Printer`

Paper size:

- `Receipt / A4` for Customer Ticket
- `Label` for Device Label

Printer and paper controls are display-only foundations because real OS printer integration is intentionally out of scope.

## Print Request Boundary

Added `PrintPreviewRequest` with:

- `repairId`
- `documentMode`
- `copies`
- `printerTarget`

`printerTarget` currently supports only:

- `systemDefault`

Pressing Print builds and emits the request boundary, then shows the informational message:

`Printer integration is not available yet.`

No fake success state, OS print call, PDF generation, file export, or print history write was added.

## Data Loading

`printPreviewDataProvider(repairId)` loads fresh print data through `BuildRepairPrintDataUseCase` and generates a QR code from `customerTicket.repairCode`.

The screen does not reuse stale Repair Details objects and does not search UI lists for the selected repair.

## State Management

Added:

- `PrintPreviewState`
- `PrintPreviewController`
- `printPreviewControllerProvider`
- `printPreviewDataProvider`
- `PrintPreviewData`

State tracks:

- selected document mode
- copy count
- informational print-boundary message

No printer controller, PDF controller, print queue, polling, or background state was added.

## Navigation Integration

Repair Details flow:

- Repair Details → Print → Print Preview
- Print Preview → Back → Repair Details

New Repair flow:

- New Repair → Save & Print → Print Preview for the created repair
- Print Preview → Back → Repair Details for the created repair

The app shell keeps the Repairs sidebar destination selected while Print Preview is open.

## Loading State

The loading state keeps the Print Preview page context and shows a calm centered `CircularProgressIndicator` inside a shared `SectionCard`.

No shimmer dependency or decorative loading animation was added.

## Not Found State

If the repair cannot be found, Print Preview shows:

- `Repair not found`
- a short explanatory message
- Back action

No raw exception details are shown.

## Error State

General print-data loading failures show:

- `Print data could not be loaded`
- Retry
- Back

Raw exception text, stack traces, SQL details, and internal error types are not exposed.

## Formatting

Added `PrintPreviewDateFormatter`.

Dates are converted to local display using a concise format such as:

`05 Jul 2026`

No localization package was added.

## Shared Widgets Reused

Reused:

- app theme colors and spacing
- shared buttons
- `SectionCard`
- existing repair/device display and print data foundations

No duplicate sidebar, app shell, routing system, design system, or UI kit was added.

## Architecture Changes

Added a small printing presentation layer under:

- `lib/features/printing/presentation/`

This layer depends on existing printing application services and QR infrastructure.

No new repository was created.

No fake use case was added.

No backend workflow was changed.

No OS printing, PDF, printer discovery, or online tracking abstraction was introduced.

## Database Schema

Schema version remains `4`.

No tables, columns, indexes, migrations, generated Drift files, print history tables, printer settings tables, QR tables, tracking token tables, or ticket snapshot tables were added.

## Dependencies

None.

No dependencies were added, removed, or changed.

## Tests Added

- `test/features/printing/presentation/print_preview_test.dart`
  - Print data loads by repair ID.
  - QR payload uses visible repair code only.
  - Controller mode and copy limits work.
  - Customer ticket renders real data.
  - Customer ticket excludes price, decision, device access, internal notes, and customer message.
  - Device label renders compact real data.
  - Device label excludes unapproved/sensitive fields.
  - Copy controls stay within bounds.
  - Print emits a `PrintPreviewRequest` boundary.
  - Missing repair state renders.
  - Error state renders without raw details.
  - Repair Details Print opens Print Preview and Back returns to Details.
  - New Repair Save & Print opens Print Preview and Back returns to Details.

Updated:

- `test/features/printing/application/build_repair_print_data_use_case_test.dart`
  - Verifies ticket data now carries device type for the approved ticket preview label.

## Validation Commands

- `dart format lib/app/app_shell.dart lib/features/printing test/features/printing/presentation/print_preview_test.dart test/features/printing/application/build_repair_print_data_use_case_test.dart`
- `flutter analyze`
- `flutter test test/features/printing/presentation/print_preview_test.dart`
- `dart format lib/features/printing/presentation/widgets/customer_ticket_preview.dart test/features/printing/presentation/print_preview_test.dart`
- `flutter analyze`
- `flutter test test/features/printing/presentation/print_preview_test.dart`
- `dart format lib/features/printing/presentation/widgets/customer_ticket_preview.dart test/features/printing/presentation/print_preview_test.dart`
- `flutter analyze`
- `flutter test test/features/printing/presentation/print_preview_test.dart`
- `flutter test test/features/printing/application/build_repair_print_data_use_case_test.dart`
- `flutter test test/features/printing/infrastructure/qr/qr_code_generator_test.dart`
- `flutter test test/features/repairs/repair_details_test.dart`
- `flutter test test/features/repairs/new_repair_test.dart`
- `flutter test test/app_shell_test.dart`
- `flutter test test/features/repairs/repairs_list_test.dart`
- `flutter test test/features/dashboard/dashboard_test.dart`
- `flutter test test/features/repairs/edit_repair_test.dart`
- `flutter pub get`
- `dart format .`
- `flutter analyze`
- `flutter test`
- `flutter build windows`
- `git status --short`

## Validation Results

Dependency resolution: succeeded. `flutter pub get` completed successfully. Flutter reported that 12 packages have newer versions incompatible with current constraints.

Code generation: not run because no Drift schema or generated-code inputs changed.

Formatting: succeeded. `dart format .` completed successfully.

Static analysis: initially reported an unused test import. After removing it, `flutter analyze` reported no issues.

Focused Print Preview tests: initially exposed a real receipt layout issue caused by a `Spacer` inside a scrollable preview, and a test harness issue where Riverpod override counts changed between pumps. After fixing the layout and stabilizing the test harness, `flutter test test/features/printing/presentation/print_preview_test.dart` passed.

Affected tests passed:

- `flutter test test/features/printing/application/build_repair_print_data_use_case_test.dart`
- `flutter test test/features/printing/infrastructure/qr/qr_code_generator_test.dart`
- `flutter test test/features/repairs/repair_details_test.dart`
- `flutter test test/features/repairs/new_repair_test.dart`
- `flutter test test/app_shell_test.dart`
- `flutter test test/features/repairs/repairs_list_test.dart`
- `flutter test test/features/dashboard/dashboard_test.dart`
- `flutter test test/features/repairs/edit_repair_test.dart`

All tests: `flutter test` passed all tests.

Windows build: attempted but not executed successfully because the current host is not Windows. Flutter returned: `"build windows" only supported on Windows hosts.`

Repository status check: `git status --short` failed because the working directory did not appear to be a Git repository.

## Issues or Limitations

- Windows build validation remains blocked by the current non-Windows environment.
- The working directory did not appear to be a Git repository when `git status --short` was attempted.
- Print is a request boundary only; OS printer integration is not implemented.
- Printer discovery, printer selection, printer settings, and real paper-size configuration are deferred.
- PDF generation and Save as PDF are deferred.
- QR payload is deliberately only the visible repair code, not an online tracking URL.
- Online tracking, tracking tokens, and customer tracking pages remain out of scope.
- Print Preview does not persist print history or generated ticket snapshots.
- A real layout issue in the receipt preview was found during testing and resolved.

## Next Safe Step

The next safe step is Create Warranty Return UI implementation using the existing warranty workflow and approved Stitch reference.
