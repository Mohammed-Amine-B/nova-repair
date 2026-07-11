# Prompt 015 — Dashboard UI

## Summary

Implemented the Dashboard screen using real offline repair data. The Dashboard now has a shared page header, four real summary cards, a recent repairs table, a needs-attention panel, a focused Riverpod Dashboard controller/state, loading/empty/error states, deterministic attention thresholds, local date display formatting, and tests covering state, UI, navigation, and refresh behavior.

No Repairs List, New Repair form, Repair Details screen, Settings UI, Print Preview, Backup & Restore UI, charts, revenue metrics, fake data, or backend workflow changes were added.

## Previous State Reviewed

Reports `docs/reports/001-project-foundation.md` through `docs/reports/014-shared-ui-foundation.md` were read.

Relevant starting state:

- Shared app shell and `NovaSidebar` existed.
- Shared `PageHeader`, `SectionCard`, `StatusBadge`, `EmptyValueText`, table primitives, buttons, and theme tokens existed.
- Repair repository already exposed real queries for active count, status counts, recent repairs, and attention counts.
- Dashboard was still a placeholder page.

The requested UI specification path `design_reference/NOVA_REPAIR_UI_SPEC.md` was checked during the previous UI foundation work and remains absent from this repository. The Dashboard Stitch references and design-system document were reviewed and used without copying fake sample data.

## Design References Used

Source-of-truth priority:

1. `design_reference/NOVA_REPAIR_UI_SPEC.md` - missing from repository.
2. Approved Dashboard screenshot.
3. Dashboard `code.html`.
4. Stitch design-system document.

Design files used:

- `design_reference/stitch/stitch_nova_repair_dashboard_management/nova_repair_dashboard_refined/screen.png`
- `design_reference/stitch/stitch_nova_repair_dashboard_management/nova_repair_dashboard_refined/code.html`
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
- `lib/features/dashboard/dashboard_page.dart`
- `lib/features/repairs/domain/repositories/repair_repository.dart`
- `lib/features/repairs/repair_providers.dart`
- `lib/features/repairs/data/repositories/drift_repair_repository.dart`
- `lib/features/repairs/data/datasources/repair_local_data_source.dart`
- `lib/features/repairs/domain/entities/repair.dart`
- `lib/features/repairs/domain/entities/repair_attention_counts.dart`
- `lib/features/repairs/domain/entities/change_repair_status_input.dart`
- `lib/features/repairs/domain/repair_status.dart`
- `lib/features/printing/application/device_display_name_formatter.dart`
- `lib/features/printing/application/build_repair_print_data_use_case.dart`
- `lib/app/app_shell.dart`
- `lib/app/widgets/table/app_table_shell.dart`
- `lib/app/widgets/section_card.dart`
- `test/app_shell_test.dart`
- `test/features/repairs/data/repair_creation_workflow_test.dart`
- `test/features/repairs/data/repair_status_workflow_test.dart`
- `test/database/app_database_test.dart`

## Files Created

- `lib/features/dashboard/presentation/dashboard_controller.dart`
- `lib/features/dashboard/presentation/dashboard_state.dart`
- `lib/features/dashboard/presentation/dashboard_date_formatter.dart`
- `lib/features/dashboard/presentation/widgets/dashboard_summary_card.dart`
- `lib/features/repairs/domain/services/device_display_name_formatter.dart`
- `test/features/dashboard/dashboard_test.dart`
- `docs/reports/015-dashboard-ui.md`

## Files Modified

- `lib/features/dashboard/dashboard_page.dart`
- `lib/app/app_shell.dart`
- `lib/features/printing/application/build_repair_print_data_use_case.dart`
- `test/app_shell_test.dart`
- `test/features/printing/application/build_repair_print_data_use_case_test.dart`

Deleted:

- `lib/features/printing/application/device_display_name_formatter.dart`

The device display-name formatter was moved into the Repairs domain services area so Dashboard and Printing can share one repair-oriented formatting rule without Dashboard depending on the Printing feature.

