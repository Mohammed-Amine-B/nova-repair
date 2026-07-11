# Prompt 005 — Repair Query Foundation

## Summary

Implemented the repair query foundation needed by future Dashboard, Repairs List, and Repair Details screens. The repair repository now supports focused read operations for lookup by ID, lookup by visible repair code, recent repairs, grouped status counts, and total active repair count.

No UI, presentation state, search, filters, status updates, editing, deletion, printing, QR generation, online tracking, or dashboard-specific methods were added.

## Previous State Reviewed

Reports `docs/reports/001-project-foundation.md`, `docs/reports/002-repair-domain-database.md`, `docs/reports/003-shop-settings-foundation.md`, and `docs/reports/004-repair-creation-workflow.md` were read.

Relevant starting state:

- Flutter desktop foundation and app shell existed.
- Drift schema version was 4.
- `repairs`, `shop_settings`, and `repair_code_sequence` tables existed.
- Repair creation used safe generated visible codes.
- Repair lookup by ID and visible code already existed.
- No repair list UI, repair detail UI, dashboard query foundation, search, filters, or status workflow existed.

## Files Inspected

- `docs/reports/001-project-foundation.md`
- `docs/reports/002-repair-domain-database.md`
- `docs/reports/003-shop-settings-foundation.md`
- `docs/reports/004-repair-creation-workflow.md`
- `lib/features/repairs/domain/repositories/repair_repository.dart`
- `lib/features/repairs/data/datasources/repair_local_data_source.dart`
- `lib/features/repairs/data/repositories/drift_repair_repository.dart`
- `lib/features/repairs/repair_providers.dart`
- `test/features/repairs/data/repair_creation_workflow_test.dart`
- `test/features/repairs/data/repair_persistence_test.dart`
- Existing file list under `lib/`, `test/`, and `docs/`

## Files Created

- `test/features/repairs/data/repair_query_foundation_test.dart`
- `docs/reports/005-repair-query-foundation.md`

## Files Modified

- `lib/features/repairs/domain/repositories/repair_repository.dart`
- `lib/features/repairs/data/datasources/repair_local_data_source.dart`
- `lib/features/repairs/data/repositories/drift_repair_repository.dart`

## Repository Query API

The `RepairRepository` now exposes:

- `getRepairById(int id)`: returns a domain `Repair` or null.
- `getRepairByCode(String repairCode)`: trims the incoming code, then returns a domain `Repair` or null.
- `getRecentRepairs({required int limit})`: returns recent repairs as `List<Repair>`.
- `getStatusCounts()`: returns `Map<RepairStatus, int>`.
- `getActiveRepairCount()`: returns the total number of non-final repairs.

The repository still exposes safe repair creation through `createRepair(CreateRepairInput input)`.

## Recent Repairs Query

Ordering:

- Primary order: `receivedAt` descending.
- Tie-breaker: internal `id` descending.

Limit validation:

- `limit` must be positive.
- Zero and negative limits throw `ArgumentError`.

SQL/Drift behavior:

- Ordering is performed by Drift/SQLite.
- The limit is applied by Drift/SQLite.
- The query does not load the entire table and trim in Dart.

## Status Count Definition

Included statuses:

- `received`
- `diagnosing`
- `waitingForCustomerApproval`
- `waitingForPart`
- `repairing`
- `readyForPickup`
- `delivered`
- `cancelled`

Return type:

- `Map<RepairStatus, int>`

Missing-status behavior:

- The repository initializes all known statuses to zero.
- Statuses with no rows resolve safely to `0`.

Invalid stored-value behavior:

- Grouped database status strings are converted with `RepairStatus.fromDatabaseValue`.
- Invalid stored values throw `FormatException` instead of being silently ignored.

## Active Repair Definition

Active repairs are repairs not in final states.

Active statuses:

- `received`
- `diagnosing`
- `waitingForCustomerApproval`
- `waitingForPart`
- `repairing`
- `readyForPickup`

Final statuses:

- `delivered`
- `cancelled`

The active count query counts only active status database values.

## Data Source Implementation

Query strategy:

- Existing lookup methods continue to use Drift selects.
- Recent repair ordering and limit are expressed directly in the Drift query.
- Status counts use a grouped Drift query over `status`.
- Active count uses a SQL-side count with `status IN (...)`.

SQL-side behavior:

- Recent ordering happens in SQL.
- Recent limit happens in SQL.
- Status grouped counting happens in SQL.
- Active counting happens in SQL.

Mapping:

- Repository methods map `RepairRow` through the existing `RepairRowMapper`.
- Generated Drift row classes are not exposed as public domain results.

## Architecture Changes

Repository changes:

- Added focused read operations to `RepairRepository`.
- Implemented those operations in `DriftRepairRepository`.

Data source changes:

- Added `getRecentRepairs`.
- Added `getStatusCountsByDatabaseValue`.
- Added `getActiveRepairCount`.

Presentation layers intentionally not created:

- No Dashboard controller.
- No Repairs List controller.
- No Repair Details controller.
- No search controller.
- No filter controller.
- No UI state providers.

Riverpod providers did not need changes because the existing repository provider already exposes the repository API.

## Database Schema

Schema version remains `4`.

No schema change was made because the required queries can be implemented efficiently with the existing `repairs` table. No new indexes were added; the current local MVP query volume does not justify a migration solely for speculative performance tuning.

No migration was created.

## Dependencies

None.

No dependencies were added, removed, or changed.

## Tests Added

- `test/features/repairs/data/repair_query_foundation_test.dart`
  - Lookup by internal ID succeeds.
  - Lookup by visible code succeeds and trims surrounding whitespace.
  - Missing ID returns null.
  - Missing visible code returns null.
  - Empty recent repairs query returns an empty list.
  - Recent repairs order by `receivedAt` descending.
  - Recent repairs tie-break by ID descending.
  - Recent repairs limit is applied.
  - Zero and negative limits are rejected.
  - Status grouped counts are correct.
  - Missing statuses resolve to zero.
  - Delivered and cancelled are counted separately.
  - Invalid stored status values throw `FormatException`.
  - Active repair count includes all active statuses.
  - Active repair count excludes delivered and cancelled repairs.

## Validation Commands

- `dart format .`
- `flutter analyze`
- `flutter test`
- `flutter pub get`
- `flutter build windows`

## Validation Results

Dependency resolution: succeeded. `flutter pub get` completed successfully. Flutter reported that 12 packages have newer versions incompatible with current constraints.

Code generation: not run because no Drift schema or generated-code inputs changed.

Formatting: succeeded. `dart format .` completed successfully.

Static analysis: initially failed because a local test helper was referenced before declaration. After moving it to a top-level helper with explicit parameters, `flutter analyze` reported no issues.

Tests: initially failed for the same test helper compile issue. After the fix, `flutter test` passed all tests.

Windows build: attempted but not executed successfully because the current host is not Windows. Flutter returned: `"build windows" only supported on Windows hosts.`

## Issues or Limitations

- Windows build validation remains blocked by the current non-Windows environment.
- Intermediate analyzer and test failures occurred in the new test file and were resolved before the final validation pass.
- No UI or presentation state was implemented.
- No search, filters, pagination tokens, status updates, editing, deletion, dashboard view models, printing, QR generation, online tracking, backup/restore, customer management, inventory, suppliers, employees, authentication, licensing, reports, analytics, or sample data were implemented.
- No indexes were added; schema remains version 4.

## Next Safe Step

The next safe development step is the repair status workflow.
