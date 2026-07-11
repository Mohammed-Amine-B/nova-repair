# Prompt 021 — Edit Repair UI

## Summary

Implemented the approved Edit Repair screen and focused save coordination logic. Repair Details now opens Edit Repair, the screen loads fresh repair data by ID, reuses the New Repair form structure, edits normal repair fields through `UpdateRepairUseCase`, coordinates price changes through the existing price workflows, and returns to refreshed Repair Details after a successful save.

No Print Preview, Create Warranty Return UI, customer price decision interaction, Settings UI, Backup UI, Change Status changes, backend workflow changes, schema changes, or dependencies were added.

## Previous State Reviewed

Reports `docs/reports/001-project-foundation.md` through `docs/reports/020-repair-update-workflow-foundation.md` were read.

Relevant starting state:

- Repair Details existed with an `onEditRepair(Repair repair)` callback boundary.
- New Repair UI existed with the approved shared repair intake form structure.
- `UpdateRepairUseCase` and `UpdateRepairInput` existed for normal repair detail updates.
- `ProposeRepairPriceUseCase` and `ClearRepairPriceUseCase` existed for price changes.
- Price editing was allowed by the backend only while status is `diagnosing` or `waitingForCustomerApproval`.
- Status changes, warranty returns, printing, QR, backup, and customer price decision workflows were separate.

The UI specification and approved Edit/New Repair Stitch references were reviewed.

## Design References Used

- `design_reference/NOVA_REPAIR_UI_SPEC.md`
- `design_reference/stitch/stitch_nova_repair_dashboard_management/nova_repair_edit_repair_refined/screen.png`
- `design_reference/stitch/stitch_nova_repair_dashboard_management/nova_repair_edit_repair_refined/code.html`
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
- `docs/reports/017-new-repair-ui.md`
- `docs/reports/018-repair-details-ui.md`
- `docs/reports/019-change-status-dialog.md`
- `docs/reports/020-repair-update-workflow-foundation.md`
- Attached Prompt 021 request text
- `design_reference/NOVA_REPAIR_UI_SPEC.md`
- Edit Repair and New Repair Stitch screenshot/code references
- `lib/app/app_shell.dart`
- `lib/features/repairs/new_repair_page.dart`
- `lib/features/repairs/repair_details_page.dart`
- `lib/features/repairs/presentation/new_repair_controller.dart`
- `lib/features/repairs/presentation/new_repair_state.dart`
- `lib/features/repairs/presentation/repair_details_controller.dart`
- `lib/features/repairs/repair_providers.dart`
- `lib/features/repairs/application/update_repair_use_case.dart`
- `lib/features/repairs/application/propose_repair_price_use_case.dart`
- `lib/features/repairs/application/clear_repair_price_use_case.dart`
- `lib/features/repairs/domain/entities/update_repair_input.dart`
- `lib/features/repairs/domain/entities/propose_repair_price_input.dart`
- `lib/features/repairs/domain/entities/clear_repair_price_input.dart`
- Existing New Repair, Repair Details, Repairs List, Dashboard, status, price, and update tests

## Files Created

- `lib/features/repairs/edit_repair_page.dart`
- `lib/features/repairs/presentation/edit_repair_controller.dart`
- `lib/features/repairs/presentation/edit_repair_state.dart`
- `lib/features/repairs/presentation/repair_form_content.dart`
- `test/features/repairs/edit_repair_test.dart`
- `docs/reports/021-edit-repair-ui.md`

## Files Modified

- `lib/app/app_shell.dart`
- `lib/features/repairs/new_repair_page.dart`

## Edit Repair Layout

The Edit Repair screen uses the shared `PageHeader`:

- Title: `Edit Repair`
- Subtitle: `Update repair information for <repair code>`

The main content uses the shared repair form structure:

- Left column: Customer Information, Device Information, Reported Problem, Notes.
- Right column: Current Status, Received Accessories, Device Access, Price.

The bottom action bar contains only:

- Cancel
- Save Changes

No Save & Print, Print, Delete, Archive, status selector, or customer decision selector was added.

## Shared Form Reuse

Extracted `RepairFormContent` and `RepairFormControllers` from the existing New Repair page structure.

New Repair now uses the shared form content with:

- `Initial Status`
- `Received`
- existing `new-repair-*` field keys
- existing Save Repair and Save & Print actions

Edit Repair uses the same form content with:

- `Current Status`
- the real current repair status
- `edit-repair-*` field keys
- Save Changes only

New Repair behavior remains unchanged and its focused tests passed after the refactor.

## Data Loading

Edit Repair receives the selected internal repair ID from the app shell and loads fresh data through:

- `editRepairLoadProvider(repairId)`
- `RepairRepository.getRepairById(repairId)`

The screen does not rely on the stale `Repair` object captured from the Details button tap, and it does not show the internal ID.

Form controllers are initialized from the loaded repair once a fresh repair is available. The page also guards against older loaded snapshots overwriting newer saved state.

## Editable Fields

Editable normal fields:

- customer name
- customer phone
- device type
- brand
- model
- reported problem
- internal notes
- customer message
- received accessories
- device access information

These save through `UpdateRepairUseCase`.

## Current Status

The current real repair status is displayed read-only with `StatusBadge`.

No dropdown, selector, or Change Status action was added to Edit Repair. Status changes remain owned by Repair Details and the existing Change Status dialog.

## Price Editing

The price field is labeled `Proposed Repair Price`, uses integer DZD text, and displays the `DA` suffix.

Allowed editable statuses:

- `diagnosing`
- `waitingForCustomerApproval`

Read-only statuses:

- `received`
- `waitingForPart`
- `repairing`
- `readyForPickup`
- `delivered`
- `cancelled`

When read-only, the current price is shown and the helper explains:

`Price can only be changed while diagnosing or waiting for customer approval.`

Backend price workflows remain authoritative.

## Validation

Presentation validation covers:

- blank device type rejected
- blank reported problem rejected
- blank price accepted as absent
- integer price accepted
- zero price accepted
- decimal price rejected
- negative price rejected
- non-numeric price rejected

No validation package was added.

## Edit Repair State

Added:

- `EditRepairState`
- `EditRepairController`
- `editRepairLoadProvider`
- `editRepairControllerProvider`

State tracks:

- validation errors
- submission error
- partial-failure warning
- latest repair after partial failure
- submission progress

Text field values remain owned by page-local `TextEditingController`s, matching the existing New Repair pattern.

## Save Coordination

`EditRepairController.submit` coordinates:

1. validate normal fields and price text before mutation
2. call `UpdateRepairUseCase`
3. compare original and edited price
4. call `ProposeRepairPriceUseCase` when a new or changed integer price is provided
5. call `ClearRepairPriceUseCase` when an existing price is cleared
6. do nothing when the price is unchanged or absent in both states
7. return the latest repair

The controller does not manually modify customer price decision. Decision reset or clearing behavior comes from the existing price workflow.

## Partial Failure Handling

Normal detail update and price update are separate workflows and are not wrapped in one cross-use-case transaction.

If normal details succeed but price update fails, the UI shows:

`Repair information was updated, but the price could not be changed. Review the current values and try again.`

The latest repair is reloaded and the page does not claim the entire save was rolled back.

## Cancel Behavior

Cancel returns from Edit Repair to Repair Details without saving.

No unsaved-changes confirmation dialog was added.

## Success Behavior

After successful save:

- Edit Repair returns to Repair Details.
- Repair Details reloads fresh data.
- Repairs List is invalidated.
- Dashboard is invalidated because recent repair rows can display changed customer/device text.

## Refresh Integration

The app shell invalidates:

- `editRepairLoadProvider(repairId)`
- `editRepairControllerProvider(repairId)`
- `repairDetailsControllerProvider(repairId)`
- `repairsListControllerProvider`
- `dashboardControllerProvider`

## Navigation Integration

Repairs sub-screen model now supports:

- Repairs List
- New Repair
- Repair Details
- Edit Repair

Flow implemented:

- Repair Details → Edit Repair
- Edit Repair → Cancel → Repair Details
- Edit Repair → Save Changes → refreshed Repair Details

The Repairs sidebar destination remains selected while Edit Repair is open.

## Shared Widgets Reused

Reused:

- `PageHeader`
- `FormSection`
- `AppTextField`
- `AppTextArea`
- `StatusBadge`
- `PrimaryButton`
- `GhostButton`
- `BottomActionBar`