## Dashboard Layout

The Dashboard follows the approved desktop composition:

- Shared `PageHeader` at the top.
- Four compact summary cards in one row.
- Lower two-column content area:
  - Recent Repairs table takes the larger left area.
  - Needs Attention panel takes the narrower right area.

No mobile stacking, charts, revenue blocks, notification controls, account controls, or New Repair UI were added.

## Summary Cards

Four Dashboard-specific `DashboardSummaryCard` widgets were added:

- Active Repairs: uses `RepairRepository.getActiveRepairCount()`.
- Waiting for Approval: uses `RepairRepository.getStatusCounts()` and reads `RepairStatus.waitingForCustomerApproval`.
- Waiting for Part: uses `RepairRepository.getStatusCounts()` and reads `RepairStatus.waitingForPart`.
- Ready for Pickup: uses `RepairRepository.getStatusCounts()` and reads `RepairStatus.readyForPickup`.

The Dashboard does not redefine active/final status rules.

## Recent Repairs

Repository query:

- `RepairRepository.getRecentRepairs(limit: 5)`

Columns:

- Repair Code
- Device
- Customer
- Status
- Received Date

Device display behavior:

- Uses the shared `DeviceDisplayNameFormatter` now located at `lib/features/repairs/domain/services/device_display_name_formatter.dart`.

Missing values:

- Missing customer name renders with `EmptyValueText` as `—`.
- Missing device details fall back to `Device` through the shared formatter.

Row interaction decision:

- Dashboard rows accept an `onRepairSelected` callback boundary.
- The app shell does not pass a callback yet because Repair Details UI is not implemented.
- No fake Repair Details page was created.

View all repairs behavior:

- The `View all repairs →` action calls the app shell callback and switches to the existing Repairs destination.
- No routing package was added.

## Needs Attention

The Needs Attention panel uses real `RepairRepository.getAttentionCounts(...)`.

Categories:

- Waiting for customer approval: `attentionCounts.waitingForCustomerApproval`.
- Ready for pickup over 5 days: `readyBefore = DateTime.now().toUtc() - Duration(days: 5)`.
- Open for over 14 days: `delayedBefore = DateTime.now().toUtc() - Duration(days: 14)`.

The Dashboard does not recompute attention rows in Dart and does not hard-code repository thresholds.

## Dashboard State

Created:

- `DashboardState`
- `DashboardController`
- `dashboardControllerProvider`
- `dashboardClockProvider`

State fields:

- `activeRepairCount`
- `waitingForApprovalCount`
- `waitingForPartCount`
- `readyForPickupCount`
- `recentRepairs`
- `attentionCounts`

Load strategy:

1. Read `RepairRepository`.
2. Compute UTC cutoffs from the Dashboard clock.
3. Start reads for status counts, active count, recent repairs, and attention counts.
4. Return one coherent `DashboardState`.

Refresh behavior:

- `DashboardController.refreshDashboard()` reloads the same state.
- No automatic polling, timers, or background refresh were added.

## Loading State

Dashboard shows the shared page header and a centered `CircularProgressIndicator` in the content area.

No shimmer package or elaborate animation was added.

## Empty State

For a brand-new database:

- Summary cards show `0`.
- Needs Attention counts show `0`.
- Recent Repairs shows:
  - `No repairs yet`
  - `New repairs will appear here.`

No fake sample rows are displayed.

## Error State

If Dashboard loading fails:

- The app shell remains intact.
- Dashboard shows a calm inline error message.
- A `Retry` action calls `refreshDashboard()`.
- Stack traces and raw database details are not shown.

## Date Formatting

`DashboardDateFormatter` converts UTC domain timestamps to local time with `toLocal()` and displays a concise date such as `05 Jul 2026`.

No localization package was added.

## Shared Widgets Reused

Reused:

- `PageHeader`
- `SectionCard`
- `StatusBadge`
- `EmptyValueText`
- `AppTableShell`
- `AppTableRowShell`
- `SecondaryButton`

The Dashboard does not duplicate sidebar, status badge, or table styling.

