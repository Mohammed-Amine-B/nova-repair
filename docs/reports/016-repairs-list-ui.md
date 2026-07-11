# Prompt 016 — Repairs List UI

## Summary

Implemented the Repairs List screen using real offline repair data and the existing search/filter repository foundation. The Repairs page now has a shared page header, New Repair callback boundary, debounced search, main filters, More Filters menu, quick filter chips, real paginated repair table, old active repair indicator, loading state, empty states, error state, and focused Riverpod presentation state.

No New Repair form, Repair Details screen, Edit Repair screen, Change Status dialog, Print Preview, Settings UI, Backup UI, schema changes, fake repair rows, or backend workflow changes were added.

## Previous State Reviewed

Reports `docs/reports/001-project-foundation.md` through `docs/reports/015-dashboard-ui.md` were read.

Relevant starting state:

- Shared app shell, `NovaSidebar`, theme tokens, shared buttons, `PageHeader`, `SectionCard`, `StatusBadge`, `EmptyValueText`, and table primitives existed.
- Dashboard UI already used real repair data.
- `RepairRepository.searchRepairs(RepairSearchQuery)` already supported backend text search, status filters, lifecycle scopes, date ranges, sorting, limit, and offset.
- Repairs page was still a placeholder.

The requested `design_reference/NOVA_REPAIR_UI_SPEC.md` file was checked and is still missing from this repository. The Repairs List Stitch reference and design-system document were used without copying fake sample data.

## Design References Used

Source-of-truth priority:

1. `design_reference/NOVA_REPAIR_UI_SPEC.md` - missing from repository.
2. Approved Repairs List screenshot.
3. Repairs List `code.html`.
4. Stitch design-system document.

Design files used:

- `design_reference/stitch/stitch_nova_repair_dashboard_management/nova_repair_repairs_list_refined/screen.png`
- `design_reference/stitch/stitch_nova_repair_dashboard_management/nova_repair_repairs_list_refined/code.html`
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
- Attached Prompt 016 request text
- `design_reference/stitch/stitch_nova_repair_dashboard_management/nova_repair_repairs_list_refined/code.html`
- `design_reference/stitch/stitch_nova_repair_dashboard_management/nova_repair_repairs_list_refined/screen.png`
- `design_reference/stitch/stitch_nova_repair_dashboard_management/nova_repair_design_system/DESIGN.md`
- `lib/features/repairs/repairs_page.dart`
- `lib/features/repairs/domain/entities/repair_search_query.dart`
- `lib/features/repairs/domain/repositories/repair_repository.dart`
- `lib/features/repairs/domain/repair_status.dart`
- `lib/features/repairs/domain/services/device_display_name_formatter.dart`
- `lib/features/repairs/repair_providers.dart`
- `lib/app/app_shell.dart`
- `lib/app/widgets/table/app_table_shell.dart`
- `test/app_shell_test.dart`
- `test/features/dashboard/dashboard_test.dart`
- Existing file list under `lib/`, `test/`, `docs/`, and `design_reference/`

## Files Created

- `lib/features/repairs/presentation/repairs_list_controller.dart`
- `lib/features/repairs/presentation/repairs_list_state.dart`
- `lib/features/repairs/presentation/repairs_list_date_formatter.dart`
- `test/features/repairs/repairs_list_test.dart`
- `docs/reports/016-repairs-list-ui.md`

## Files Modified

- `lib/features/repairs/repairs_page.dart`
- `lib/app/app_shell.dart`
- `lib/app/widgets/table/app_table_shell.dart`
- `test/app_shell_test.dart`
- `test/features/dashboard/dashboard_test.dart`

## Repairs List Layout

The Repairs page now uses:

- Shared `PageHeader` with title `Repairs` and subtitle `Manage and track all repair jobs`.
- Shared `PrimaryButton` for `New Repair`.
- Shared `SectionCard` for search and filters.
- A desktop-first table area with shared table styling.
- Pagination controls at the bottom of the table.

The main desktop layout keeps filters in one row. When constrained, the filters stack to avoid layout overflow while preserving the same controls.

## Search Behavior

Search uses `RepairSearchQuery.searchText` through `RepairRepository.searchRepairs`.

UI behavior:

