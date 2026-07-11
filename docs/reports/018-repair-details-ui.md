# Prompt 018 — Repair Details UI

## Summary

Implemented the approved Repair Details screen and focused presentation/data-loading logic. The app now supports opening a repair from the Repairs List or Dashboard recent repairs, loading fresh detail data by internal repair ID, displaying real read-only repair information, showing honestly derived timeline entries, and exposing callback boundaries for deferred Edit, Change Status, Print, and Create Warranty Return actions.

No Edit Repair UI, Change Status dialog, Print Preview, Create Warranty Return workflow UI, customer decision dialog, Settings UI, Backup UI, backend workflow changes, schema changes, or fake sample data were added.

## Previous State Reviewed

Reports `docs/reports/001-project-foundation.md` through `docs/reports/017-new-repair-ui.md` were read.

Relevant starting state:

- Flutter desktop foundation, Riverpod root, app shell, and shared UI foundation existed.
- Dashboard, Repairs List, and New Repair UI existed.
- Repairs List and Dashboard already exposed repair-row selection callback boundaries.
- Repair creation, generated repair codes, status workflow, price workflow, warranty return workflow, search/filter logic, print-data foundation, QR generation, and backup/restore foundation existed.
- `RepairRepository.getRepairById` already existed for fresh detail loading.
- Repair Details UI did not exist yet.

The UI specification `design_reference/NOVA_REPAIR_UI_SPEC.md` was read. The final Repair Details Stitch screenshot and supporting code reference were reviewed.

## Design References Used

Source-of-truth priority used:

1. `design_reference/NOVA_REPAIR_UI_SPEC.md`
2. `design_reference/stitch/stitch_nova_repair_dashboard_management/nova_repair_repair_details_final_refinement/screen.png`
3. `design_reference/stitch/stitch_nova_repair_dashboard_management/nova_repair_repair_details_final_refinement/code.html`
4. `design_reference/stitch/stitch_nova_repair_dashboard_management/nova_repair_design_system/DESIGN.md`

The older Repair Details reference folder was identified but not used as the final source.

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
- Attached Prompt 018 request text
- `design_reference/NOVA_REPAIR_UI_SPEC.md`
- `design_reference/stitch/stitch_nova_repair_dashboard_management/nova_repair_repair_details_final_refinement/screen.png`
- `design_reference/stitch/stitch_nova_repair_dashboard_management/nova_repair_repair_details_final_refinement/code.html`
- `design_reference/stitch/stitch_nova_repair_dashboard_management/nova_repair_design_system/DESIGN.md`
- `lib/app/app_shell.dart`
- `lib/app/widgets/buttons/app_buttons.dart`
- `lib/features/dashboard/dashboard_page.dart`
- `lib/features/repairs/repairs_page.dart`
- `lib/features/repairs/domain/entities/repair.dart`
- `lib/features/repairs/domain/repositories/repair_repository.dart`
- `lib/features/repairs/domain/customer_price_decision.dart`
- `lib/features/repairs/domain/services/device_display_name_formatter.dart`
- `lib/features/repairs/repair_providers.dart`
- `test/app_shell_test.dart`
- `test/features/dashboard/dashboard_test.dart`
- `test/features/repairs/repairs_list_test.dart`
- Existing file list under `lib/features/repairs/`, `test/features/repairs/`, `docs/`, and `design_reference/`

## Files Created

- `lib/features/repairs/repair_details_page.dart`
- `lib/features/repairs/presentation/repair_details_controller.dart`
- `lib/features/repairs/presentation/repair_details_formatters.dart`
- `lib/features/repairs/presentation/repair_details_state.dart`
- `test/features/repairs/repair_details_test.dart`
- `docs/reports/018-repair-details-ui.md`

## Files Modified

- `lib/app/app_shell.dart`
- `lib/app/widgets/buttons/app_buttons.dart`

## Repair Details Layout

The screen uses the shared `PageHeader` with:

- Title: `Repair Details`
- Subtitle: `View and manage repair information`

Below the page header, the page shows a repair context header and a desktop-first two-column layout:

- Left column: Device Information, Reported Problem, Notes, Repair Timeline.
- Right column: Summary, Customer, Price & Approval, Received Accessories, Device Access, Warranty.

The layout uses compact spacing, shared cards, and page scrolling when content exceeds the available height. It stacks only at constrained widths to prevent overflow.

## Data Loading

The app shell stores a selected repair ID when a row is selected.

`RepairDetailsPage` receives `repairId` and loads fresh data through:

- `RepairRepository.getRepairById(repairId)`

The UI does not search an existing list in memory and does not expose the internal database ID visually.

