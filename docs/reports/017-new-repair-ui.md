# Prompt 017 — New Repair UI

## Summary

Implemented the approved New Repair screen and focused presentation logic. The app now has a two-column intake form, required-field and price validation, submission state, inline submission errors, Save Repair and Save & Print actions, safe repair creation through `CreateRepairUseCase`, and app-shell navigation from Repairs List to New Repair and back.

No Repair Details screen, Edit Repair screen, Change Status dialog, Print Preview, Settings UI, Backup & Restore UI, schema changes, fake form data, repair-code generation in UI, or low-level insertion bypass was added.

## Previous State Reviewed

Reports `docs/reports/001-project-foundation.md` through `docs/reports/016-repairs-list-ui.md` were read.

Relevant starting state:

- Shared shell, sidebar, page header, form controls, buttons, bottom action bar, status badge, and theme tokens existed.
- Repairs List had a New Repair callback boundary.
- `CreateRepairInput`, `CreateRepairUseCase`, generated repair codes, and safe creation workflow already existed.
- New repairs were created with generated visible repair codes, `RepairStatus.received`, and `CustomerPriceDecision.notRequested`.

The requested `design_reference/NOVA_REPAIR_UI_SPEC.md` file is now present and was read. The approved New Repair Stitch reference and design-system document were also reviewed.

## Design References Used

Source-of-truth priority:

1. `design_reference/NOVA_REPAIR_UI_SPEC.md`
2. Approved New Repair screenshot.
3. New Repair `code.html`.
4. Stitch design-system document.

Design files used:

- `design_reference/NOVA_REPAIR_UI_SPEC.md`
- `design_reference/stitch/stitch_nova_repair_dashboard_management/nova_repair_new_repair_intake/screen.png`
- `design_reference/stitch/stitch_nova_repair_dashboard_management/nova_repair_new_repair_intake/code.html`
- `design_reference/stitch/stitch_nova_repair_dashboard_management/nova_repair_design_system/DESIGN.md`

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
- Attached Prompt 017 request text
- `design_reference/NOVA_REPAIR_UI_SPEC.md`
- `design_reference/stitch/stitch_nova_repair_dashboard_management/nova_repair_new_repair_intake/code.html`
- `design_reference/stitch/stitch_nova_repair_dashboard_management/nova_repair_new_repair_intake/screen.png`
- `design_reference/stitch/stitch_nova_repair_dashboard_management/nova_repair_design_system/DESIGN.md`
- `lib/app/app_shell.dart`
- `lib/app/widgets/buttons/app_buttons.dart`
- `lib/app/widgets/form/app_text_field.dart`
- `lib/app/widgets/form/form_section.dart`
- `lib/app/widgets/bottom_action_bar.dart`
- `lib/features/repairs/repairs_page.dart`
- `lib/features/repairs/repair_providers.dart`
- `lib/features/repairs/application/create_repair_use_case.dart`
- `lib/features/repairs/domain/entities/create_repair_input.dart`
- `lib/features/repairs/domain/repositories/repair_repository.dart`
- `test/app_shell_test.dart`
- `test/features/repairs/repairs_list_test.dart`
- Existing file list under `lib/`, `test/`, `docs/`, and `design_reference/`

## Files Created

- `lib/features/repairs/new_repair_page.dart`
- `lib/features/repairs/presentation/new_repair_controller.dart`
- `lib/features/repairs/presentation/new_repair_state.dart`
- `test/features/repairs/new_repair_test.dart`
- `docs/reports/017-new-repair-ui.md`

## Files Modified

- `lib/app/app_shell.dart`
- `lib/app/widgets/buttons/app_buttons.dart`
- `lib/app/widgets/form/app_text_field.dart`

## New Repair Layout

The screen uses:

- Shared `PageHeader`.
- Title: `New Repair`.
- Subtitle: `Create a new repair job`.
- Desktop-first two-column form layout.
- Scrollable form content.
- Sticky shared `BottomActionBar`.

Left column sections:

- `Customer Information`
- `Device Information`
- `Reported Problem`
- `Notes`

Right column sections:

- `Initial Status`
- `Received Accessories`
- `Device Access`
- `Price`

The layout stacks at constrained widths to avoid overflow in smaller test or app windows.

## Form Fields

Customer Information:

- `Customer Name`, optional text field.
- `Phone Number`, optional text field with placeholder `0555 12 34 56`.

Device Information:

- `Device Type`, required text field.
- `Brand`, optional text field.
- `Model`, optional text field.

Reported Problem:

- Required multiline field.

Notes:

- `Internal Notes`, optional multiline field.
- `Customer Message`, optional multiline field with helper `This may later be shown to the customer in repair tracking`.

Initial Status:

- Read-only `StatusBadge(status: RepairStatus.received)`.
- No status dropdown.

Received Accessories:

- Optional multiline field with helper `List any accessories received with the device`.

Device Access:

- `PIN / Password / Access Note`, optional multiline field.
- Helper `Internal only — not shown on printed tickets`.
- No masking, encryption, printing exposure, or warning styling was added.

Price:

- `Proposed Repair Price`, optional integer-only DZD field.
- `DA` suffix.
- Helper `Optional — can be added later after diagnosis`.

## Text Editing Strategy

The page owns `TextEditingController`s and disposes them in the widget state.

`NewRepairController` owns validation, submission state, active submit action, and submission errors. This avoids two competing sources of truth for text values while still keeping business-facing submit logic outside the widget.

## Validation

Presentation validation covers:

- Device type is required after trimming.
- Reported problem is required after trimming.
- Price is optional.
- Price must be whole digits only when present.
- Decimal values, comma values, negative values, and non-numeric text are rejected by the controller.

