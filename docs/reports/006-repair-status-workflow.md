# Prompt 006 — Repair Status Workflow

## Summary

Implemented the repair status workflow without changing UI or database schema. The app now has an explicit domain transition policy, focused status update input, domain errors for not-found and invalid transitions, a `ChangeRepairStatusUseCase`, repository support for atomic status changes, lifecycle timestamp updates, optional customer-visible message updates, and tests for policy and persistence behavior.

No UI, dialogs, repair editing, price approval, warranty workflow, deletion, printing, QR generation, online tracking, or presentation state were added.

## Previous State Reviewed

Reports `docs/reports/001-project-foundation.md`, `docs/reports/002-repair-domain-database.md`, `docs/reports/003-shop-settings-foundation.md`, `docs/reports/004-repair-creation-workflow.md`, and `docs/reports/005-repair-query-foundation.md` were read.

Relevant starting state:

- Flutter desktop foundation and app shell existed.
- Drift schema version was 4.
- Repair creation, safe repair code generation, and query foundation existed.
- The `repairs` table already contained `status`, `updated_at`, `ready_at`, `delivered_at`, and `customer_message`.
- There was no status mutation workflow.

## Files Inspected

- `docs/reports/001-project-foundation.md`
- `docs/reports/002-repair-domain-database.md`
- `docs/reports/003-shop-settings-foundation.md`
- `docs/reports/004-repair-creation-workflow.md`
- `docs/reports/005-repair-query-foundation.md`
- `lib/features/repairs/domain/entities/repair.dart`
- `lib/features/repairs/domain/repair_status.dart`
- `lib/features/repairs/domain/repositories/repair_repository.dart`
- `lib/features/repairs/data/datasources/repair_local_data_source.dart`
- `lib/features/repairs/data/repositories/drift_repair_repository.dart`
- `lib/features/repairs/repair_providers.dart`
- `test/features/repairs/data/repair_creation_workflow_test.dart`
- Existing file list under `lib/`, `test/`, and `docs/`

## Files Created

- `lib/features/repairs/domain/entities/change_repair_status_input.dart`
- `lib/features/repairs/domain/errors/repair_status_workflow_exception.dart`
- `lib/features/repairs/domain/services/repair_status_transition_policy.dart`
- `lib/features/repairs/application/change_repair_status_use_case.dart`
- `test/features/repairs/domain/repair_status_transition_policy_test.dart`
- `test/features/repairs/data/repair_status_workflow_test.dart`
- `docs/reports/006-repair-status-workflow.md`

## Files Modified

- `lib/features/repairs/domain/repositories/repair_repository.dart`
- `lib/features/repairs/data/datasources/repair_local_data_source.dart`
- `lib/features/repairs/data/repositories/drift_repair_repository.dart`
- `lib/features/repairs/repair_providers.dart`

## Status Transition Policy

Allowed transitions:

- `received` -> `diagnosing`
- `received` -> `cancelled`
- `diagnosing` -> `waitingForCustomerApproval`
- `diagnosing` -> `waitingForPart`
- `diagnosing` -> `repairing`
- `diagnosing` -> `cancelled`
- `waitingForCustomerApproval` -> `waitingForPart`
- `waitingForCustomerApproval` -> `repairing`
- `waitingForCustomerApproval` -> `cancelled`
- `waitingForPart` -> `repairing`
- `waitingForPart` -> `cancelled`
- `repairing` -> `waitingForPart`
- `repairing` -> `readyForPickup`
- `repairing` -> `cancelled`
- `readyForPickup` -> `delivered`
- `readyForPickup` -> `repairing`

Final states:

- `delivered`
- `cancelled`

Final states have no allowed outgoing transitions.

Same-status behavior:

- Same-status transitions are not allowed.
- Message-only updates are intentionally not part of this workflow.

## Status Update Input

`ChangeRepairStatusInput` accepts:

- `repairId`: required internal repair ID.
- `targetStatus`: required target `RepairStatus`.
- `customerMessage`: optional `OptionalCustomerMessage`, defaulting to unchanged.

Callers cannot provide:

- `updatedAt`
- `readyAt`
- `deliveredAt`
- other editable repair fields

## Status Update Workflow

The workflow is:

1. Start a Drift database transaction.
2. Load the current repair by internal ID.
3. Throw `RepairNotFoundException` if it does not exist.
4. Convert the row to the domain `Repair`.
5. Validate the current status to target status through `RepairStatusTransitionPolicy`.
6. Determine lifecycle timestamp changes.
7. Update only `status`, `updatedAt`, relevant lifecycle timestamps, and optionally `customerMessage`.
8. Reload the updated repair.
9. Return the updated domain `Repair`.
10. Commit the transaction.

No unrestricted partial update API was added.

## Timestamp Behavior

Every successful status change:

- Sets `updatedAt` to current UTC time.

Entering `readyForPickup`:

- Sets `readyAt` to current UTC time.

Leaving `readyForPickup` back to `repairing`:

- Clears `readyAt`.

Entering `delivered`:

- Sets `deliveredAt` to current UTC time.

Other transitions:

- Do not set `deliveredAt`.
- Do not create additional status timestamps.

## Customer Message Behavior

The status workflow uses `OptionalCustomerMessage` to distinguish message behavior:

- Omitted message: preserves the existing `customerMessage`.
- Non-blank replacement: trims and stores the new message.
- Blank replacement: normalizes to null and clears the stored message.

Internal notes are not modified.

## Errors

Repair not found:

- Throws `RepairNotFoundException`.

Invalid transition:

- Throws `InvalidRepairStatusTransitionException`.
- Includes the source and target statuses.

Both error types extend `RepairStatusWorkflowException`.

## Architecture Changes

Domain policy:

- Added `RepairStatusTransitionPolicy`.
- It supports checking transitions, validating transitions, and retrieving allowed next statuses.

Use case:

- Added `ChangeRepairStatusUseCase`.

Repository changes:

- Added `changeStatus(ChangeRepairStatusInput input)` to `RepairRepository`.
- Implemented it in `DriftRepairRepository`.

Persistence changes:

- Added a focused `updateRepairStatus` method to `RepairLocalDataSource`.
- The update uses Drift update operations and does not rebuild the whole repair row manually.

Riverpod providers:

- Added `changeRepairStatusUseCaseProvider`.

Presentation layers intentionally deferred:

- No status dialog controller.
- No repair details controller.
- No repairs list controller.
- No dashboard controller.
- No UI state providers.

## Database Schema

Schema version remains `4`.

No schema change was required because the existing `repairs` table already has:

- `status`
- `updated_at`
- `ready_at`
- `delivered_at`
- `customer_message`

No migration was created.

## Dependencies

None.

No dependencies were added, removed, or changed.

## Tests Added

- `test/features/repairs/domain/repair_status_transition_policy_test.dart`
  - Every allowed transition.
  - Every forbidden transition.
  - Same-status transition rejection.
  - Final-state behavior for `delivered` and `cancelled`.
  - Required examples from the prompt.

- `test/features/repairs/data/repair_status_workflow_test.dart`
  - Existing repair status changes successfully.
  - Missing repair throws `RepairNotFoundException`.
  - Invalid transition throws `InvalidRepairStatusTransitionException`.
  - Invalid transition does not persist status, timestamp, or message changes.
  - `updatedAt` changes and remains UTC.
  - Entering `readyForPickup` sets `readyAt`.
  - Leaving `readyForPickup` for `repairing` clears `readyAt`.
  - Entering `delivered` sets `deliveredAt`.
  - Unrelated fields remain unchanged.
  - Customer message replacement, trimming, clearing, and preservation.
  - Status counts and active counts reflect successful status changes.

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

Static analysis: initially reported const-constructor and local test helper issues. After fixes, `flutter analyze` reported no issues.

Tests: succeeded. `flutter test` passed all tests.

Windows build: attempted but not executed successfully because the current host is not Windows. Flutter returned: `"build windows" only supported on Windows hosts.`

## Issues or Limitations

- Windows build validation remains blocked by the current non-Windows environment.
- Intermediate analyzer issues occurred during implementation and were resolved before the final validation pass.
- No UI, dialog, presentation state, status list state, or details state was implemented.
- No price approval workflow was implemented.
- No warranty return workflow was implemented.
- No general repair editing was implemented.
- No deletion, printing, QR generation, online tracking, backup/restore, customer management, inventory, suppliers, employees, authentication, licensing, reports, analytics, or sample data were implemented.
- Final repairs cannot be reopened in this workflow.

## Next Safe Step

The next safe development step is the customer price approval workflow.