- One search field.
- Placeholder: `Search by repair code, customer, phone, or device`.
- Debounce duration: `300ms`.
- Implemented with `dart:async` `Timer`.
- Timer is cancelled on provider disposal and when search text changes.
- Blank/trim behavior remains owned by `RepairSearchQuery`.

The UI does not search in Dart and does not expose internal notes, device access information, or customer messages.

## Main Filters

Implemented main filters:

- `All Statuses` dropdown with one selected `RepairStatus` at a time.
- `All Dates` dropdown with `All Dates`, `Today`, `Last 7 Days`, and `Last 30 Days`.
- `More Filters` popup menu with lifecycle scope and sort options.

Date preset behavior:

- Date presets use local calendar boundaries.
- The controller converts boundaries to UTC before creating `RepairSearchQuery`.
- Date ranges use the existing backend half-open behavior.

More Filters behavior:

- Lifecycle options: `All`, `Active`, `Finalized`.
- Sort options: `Newest first`, `Oldest first`.
- No unsupported backend options were added.

## Quick Filters

Implemented quick chips:

- `All`
- `Active`
- `Waiting for Approval`
- `Waiting for Part`
- `Ready for Pickup`
- `Delivered`

Quick filters map to existing `RepairSearchQuery` status and lifecycle behavior. They do not create separate query logic.

## Repairs List State

Added:

- `RepairsListState`
- `RepairsListController`
- `repairsListControllerProvider`
- `repairsListClockProvider`

State tracks:

- current repairs
- search text
- quick filter
- selected status
- date preset
- lifecycle scope
- sort
- offset
- page size

The controller builds one `RepairSearchQuery` and reads from `RepairRepository.searchRepairs`.

## Pagination

Page size is `20`.

Pagination behavior:

- Previous is available when `offset > 0`.
- Next is available when the current result count equals page size.
- Search, filter, lifecycle, date, sort, and quick-filter changes reset offset to `0`.
- Limit and offset are applied through the existing repository query, not in presentation code.

## Table

The table columns are:

- Repair Code
- Device
- Customer
- Phone
- Status
- Received Date
- Last Updated
- chevron action indicator

Device display uses `DeviceDisplayNameFormatter` from the Repairs domain services.

Missing values:

- Missing customer name uses `EmptyValueText`.
- Missing customer phone uses `EmptyValueText`.
- Missing device details fall back to `Device` through the shared formatter.

Rows expose an `onRepairSelected(Repair)` callback boundary. The app shell does not wire this yet because Repair Details UI does not exist.

## Old Repair Indicator

The Repairs List shows a subtle amber old-active indicator when:

- the repair is not finalized
- and `receivedAt` is at least 14 local calendar days before the current clock date

The indicator text is `Open N days`.

Delivered and cancelled repairs do not show the old active indicator.

No database column or stored derived value was added.

## Loading State

The page keeps the header and filters visible while the list is loading, then shows a centered `CircularProgressIndicator` in the content area.

No shimmer package or animation dependency was added.

## Empty States

Brand-new database:

- `No repairs yet`
- `Create your first repair to get started.`

Filtered or searched no-results state:

- `No repairs found`
- `Try adjusting your search or filters.`

No fake repairs or Stitch sample rows are displayed.

## Error State

If loading fails, the page shows:

- `Repairs could not be loaded.`
- `Please try again.`
- `Retry`

The retry action calls `RepairsListController.refresh()`. Raw exceptions and stack traces are not shown.

## New Repair Action

`RepairsPage` exposes an `onNewRepair` callback boundary and renders the `New Repair` button through the shared `PrimaryButton`.

The app shell leaves this callback unwired because the New Repair form does not exist yet. No placeholder form, modal, dialog, route, or snackbar was added.

## Repair Row Interaction

`RepairsPage` exposes an `onRepairSelected(Repair)` callback boundary for future Repair Details navigation.

The app shell does not pass a callback yet because Repair Details UI is intentionally not implemented in this prompt.

## Shared Widgets Reused

Reused:

- `PageHeader`
- `SectionCard`
- `PrimaryButton`
- `GhostButton`
- `SecondaryButton`
- `StatusBadge`
- `EmptyValueText`
- `AppTableShell`
- `AppTableRowShell`

`AppTableShell` received an optional `expandChild` flag so table bodies that contain an internal `Expanded` list can be bounded safely. Existing uses keep the default behavior.