The price field also uses digit-only input formatting in the UI, while controller validation remains the final presentation guard.

Backend `CreateRepairInput` validation remains the final domain protection.

## Submission Behavior

Both submit actions use the same `NewRepairController.submit` flow:

1. Validate presentation fields.
2. Build `CreateRepairInput`.
3. Call `CreateRepairUseCase`.
4. Return the created `Repair` on success.
5. Show a calm inline error on failure.

Successful creation preserves existing backend behavior:

- visible repair code is generated automatically
- status is `received`
- customer price decision is `notRequested`
- internal database ID is not displayed in the UI

## Save Repair Behavior

`Save Repair` creates the repair through `CreateRepairUseCase` and calls `onRepairCreated(Repair)`.

The app shell handles this by returning to the Repairs List and invalidating `repairsListControllerProvider`, so the list reloads and the new repair appears.

## Save & Print Behavior

`Save & Print` creates the repair through the same shared submit flow and calls `onRepairCreatedForPrint(Repair)`.

Because Print Preview is not implemented yet, the app shell currently returns to the Repairs List after creation and refreshes the list. No PDF, printer call, QR embedding, fake Print Preview, or silent print behavior was added.

## Cancel Behavior

`NewRepairPage` exposes `onCancel`.

The app shell opens New Repair as a sub-screen inside the Repairs destination. Cancel returns to the Repairs List without browser-style history and without adding a routing package.

## Submission State

`NewRepairState` tracks:

- field validation errors
- submission error
- `isSubmitting`
- active submit action
- created repair

While submitting:

- Save Repair is disabled.
- Save & Print is disabled.
- Cancel is disabled.
- The active submit button shows the shared loading state.

## Shared Widgets Updated

`PrimaryButton`, `SecondaryButton`, and `GhostButton` now support an optional `isLoading` flag.

`AppTextField` now supports optional `keyboardType` and `inputFormatters`.

Existing call sites keep default behavior.

## Architecture Changes

Added Repairs presentation files:

- `new_repair_controller.dart`
- `new_repair_state.dart`
- `new_repair_page.dart`

The controller depends on the existing `createRepairUseCaseProvider`.

The app shell was changed from `StatefulWidget` to `ConsumerStatefulWidget` so it can invalidate the Repairs List provider after creating a repair.

Intentionally not created:

- New repository methods.
- New data sources.
- New backend use cases.
- Repair Details controller.
- Edit Repair controller.
- Print Preview controller.
- Routing package.

## Database Schema

Schema version remains `4`.

No database tables, columns, indexes, or migrations were added. The existing repair creation workflow already supports the required fields.

## Dependencies

None.

No dependencies were added, removed, or changed.

## Tests Added

- `test/features/repairs/new_repair_test.dart`
  - Controller rejects blank device type.
  - Controller rejects blank reported problem.
  - Controller rejects invalid price text.
  - Controller creates repairs through the safe use case with generated repair code.
  - Created repair starts as `received`.
  - Created repair keeps customer price decision as `notRequested`, including when a price is provided.
  - Controller failure state is recoverable.
  - UI renders approved sections, fields, read-only Received status, and bottom actions.
  - UI uses no status dropdown.
  - UI shows validation and preserves entered values.
  - Save Repair calls the normal creation callback.
  - Save & Print calls the print callback boundary.
  - Submission failure shows inline error and preserves values.
  - App shell opens New Repair from Repairs and Cancel returns to Repairs List.
  - App shell saves a repair, returns to Repairs List, refreshes data, and shows the new repair.

## Validation Commands

- `dart format .`
- `flutter analyze`
- `flutter test test/features/repairs/new_repair_test.dart`
- `flutter pub get`
- `flutter test test/features/repairs/new_repair_test.dart test/features/repairs/repairs_list_test.dart test/app_shell_test.dart`
- `flutter test`
- `flutter build windows`
- `git status --short`

## Validation Results

Dependency resolution: succeeded. `flutter pub get` completed successfully. Flutter reported that 12 packages have newer versions incompatible with current constraints.

Code generation: not run because no Drift schema or generated-code inputs changed.

Formatting: succeeded. `dart format .` completed successfully.

Static analysis: initially failed while the new test helper used a non-public Riverpod override type and an old warranty fake-repository method name. After fixes, `flutter analyze` reported no issues.

Focused New Repair tests: initially failed because the app shell returned to a cached Repairs List after creation. The shell now invalidates `repairsListControllerProvider` after successful creation. After the fix, `flutter test test/features/repairs/new_repair_test.dart` passed.

Targeted related tests: `flutter test test/features/repairs/new_repair_test.dart test/features/repairs/repairs_list_test.dart test/app_shell_test.dart` passed.

All tests: succeeded. `flutter test` passed all tests.

Windows build: attempted but not executed successfully because the current host is not Windows. Flutter returned: `"build windows" only supported on Windows hosts.`

Repository status check: `git status --short` failed because the working directory did not appear to be a Git repository.

## Issues or Limitations

- Windows build validation remains blocked by the current non-Windows environment.
- The working directory did not appear to be a Git repository when `git status --short` was attempted.
- Print Preview is still deferred. Save & Print creates the repair and exposes a dedicated callback boundary, but the app shell currently returns to Repairs List.
- Repair Details UI is not implemented.
- Edit Repair UI is not implemented.
- Change Status dialog is not implemented.
- Settings UI and Backup & Restore UI are not implemented.
- No customer lookup, customer profiles, device dropdowns, brand autocomplete, QR embedding, PDF generation, printing, online tracking, notifications, reports, analytics, or sample data were added.

## Next Safe Step

The next safe development step is Repair Details UI implementation using the approved Stitch reference and existing repair query/status/price foundations.