## Architecture Changes

Dashboard-specific presentation files were added under `lib/features/dashboard/presentation/`.

No Dashboard repository was created. The Dashboard depends directly on the existing `RepairRepository` because this screen only aggregates existing read operations.

No fake use cases were added.

Intentionally deferred:

- Repairs List controller.
- Repair Details navigation.
- New Repair action.
- Dashboard auto-refresh.
- Screen-specific routing package.

## Database Schema

Schema version remains `4`.

No database tables, columns, indexes, or migrations were added.

## Dependencies

None.

No dependencies were added, removed, or changed.

## Tests Added

- `test/features/dashboard/dashboard_test.dart`
  - Dashboard state loads active repair count.
  - Waiting approval, waiting part, and ready-for-pickup counts load from real status counts.
  - Recent repairs load from the real repository query.
  - Attention counts use deterministic 5-day and 14-day UTC cutoffs.
  - Empty database produces zero counts and empty recent repairs.
  - Dashboard UI renders title, subtitle, summary cards, real counts, Recent Repairs, Needs Attention, real repair rows, and shared status labels.
  - Dashboard UI shows empty state for a new database.
  - Dashboard UI does not depend on Stitch sample values such as `REP-0042`, `Ahmed Benali`, or `HP EliteBook 840`.
  - `View all repairs →` navigates to the existing Repairs destination.
  - Refresh after a real repair status change updates Dashboard counts.

Updated:

- `test/app_shell_test.dart`
  - Uses an in-memory database override now that Dashboard reads real data.
  - Expects the real Dashboard subtitle and empty state.

Updated:

- `test/features/printing/application/build_repair_print_data_use_case_test.dart`
  - Imports the moved device display-name formatter from Repairs domain services.

## Validation Commands

- `dart format .`
- `flutter analyze`
- `flutter test test/features/dashboard/dashboard_test.dart`
- `flutter test test/features/dashboard/dashboard_test.dart`
- `flutter test test/app_shell_test.dart`
- `flutter pub get`
- `flutter analyze`
- `flutter test`
- `flutter build windows`
- `git status --short`

## Validation Results

Dependency resolution: succeeded. `flutter pub get` completed successfully. Flutter reported that 12 packages have newer versions incompatible with current constraints.

Formatting: succeeded. `dart format .` completed successfully.

Static analysis: initially reported a stale test import after moving `DeviceDisplayNameFormatter` and one unused app-shell-test import. After fixes, `flutter analyze` reported no issues.

Focused tests: initially one Dashboard UI assertion was too strict because `Ready for Pickup` correctly appeared both as a summary label and a status badge. After relaxing that assertion, `flutter test test/features/dashboard/dashboard_test.dart` passed.

Shell smoke tests: `flutter test test/app_shell_test.dart` passed.

All tests: `flutter test` passed all tests.

Windows build: attempted but not executed successfully because the current host is not Windows. Flutter returned: `"build windows" only supported on Windows hosts.`

Repository status check: `git status --short` failed because the working directory did not appear to be a Git repository.

Code generation: not run because no Drift schema or generated-code inputs changed.

## Issues or Limitations

- `design_reference/NOVA_REPAIR_UI_SPEC.md` is still missing from the repository.
- Windows build validation remains blocked by the current non-Windows environment.
- The working directory did not appear to be a Git repository when `git status --short` was attempted.
- Repair Details UI does not exist yet, so recent repair row taps are only exposed as a callback boundary and are not wired by the app shell.
- Dashboard uses fixed desktop composition and does not implement mobile/tablet responsive stacking.
- No New Repair button/action was added to Dashboard because the prompt preferred the approved specification and New Repair UI is not implemented yet.
- No charts, revenue, fake activity, notifications, account controls, Repairs List UI, New Repair UI, Settings UI, Print Preview UI, Backup & Restore UI, or backend workflow changes were implemented.

## Next Safe Step

The next safe development step is Repairs List UI implementation using the approved Stitch reference and existing search/filter logic.