## Architecture Changes

Added only presentation-level coordination:

- shared repair form content
- Edit Repair page
- Edit Repair controller/state

No new repository was created.

No backend workflow was changed.

No generic update map, direct data-source write, status workflow change, price workflow change, warranty workflow change, print logic, QR logic, or backup logic was added.

## Database Schema

Schema version remains `4`.

No tables, columns, indexes, migrations, or generated Drift files were changed.

## Dependencies

None.

No dependencies were added, removed, or changed.

## Tests Added

- `test/features/repairs/edit_repair_test.dart`
  - Loads fresh repair by ID.
  - Prefills all editable fields.
  - Displays current status read-only.
  - Shows not-found and load-error states.
  - Validates required fields and price text.
  - Updates normal fields through real persistence.
  - Preserves protected fields.
  - Adds, changes, and clears price through real price workflows.
  - Keeps price read-only in disallowed statuses while allowing normal edits.
  - Reports partial price workflow failure honestly after normal update succeeds.
  - Confirms New Repair still renders the shared form sections and actions.
  - Verifies Details → Edit → Cancel and Details → Edit → Save → refreshed Details/List navigation.

Affected suites were also run for New Repair, Repair Details, Repairs List, Dashboard, update workflow, price workflow, and Change Status.

## Validation Commands

- `dart format lib/features/repairs/presentation/repair_form_content.dart lib/features/repairs/presentation/edit_repair_state.dart lib/features/repairs/presentation/edit_repair_controller.dart lib/features/repairs/edit_repair_page.dart lib/features/repairs/new_repair_page.dart lib/app/app_shell.dart`
- `flutter analyze`
- `dart format test/features/repairs/edit_repair_test.dart`
- `flutter test test/features/repairs/edit_repair_test.dart`
- `dart format lib/features/repairs/edit_repair_page.dart test/features/repairs/edit_repair_test.dart`
- `flutter test test/features/repairs/new_repair_test.dart`
- `flutter test test/features/repairs/repair_details_test.dart`
- `flutter test test/features/repairs/repairs_list_test.dart`
- `flutter test test/features/dashboard/dashboard_test.dart`
- `flutter test test/features/repairs/data/repair_update_workflow_test.dart`
- `flutter test test/features/repairs/data/repair_price_workflow_test.dart`
- `flutter test test/features/repairs/change_status_dialog_test.dart`
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

Static analysis: initially found a const-list issue in the extracted shared form and a missing fake repository method in the new test. After fixes, `flutter analyze` reported no issues.

Focused Edit Repair tests: initially exposed a ProviderScope override-count issue in one test, a local DateTime expectation mismatch, and a real page-state issue where an older load snapshot could overwrite newly saved standalone page state. After fixes, `flutter test test/features/repairs/edit_repair_test.dart` passed.

Affected tests:

- `flutter test test/features/repairs/new_repair_test.dart` passed.
- `flutter test test/features/repairs/repair_details_test.dart` passed.
- `flutter test test/features/repairs/repairs_list_test.dart` passed.
- `flutter test test/features/dashboard/dashboard_test.dart` passed.
- `flutter test test/features/repairs/data/repair_update_workflow_test.dart` passed.
- `flutter test test/features/repairs/data/repair_price_workflow_test.dart` passed.
- `flutter test test/features/repairs/change_status_dialog_test.dart` passed.

All tests: `flutter test` passed all tests.

Windows build: attempted but not executed successfully because the current host is not Windows. Flutter returned: `"build windows" only supported on Windows hosts.`

Repository status check: `git status --short` failed because the working directory did not appear to be a Git repository.

## Issues or Limitations

- Windows build validation remains blocked by the current non-Windows environment.
- The working directory did not appear to be a Git repository when `git status --short` was attempted.
- Normal detail update and price update are separate workflows, so cross-workflow save is not fully atomic.
- Print Preview remains deferred.
- Create Warranty Return UI remains deferred.
- Customer price decision interaction remains deferred.
- No unsaved-changes confirmation was added.

## Next Safe Step

The next safe step is Print Preview implementation using the approved shared screen, existing print data foundation, and QR generation foundation.
