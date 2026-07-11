# Prompt 010 — Ready and Delayed Repair Logic

## Summary

Implemented read-only derived query logic for ready-for-pickup repairs, repairs ready for pickup too long, delayed active repairs, and practical attention counts for future Dashboard use.

No UI, Dashboard presentation state, cards, notifications, background jobs, timers, automatic status changes, printing, QR generation, backup/restore, online functionality, deletion, reports, analytics, or sample data were added.

## Previous State Reviewed

Reports `docs/reports/001-project-foundation.md` through `docs/reports/009-repair-search-filter-logic.md` were read.

Relevant starting state:

- Flutter desktop foundation, Riverpod root, and desktop app shell existed.
- Drift schema version was `4`.
- Repair creation, global repair code sequence, shop settings, repair query foundation, status workflow, customer price workflow, warranty return workflow, and composable search/filter logic existed.
- Existing repository reads included lookup, recent repairs, warranty return lookup, status counts, active count, and composable search.
- There was no dedicated ready-for-pickup, delayed active, or attention-summary query logic.

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
- Attached Prompt 010 request text
- `lib/features/repairs/domain/repositories/repair_repository.dart`
- `lib/features/repairs/domain/entities/repair_search_query.dart`
- `lib/features/repairs/data/tables/repairs_table.dart`
- `lib/features/repairs/data/datasources/repair_local_data_source.dart`
- `lib/features/repairs/data/repositories/drift_repair_repository.dart`
- `lib/features/repairs/repair_providers.dart`
- `test/features/repairs/data/repair_status_workflow_test.dart`
- `test/features/repairs/data/warranty_return_workflow_test.dart`
- Existing file list under `lib/`, `test/`, and `docs/`

## Files Created

- `lib/features/repairs/domain/entities/repair_attention_counts.dart`
- `test/features/repairs/data/repair_attention_query_test.dart`
- `docs/reports/010-ready-delayed-repair-logic.md`

## Files Modified

- `lib/features/repairs/domain/repositories/repair_repository.dart`
- `lib/features/repairs/data/datasources/repair_local_data_source.dart`
- `lib/features/repairs/data/repositories/drift_repair_repository.dart`

## Ready for Pickup Definition

A repair qualifies when:

- `status == readyForPickup`

Ordering:

- `readyAt ASC`
- `id ASC`

Missing `readyAt` behavior:

- A `readyForPickup` repair with `readyAt == null` is included.
- SQLite ascending ordering places null `readyAt` values first, so inconsistent ready rows surface before normal ready rows.

Pagination:

- `limit` must be positive.
- `offset` must be zero or greater.
- Limit and offset are applied in Drift/SQLite.

## Ready Too Long Definition

A repair qualifies when:

- `status == readyForPickup`
- and either `readyAt < readyBefore` or `readyAt IS NULL`

Cutoff boundary:

- The comparison is strict.
- A repair exactly at `readyBefore` is excluded.

Missing `readyAt` behavior:

- Missing `readyAt` is treated as needing attention and included.
- This prevents inconsistent ready records from being hidden.

## Delayed Active Repair Definition

A repair qualifies when:

- its status is active
- and `receivedAt < receivedBefore`

Active statuses reuse the established query-foundation definition:

- `received`
- `diagnosing`
- `waitingForCustomerApproval`
- `waitingForPart`
- `repairing`
- `readyForPickup`

Final statuses:

- `delivered`
- `cancelled`

Final repairs never qualify as delayed active repairs.

Cutoff boundary:

- The comparison is strict.
- A repair exactly at `receivedBefore` is excluded.

Ordering:

- `receivedAt ASC`
- `id ASC`

## Attention Counts

`RepairAttentionCounts` was added as a small domain-friendly result type with:

- `waitingForCustomerApproval`: count of repairs with `status = waitingForCustomerApproval`
- `readyTooLong`: count of ready repairs where `readyAt < readyBefore` or `readyAt IS NULL`
- `delayedActive`: count of active repairs where `receivedAt < delayedBefore`

All counts are calculated in Drift/SQLite and return `0` when nothing matches.

## Time Strategy

All supplied cutoff values are normalized with `toUtc()` before comparison.

The repository accepts explicit cutoff values:

- `readyBefore`
- `receivedBefore`
- `delayedBefore`

No duration thresholds such as 5 days or 14 days are hard-coded in the repository. Future UI or Dashboard logic can choose those thresholds and pass deterministic UTC cutoffs.