## Architecture Changes

Added Repairs presentation files under `lib/features/repairs/presentation/`:

- `repairs_list_controller.dart`
- `repairs_list_state.dart`
- `repairs_list_date_formatter.dart`

No Repairs List repository, use case, data source, or backend query was created. The screen uses the existing `RepairRepository.searchRepairs` API.

Intentionally deferred:

- New Repair form state.
- Repair Details controller.
- Edit Repair controller.
- Change Status dialog state.
- Multi-select status filter state.
- Route package.

## Database Schema

Schema version remains `4`.

No database tables, columns, indexes, or migrations were added. The existing `repairs` table and `RepairSearchQuery` API already support the required list behavior.

## Dependencies

None.

No dependencies were added, removed, or changed.

## Tests Added

- `test/features/repairs/repairs_list_test.dart`
  - Controller default query loads newest repairs first.
  - Search applies after debounce.
  - Quick filters map to backend query behavior.
  - Status filter, date preset, lifecycle filter, sort, clear filters, and pagination behavior work.
  - UI renders header, filters, quick chips, real table rows, missing values, status labels, and old repair indicator.
  - UI does not display Stitch sample values such as `REP-0042`, `Ahmed Benali`, or `HP EliteBook 840`.
  - New Repair button invokes the callback boundary.
  - Repair row tap invokes the selection callback boundary.
  - Search no-results state and clear filters work.
  - Empty database state renders.
  - Error state renders with retry.
  - Pagination next and previous render real pages.
  - Refresh after a real repair status change updates the list.

Updated:

- `test/app_shell_test.dart`
  - Expects the real Repairs page instead of the old placeholder.

- `test/features/dashboard/dashboard_test.dart`
  - Expects Dashboard `View all repairs →` to navigate to the real Repairs page.

## Validation Commands

- `dart format .`
- `flutter analyze`
- `flutter test test/features/repairs/repairs_list_test.dart`
- `flutter test test/app_shell_test.dart test/features/dashboard/dashboard_test.dart`
- `flutter pub get`
- `flutter test`
- `flutter build windows`
- `git status --short`

## Validation Results

Dependency resolution: succeeded. `flutter pub get` completed successfully. Flutter reported that 12 packages have newer versions incompatible with current constraints.

Code generation: not run because no Drift schema or generated-code inputs changed.

Formatting: succeeded. `dart format .` completed successfully.

Static analysis: initially failed during implementation for small stale issues and then passed. Final `flutter analyze` reported no issues.

Focused Repairs List tests: initially failed due layout constraints in the new Repairs List UI and a row-tap test targeting inner text instead of the row shell. After fixing table bounds, responsive filter wrapping, small-height states, and test tapping, `flutter test test/features/repairs/repairs_list_test.dart` passed.

Shell/Dashboard focused tests: initially failed because tests still expected the old Repairs placeholder and because the default Flutter test window exposed constrained-size layout issues. After updating expectations and making the Repairs page handle constrained sizes, `flutter test test/app_shell_test.dart test/features/dashboard/dashboard_test.dart` passed.

All tests: succeeded. `flutter test` passed all tests.

Windows build: attempted but not executed successfully because the current host is not Windows. Flutter returned: `"build windows" only supported on Windows hosts.`

Repository status check: `git status --short` failed because the working directory did not appear to be a Git repository.

## Issues or Limitations

- `design_reference/NOVA_REPAIR_UI_SPEC.md` is still missing from the repository.
- Windows build validation remains blocked by the current non-Windows environment.
- The working directory did not appear to be a Git repository when `git status --short` was attempted.
- New Repair button is a callback boundary only; the app shell does not wire it yet because New Repair UI is not implemented.
- Repair row selection is a callback boundary only; the app shell does not wire it yet because Repair Details UI is not implemented.
- Status filtering is single-select in the UI even though the backend supports multiple statuses.
- Pagination uses the current limit/offset foundation and does not show total result count.
- No New Repair form, Repair Details screen, Edit Repair workflow, Change Status dialog, Print Preview, Settings UI, Backup UI, QR embedding, online tracking, reports, analytics, or sample data were implemented.

## Next Safe Step

The next safe development step is New Repair form UI implementation using the approved Stitch reference and the existing repair creation workflow.