## Repair Details State

Added:

- `repairDetailsControllerProvider`
- `RepairDetailsState`
- `RepairTimelineEntry`
- `RepairTimelineEntryType`

The controller loads:

- current repair
- original repair when `parentRepairId` exists
- derived timeline entries
- simple warranty action availability

The provider is `autoDispose.family`, so reopening a repair loads fresh repository data.

## Repair Context Header

The context header shows:

- `Back to Repairs`
- visible repair code
- device display name using the shared repair `DeviceDisplayNameFormatter`
- current shared `StatusBadge`

Actions:

- `Edit Repair`
- `Change Status`
- `Print`

These are callback boundaries only.

## Device Information

The Device Information section shows read-only values:

- Device Type
- Brand
- Model

Missing optional values use the shared `EmptyValueText` display.

## Reported Problem

The Reported Problem section shows the stored reported problem as plain read-only text. No quotation marks, truncation, editing controls, or fake values were added.

## Notes

The Notes section shows:

- Internal Notes, marked as internal-only
- Customer Message, described as potentially customer-visible later

Missing values use `EmptyValueText`. Device access information is not mixed into Notes.

## Repair Timeline

The timeline is derived only from persisted repair timestamps:

- `Repair received` from `receivedAt`
- `Ready for pickup` from `readyAt`, only when present
- `Delivered` from `deliveredAt`, only when present

Timeline entries are sorted newest-first to match the final details reference direction.

Intentionally not invented:

- Diagnosing history
- Repairing history
- Customer message updates
- Status-change events without persisted event records
- A new event-history table

## Summary

The Summary section shows:

- Code, using visible repair code only
- Status, using shared `StatusBadge`
- Received, formatted as local date and time
- Last Updated, formatted as local date and time

The internal database ID is not shown.

## Customer

The Customer section shows read-only:

- Customer Name
- Phone Number

No avatar, initials, account profile, customer history, or customer actions were added.

## Price & Approval

The Price & Approval section shows:

- Proposed Repair Price
- Customer Decision

Price display:

- Absent price shows `EmptyValueText`
- Present price is formatted as integer DZD, such as `6 500 DA`
- No floating-point or currency package was added

Customer decision display uses the new `PriceDecisionBadge`:

- `Not Requested`
- `Pending`
- `Approved`
- `Rejected`

`StatusBadge` is not reused for price decisions because repair status and price decision are separate concepts.

Lightweight customer decision interaction was deferred because the final Repair Details reference did not include an approved obvious decision action.

## Received Accessories

Received Accessories is a separate read-only section. Missing values use `EmptyValueText`.

## Device Access

Device Access shows the stored access value internally with the helper text:

`Internal only — not shown on printed tickets`

Missing values use `EmptyValueText`. No masking, encryption, copy-to-clipboard, ticket exposure, QR exposure, customer tracking exposure, or search exposure was added.

## Warranty

Normal repairs without a parent show:

- `No previous repair linked`
- `Create Warranty Return` secondary action

The action is enabled only when the repair is a delivered original repair and not itself a warranty return.

Warranty return repairs show:

- `Warranty Return`
- original visible repair code when the parent repair can be loaded
- no parent internal ID

No child-history UI or warranty workflow screen was added.

## Navigation Integration

Repairs List to Details:

- Whole repair rows continue to be the main interaction target.
- Selecting a row stores the selected repair ID in the app shell and opens Repair Details.

Details to Repairs:

- `Back to Repairs` clears the selected repair ID and returns to the Repairs List.

Dashboard to Details:

- Dashboard recent repair rows are wired to the same shell selection flow.
- The app shell switches to the Repairs destination while showing Repair Details, so the sidebar highlights repair management content.

The existing New Repair flow, Dashboard navigation, Repairs navigation, and Settings navigation were preserved.

## Deferred Action Boundaries

The details screen exposes callback boundaries for:

- `onEditRepair(Repair repair)`
- `onChangeStatus(Repair repair)`
- `onPrintRepair(Repair repair)`
- `onCreateWarrantyReturn(Repair repair)`

No destination screens, dialogs, snackbars, or fake coming-soon behavior were implemented.

## Loading State

The loading state keeps the page shell and page header intact and shows a centered `CircularProgressIndicator` inside a shared `SectionCard`.

No shimmer dependency or complex animation was added.

## Not Found State

When a repair cannot be found, the content area shows:

- `Repair not found`
- explanatory text
- `Back to Repairs`

The app does not crash and does not expose raw details.

## Error State

When loading fails, the content area shows:

- calm error title
- `Retry`
- `Back to Repairs`

Stack traces, SQL errors, and raw exception text are not shown.