## Repository API

Added to `RepairRepository`:

- `getReadyForPickupRepairs({required int limit, required int offset})`
- `getReadyTooLongRepairs({required DateTime readyBefore, required int limit, required int offset})`
- `getDelayedActiveRepairs({required DateTime receivedBefore, required int limit, required int offset})`
- `getAttentionCounts({required DateTime readyBefore, required DateTime delayedBefore})`

Existing query, status, price, creation, and warranty methods were preserved.

## Data Source Implementation

`RepairLocalDataSource` now performs:

- ready-for-pickup filtering with `status = ready_for_pickup`
- ready-too-long filtering with `status = ready_for_pickup` and `(ready_at IS NULL OR ready_at < cutoff)`
- delayed-active filtering with `status IN activeStatuses` and `received_at < cutoff`
- ready ordering by `ready_at ASC, id ASC`
- delayed ordering by `received_at ASC, id ASC`
- SQL-side count queries for waiting approval, ready too long, and delayed active repairs
- SQL-side limit and offset pagination for list queries

The repository maps generated Drift rows through the existing mapper and continues returning domain `Repair` objects.

## Architecture Changes

Added:

- `RepairAttentionCounts`, a small domain/query result type for business attention counts.
- Focused repository methods for ready, ready-too-long, delayed-active, and attention-count queries.

Shared status definition:

- Delayed active query behavior reuses `RepairSearchQuery.activeStatuses` through the repository's active status database-value helper.
- No competing active-status definition was added to production code.

Presentation layers intentionally deferred:

- No Dashboard controller.
- No attention-card provider.
- No repair list controller.
- No periodic refresh provider.
- No timer or notification service.
- No UI state providers.

## Database Schema

Schema version remains `4`.

No schema change was required because the existing `repairs` table already contains:

- `status`
- `received_at`
- `ready_at`
- `id`

No derived columns such as `isDelayed`, `isOld`, `needsAttention`, or `readyTooLong` were added.

No indexes were added. The current local MVP does not yet justify a schema migration for speculative performance tuning.

## Dependencies

None.

No dependencies were added, removed, or changed.

## Tests Added

- `test/features/repairs/data/repair_attention_query_test.dart`
  - Ready-for-pickup query includes only ready repairs.
  - Delivered and cancelled repairs are excluded from ready results.
  - Ready results order by oldest `readyAt`, then ID.
  - Missing `readyAt` ready rows are included and sorted first.
  - Limit and offset work for ready queries.
  - Invalid pagination fails clearly.
  - Empty ready and delayed queries return empty lists.
  - Ready-too-long uses strict `readyAt < cutoff`.
  - Repairs exactly at the ready cutoff are excluded.
  - Newer ready repairs and non-ready repairs are excluded from ready-too-long results.
  - All active statuses can qualify as delayed active.
  - Delivered and cancelled repairs never qualify as delayed active.
  - Delayed active uses strict `receivedAt < cutoff`.
  - Delayed active results order by oldest `receivedAt`, then ID.
  - Delayed active pagination works.
  - Attention counts cover zero results, waiting approval, ready-too-long, and delayed-active counts.
  - Status workflow integration confirms `repairing -> readyForPickup` appears in ready results.
  - Status workflow integration confirms `readyForPickup -> delivered` removes the repair from ready and delayed-active results.
  - Warranty return integration confirms warranty returns behave like normal repairs in delayed and ready queries.

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

Static analysis: succeeded. `flutter analyze` reported no issues.

Tests: succeeded. `flutter test` passed all tests.

Windows build: attempted but not executed successfully because the current host is not Windows. Flutter returned: `"build windows" only supported on Windows hosts.`

## Issues or Limitations

- Windows build validation remains blocked by the current non-Windows environment.
- Ready-for-pickup rows with missing `readyAt` are intentionally included and sorted first because they represent inconsistent data needing attention.
- No UI, Dashboard state, cards, notifications, background jobs, timers, scheduled tasks, automatic status changes, printing, QR generation, backup/restore, online tracking, deletion, customer management, inventory, suppliers, employees, authentication, licensing, reports, analytics, or sample data were implemented.
- No delayed thresholds are hard-coded; callers must provide explicit cutoff values.
- No indexes were added; schema remains version `4`.

## Next Safe Step

The next safe development step is ticket and print data foundation.
