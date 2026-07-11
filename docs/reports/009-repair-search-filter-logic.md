# Prompt 009 — Repair Search and Filter Logic

## Summary

Implemented reusable repair search and filter logic for future Repairs List UI work. The repository now supports one composable `RepairSearchQuery` with text search, status filtering, lifecycle scope filtering, received date range filtering, deterministic sorting, and limit/offset pagination.

No UI, list controllers, search bars, filter chips, delayed repair logic, printing, QR generation, backup/restore, online functionality, or sample data were added.

## Previous State Reviewed

Reports `docs/reports/001-project-foundation.md` through `docs/reports/008-warranty-return-workflow.md` were read.

Relevant starting state:

- Flutter desktop foundation, Riverpod root, and app shell existed.
- Drift schema version was `4`.
- Safe repair creation, global repair code sequence, shop settings, repair queries, status workflow, price workflow, and warranty return workflow existed.
- Existing focused read methods included lookup, recent repairs, status counts, active count, and warranty return lookup.
- There was no composable repair search/filter query.

## Files Inspected

- `docs/reports/001-project-foundation.md`
- `docs/reports/002-repair-domain-database.md`
- `docs/reports/003-shop-settings-foundation.md`
- `docs/reports/004-repair-creation-workflow.md`
- `docs/reports/005-repair-query-foundation.md`
- `docs/reports/006-repair-status-workflow.md`
- `docs/reports/007-customer-price-approval-workflow.md`
- `docs/reports/008-warranty-return-workflow.md`
- `pubspec.yaml`
- `lib/features/repairs/domain/repair_status.dart`
- `lib/features/repairs/domain/repositories/repair_repository.dart`
- `lib/features/repairs/data/tables/repairs_table.dart`
- `lib/features/repairs/data/datasources/repair_local_data_source.dart`
- `lib/features/repairs/data/repositories/drift_repair_repository.dart`
- `test/features/repairs/data/repair_query_foundation_test.dart`
- `test/features/repairs/data/warranty_return_workflow_test.dart`
- Existing file list under `lib/`, `test/`, and `docs/`

## Files Created

- `lib/features/repairs/domain/entities/repair_search_query.dart`
- `test/features/repairs/data/repair_search_filter_test.dart`
- `docs/reports/009-repair-search-filter-logic.md`

## Files Modified

- `lib/features/repairs/domain/repositories/repair_repository.dart`
- `lib/features/repairs/data/datasources/repair_local_data_source.dart`
- `lib/features/repairs/data/repositories/drift_repair_repository.dart`

## Search Query Model

`RepairSearchQuery` supports:

- `searchText`: optional text search, default `null`.
- `statuses`: optional set of `RepairStatus`, default empty set.
- `lifecycleScope`: `all`, `active`, or `finalized`, default `all`.
- `receivedFrom`: optional UTC-normalized lower received date bound.
- `receivedTo`: optional UTC-normalized upper received date bound.
- `sort`: `newestFirst` or `oldestFirst`, default `newestFirst`.
- `limit`: positive row limit, default `50`.
- `offset`: non-negative row offset, default `0`.

Validation:

- `limit` must be positive.
- `offset` must be zero or greater.
- When both date bounds are supplied, `receivedFrom` must be before `receivedTo`.

## Text Search Behavior

Searchable fields:

- visible repair code
- customer name
- customer phone
- device type
- brand
- model
- reported problem

Excluded fields:

- internal notes
- device access information
- customer-visible message

Normalization:

- Surrounding whitespace is trimmed.
- Blank search becomes no search filter.
- Meaningful internal spaces are preserved.

Case sensitivity:

- Matching is case-insensitive by applying `LOWER(...)` to searchable columns and the query pattern.

Wildcard handling:

- User-entered `%` and `_` are escaped and treated as literal characters.
- Backslashes are also escaped for the SQLite `LIKE ... ESCAPE '\'` pattern.
- Full-text search was not added.

## Status Filtering

One status:

- Filters using that status's stable database value.

Multiple statuses:

- Filters using `status IN (...)` with stable database values.

Empty status set:

- Behaves as no explicit status filter.

Enum indexes are not used.

## Lifecycle Scope

`all`:

- No lifecycle status restriction.

`active`:

- `received`
- `diagnosing`
- `waitingForCustomerApproval`
- `waitingForPart`
- `repairing`
- `readyForPickup`

`finalized`:

- `delivered`
- `cancelled`

No additional lifecycle scopes were added.

## Scope and Status Combination

Explicit statuses and lifecycle scope are combined by intersection.

Examples:

- `scope = active`, `statuses = {repairing, delivered}` returns only `repairing`.
- `scope = finalized`, `statuses = {readyForPickup}` produces an empty effective status set and returns no rows.

Neither filter silently overrides the other.

## Date Range Behavior

Timezone normalization:

- `receivedFrom` and `receivedTo` are converted to UTC in `RepairSearchQuery`.

Lower bound:

- Inclusive: `receivedFrom <= receivedAt`.

Upper bound:

- Exclusive: `receivedAt < receivedTo`.

Validation:

- If both bounds are supplied, `receivedFrom` must be before `receivedTo`.

## Sorting

Supported sort orders:

- `newestFirst`
- `oldestFirst`

Newest first:

- `receivedAt DESC`
- `id DESC`

Oldest first:

- `receivedAt ASC`
- `id ASC`

No arbitrary column sorting was added.

## Pagination

`limit`:

- Applied in Drift/SQLite.
- Must be positive.
- Defaults to `50`.

`offset`:

- Applied in Drift/SQLite.
- Must be zero or greater.
- Defaults to `0`.

Cursor pagination and paginated response DTOs were not added.

## Repository API

Added:

- `Future<List<Repair>> searchRepairs(RepairSearchQuery query)`

The method returns domain `Repair` objects and complements existing focused query methods.

## Data Source Implementation

`RepairLocalDataSource.searchRepairs` builds a Drift select query.

SQL-side behavior:

- Text search uses `LIKE` with escaped user input.
- Status filtering uses `status IN (...)`.
- Lifecycle filtering is converted into status filtering.
- Date filtering uses `received_at >= receivedFrom` and `received_at < receivedTo`.
- Sorting uses `received_at` and `id`.
- Limit and offset are applied by Drift/SQLite.

Generated Drift row classes remain internal. `DriftRepairRepository.searchRepairs` maps rows through the existing `RepairRowMapper`.

## Database Schema

Schema version remains `4`.

No schema change was made. The existing `repairs` table already contains the fields needed by this query foundation, and the current local MVP does not justify adding indexes before real usage data exists.

No migration was created, and Drift code generation was not required.

## Dependencies

None.

No dependencies were added, removed, or changed.

## Tests Added

- `test/features/repairs/data/repair_search_filter_test.dart`
  - Repair code fragment search.
  - Customer name search.
  - Customer phone search.
  - Device type search.
  - Brand search.
  - Model search.
  - Reported problem search.
  - Case-insensitive search.
  - Partial search.
  - Blank search behaves as no search filter.
  - Internal notes are not searchable.
  - Device access information is not searchable.
  - Customer-visible message is not searchable.
  - Literal `%` and `_` search behavior.
  - One-status filtering.
  - Multi-status filtering.
  - Empty status set behavior.
  - `all`, `active`, and `finalized` lifecycle scopes.
  - Scope/status intersection.
  - Empty intersection returns no rows.
  - Half-open date range behavior.
  - Invalid date range rejection.
  - Newest-first sorting.
  - Oldest-first sorting.
  - Deterministic ID tie-breakers.
  - Limit and offset pagination.
  - Invalid limit and offset validation.
  - Combined search, scope, date, sort, limit, and offset query.

## Validation Commands

- `dart format .`
- `flutter analyze`
- `dart format .`
- `flutter analyze`
- `flutter test`
- `flutter pub get`
- `flutter build windows`

## Validation Results

Dependency resolution: succeeded. `flutter pub get` completed successfully. Flutter reported that 12 packages have newer versions incompatible with current constraints.

Code generation: not run because no Drift schema or generated-code inputs changed.

Formatting: succeeded. `dart format .` completed successfully.

Static analysis: initially failed because a local test helper was referenced before declaration. After moving the helper to top level and formatting, `flutter analyze` reported no issues.

Tests: succeeded. `flutter test` passed all tests.

Windows build: attempted but not executed successfully because the current host is not Windows. Flutter returned: `"build windows" only supported on Windows hosts.`

## Issues or Limitations

- Windows build validation remains blocked by the current non-Windows environment.
- The working directory did not appear to be a Git repository when `git status --short` was attempted.
- Intermediate analyzer failure occurred in the new test file and was resolved before final validation.
- No UI, list controller, search field provider, filter provider, pagination controller, or presentation state was implemented.
- No delayed repair logic was implemented.
- No full-text search, search indexing, arbitrary column sorting, cursor pagination, or total-count response DTO was implemented.
- No printing, QR generation, online tracking, backup/restore, deletion, customer management, inventory, suppliers, employees, authentication, licensing, reports, analytics, or sample data were implemented.

## Next Safe Step

The next safe development step is ready-for-pickup and delayed repair logic.