## Date Formatting

Added `RepairDetailsDateFormatter`.

It converts UTC domain timestamps to local time and displays concise date and time values such as:

`05 Jul 2026, 13:00`

No localization dependency was added.

## Price Formatting

Added `DzdPriceFormatter`.

It formats integer DZD values with grouped thousands and `DA` suffix:

- `0 DA`
- `6 500 DA`
- `1 250 000 DA`

No decimals, floating-point conversion, or currency package was added.

## Shared Widgets Reused

Reused:

- `PageHeader`
- `SectionCard`
- `StatusBadge`
- `EmptyValueText`
- `PrimaryButton`
- `SecondaryButton`
- `GhostButton`

The shared button content was slightly improved so long icon+text labels ellipsize inside compact panels instead of overflowing.

## Architecture Changes

Added focused Repairs presentation pieces:

- `RepairDetailsPage`
- `repairDetailsControllerProvider`
- `RepairDetailsState`
- `RepairTimelineEntry`
- detail-specific date and price formatters

No new repository was created.

No fake use case was added for simple reads.

No backend workflow was changed.

No presentation state was added for Edit Repair, Change Status dialog, Print Preview, or Warranty Return UI.

## Database Schema

Schema version remains `4`.

No tables, columns, indexes, migrations, event-history table, or generated Drift changes were added.

## Dependencies

None.

No dependencies were added, removed, or changed.

## Tests Added

- `test/features/repairs/repair_details_test.dart`
  - Controller loads repair by ID.
  - Controller returns null for missing repairs.
  - Warranty parent/original repair code loads.
  - Timeline entries are derived from persisted received, ready, and delivered timestamps.
  - Repair Details UI renders page header, real repair code, device display, status, sections, notes, accessories, device access helper, price, and decision.
  - Missing optional values render empty markers.
  - Warranty return display shows original visible repair code.
  - Action callbacks fire for Edit Repair, Change Status, Print, and eligible Create Warranty Return.
  - Not found state renders.
  - Error state renders without raw exception text.
  - Integer DZD price formatting is covered.
  - Repairs List row opens Repair Details and Back returns to Repairs.
  - Dashboard recent repair row opens Repair Details.

Existing adjacent tests were also run:

- `test/app_shell_test.dart`
- `test/features/dashboard/dashboard_test.dart`
- `test/features/repairs/repairs_list_test.dart`

## Validation Commands

- `dart format .`
- `flutter analyze`
- `flutter test test/features/repairs/repair_details_test.dart`
- `flutter analyze`
- `flutter test test/app_shell_test.dart`
- `flutter test test/features/dashboard/dashboard_test.dart`
- `flutter test test/features/repairs/repairs_list_test.dart`
- `flutter pub get`
- `flutter test`
- `flutter build windows`
- `git status --short`

## Validation Results

Dependency resolution: succeeded. `flutter pub get` completed successfully. Flutter reported that 12 packages have newer versions incompatible with current constraints.

Code generation: not run because no Drift schema or generated-code inputs changed.

Formatting: succeeded. `dart format .` completed successfully.

Static analysis: initially reported a test-only Riverpod override type issue. After simplifying the test helper, `flutter analyze` reported no issues.

Focused Repair Details tests: initially exposed a real shared button overflow and a few overly strict test assumptions. After improving shared button label overflow handling and fixing the tests, `flutter test test/features/repairs/repair_details_test.dart` passed.

Adjacent tests:

- `flutter test test/app_shell_test.dart` passed.
- `flutter test test/features/dashboard/dashboard_test.dart` passed.
- `flutter test test/features/repairs/repairs_list_test.dart` passed.

All tests: `flutter test` passed all tests.

Windows build: attempted but not executed successfully because the current host is not Windows. Flutter returned: `"build windows" only supported on Windows hosts.`

Repository status check: `git status --short` failed because the working directory did not appear to be a Git repository.

## Issues or Limitations

- Windows build validation remains blocked by the current non-Windows environment.
- The working directory did not appear to be a Git repository when `git status --short` was attempted.
- Timeline is limited to truthfully derivable timestamp events because there is no full repair event-history table.
- Edit Repair UI is deferred.
- Change Status dialog is deferred.
- Print Preview is deferred.
- Create Warranty Return workflow UI is deferred.
- Customer price decision interaction is read-only and deferred.
- Repair Details does not implement automatic polling or timers.
- A shared button overflow issue was found during testing and resolved by ellipsizing icon+text button labels in constrained widths.

## Next Safe Step

The next safe development step is Change Status Dialog implementation using the approved Stitch reference and existing safe status workflow.
