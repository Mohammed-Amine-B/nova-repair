# Prompt 020 — Repair Update Workflow Foundation

## Summary

Implemented the safe repair-details update workflow foundation required before Edit Repair UI. The repository now exposes a narrow `updateRepairDetails` operation, backed by `UpdateRepairInput`, `UpdateRepairUseCase`, a focused Drift update, Riverpod provider access, and tests proving normal editable fields can be changed while protected workflow fields are preserved.

No Edit Repair UI, new screen, Change Status changes, Print Preview, Warranty Return UI, customer price decision UI, Settings UI, Backup UI, schema changes, or dependency changes were added.

## Previous State Reviewed

Reports `docs/reports/001-project-foundation.md` through `docs/reports/019-change-status-dialog.md` were read.

Relevant starting state:

- Repair creation, status workflow, price workflow, warranty workflow, query logic, Dashboard, Repairs List, New Repair UI, Repair Details UI, and Change Status dialog already existed.
- `RepairRepository` had focused creation, status, price, warranty, and query methods.
- There was no narrow safe workflow for updating normal repair details.
- Price, status, warranty, and lifecycle timestamp changes already had separate workflow ownership.

`design_reference/NOVA_REPAIR_UI_SPEC.md` was inspected to confirm Edit Repair is intended to edit normal repair information while keeping status changes separate.

## Existing Update Capability Review

A safe generic repair-details update workflow did not already exist.

Inspected areas:

- `RepairRepository`: no update method for normal repair details.
- `DriftRepairRepository`: no safe details update operation.
- `RepairLocalDataSource`: update methods existed only for status and price state.
- `Repair` entity: represented all fields but was not appropriate as a generic update input because it includes protected workflow fields.
- `CreateRepairInput`: creation-only and includes creation-specific behavior.
- Status workflow: safely updates status, customer message, and lifecycle timestamps only through `ChangeRepairStatusUseCase`.
- Price workflow: safely updates price and customer price decision through dedicated price operations.

Because no existing workflow fully supported the approved Edit Repair fields safely, a focused update workflow was added.

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
- Attached Prompt 020 request text
- `design_reference/NOVA_REPAIR_UI_SPEC.md`
- `lib/features/repairs/domain/repositories/repair_repository.dart`
- `lib/features/repairs/data/repositories/drift_repair_repository.dart`
- `lib/features/repairs/data/datasources/repair_local_data_source.dart`
- `lib/features/repairs/domain/entities/repair.dart`
- `lib/features/repairs/domain/entities/create_repair_input.dart`
- `lib/features/repairs/domain/entities/change_repair_status_input.dart`
- `lib/features/repairs/domain/errors/repair_status_workflow_exception.dart`
- `lib/features/repairs/repair_providers.dart`
- `test/features/repairs/data/repair_status_workflow_test.dart`
- `test/features/repairs/data/repair_price_workflow_test.dart`
- `test/features/repairs/data/warranty_return_workflow_test.dart`
- Existing repository fake implementations in UI tests

## Files Created

- `lib/features/repairs/domain/entities/update_repair_input.dart`
- `lib/features/repairs/domain/errors/repair_update_workflow_exception.dart`
- `lib/features/repairs/application/update_repair_use_case.dart`
- `test/features/repairs/data/repair_update_workflow_test.dart`
- `docs/reports/020-repair-update-workflow-foundation.md`

## Files Modified

- `lib/features/repairs/domain/repositories/repair_repository.dart`
- `lib/features/repairs/data/datasources/repair_local_data_source.dart`
- `lib/features/repairs/data/repositories/drift_repair_repository.dart`
- `lib/features/repairs/repair_providers.dart`
- `test/features/repairs/change_status_dialog_test.dart`
- `test/features/repairs/repair_details_test.dart`
- `test/features/repairs/new_repair_test.dart`
- `test/features/repairs/repairs_list_test.dart`

## Update Scope

Editable fields:

- `customerName`
- `customerPhone`
- `deviceType`
- `brand`
- `model`
- `reportedProblem`
- `receivedAccessories`
- `deviceAccessInfo`
- `internalNotes`
- `customerMessage`

Protected fields:

- internal database ID
- `repairCode`
- `status`
- `priceAmount`
- `customerPriceDecision`
- `parentRepairId`
- `receivedAt`
- `readyAt`
- `deliveredAt`
- `createdAt`
- caller-supplied `updatedAt`

Only backend-owned `updatedAt` changes automatically.

## UpdateRepairInput

`UpdateRepairInput` accepts:

- `repairId`
- `customerName`
- `customerPhone`
- `deviceType`
- `brand`
- `model`
- `reportedProblem`
- `receivedAccessories`
- `deviceAccessInfo`
- `internalNotes`
- `customerMessage`

It does not accept repair code, status, price, customer price decision, warranty parent ID, lifecycle timestamps, creation timestamp, or caller-supplied update timestamp.

Normalization:

- Required text fields are trimmed.
- Optional text fields are trimmed.
- Blank optional text becomes `null`.

## Validation

Required fields:

- `deviceType`
- `reportedProblem`

Invalid required fields throw `InvalidRepairUpdateInputException`.

Validation rules:

- Blank `deviceType` fails.
- Whitespace-only `deviceType` fails.
- Blank `reportedProblem` fails.
- Whitespace-only `reportedProblem` fails.

No phone formatting or unrelated normalization was added.

## Repository Update

Added narrow repository API:

`Future<Repair> updateRepairDetails(UpdateRepairInput input)`

No generic map-based update was added.

No `updateRepair(Repair repair)` method was added, because that would allow callers to accidentally mutate protected workflow fields.

## Atomicity

`DriftRepairRepository.updateRepairDetails` runs in a transaction:

1. Load the current repair by ID.
2. Throw `RepairNotFoundException` if it does not exist.
3. Update only allowed detail columns and backend-owned `updatedAt`.
4. Reload the updated repair.
5. Return the domain `Repair`.

The data source update writes only permitted columns.

## UpdatedAt

`updatedAt` is backend-owned.

Callers cannot provide it through `UpdateRepairInput`.

On success, the repository uses its clock and stores `updatedAt` as UTC.

The existing repository clock injection style is preserved for deterministic tests.

## Status Preservation

The update workflow does not accept or write status.

Repairs in non-default statuses keep their status unchanged.

Status changes remain owned by `ChangeRepairStatusUseCase`.

## Price Preservation

The generic detail update does not accept or write:

- `priceAmount`
- `customerPriceDecision`

Price remains owned by:

- `ProposeRepairPriceUseCase`
- `ClearRepairPriceUseCase`
- `RecordCustomerPriceDecisionUseCase`

This prevents a future Edit Repair screen from bypassing customer approval semantics.

## Warranty Preservation

The update workflow does not accept or write `parentRepairId`.

Warranty relationships remain owned by the warranty workflow.

Tests confirm warranty returns keep their original parent repair link after normal details are updated.

## Final-Status Edit Policy

Normal repair details remain editable for delivered and cancelled repairs.

Reason:

- The current project has no rule making final repairs immutable.
- The prompt preferred allowing normal information edits for any existing repair unless an existing immutability rule existed.
- The workflow still preserves status, price, warranty links, and lifecycle timestamps.

## Future Edit Repair Price Coordination

Prompt 021 should coordinate Edit Repair save behavior as:

1. Load the fresh repair.
2. Submit normal editable fields through `UpdateRepairUseCase`.
3. Compare original price and edited price.
4. If unchanged, do nothing to price.
5. If changed to an integer amount, call `ProposeRepairPriceUseCase`.
6. If cleared, call `ClearRepairPriceUseCase`.
7. Refresh Repair Details, Repairs List, and Dashboard where relevant.

This coordinator was intentionally not implemented in Prompt 020.

## Architecture Changes

Added:

- focused input model
- focused update workflow exception
- focused use case
- narrow repository method
- focused Drift data-source update
- Riverpod use-case provider

No UI was added.

No Edit Repair controller was added.

No fake layers were added.

No status, price, warranty, printing, QR, backup, or dashboard workflow was changed.

## Database Schema

Schema version remains `4`.

No tables, columns, indexes, migrations, or generated Drift files were changed.

## Dependencies

None.

No dependencies were added, removed, or changed.

## Tests Added

- `test/features/repairs/data/repair_update_workflow_test.dart`
  - Updates all normal editable repair details.
  - Rejects blank and whitespace-only required fields.
  - Trims surrounding whitespace.
  - Converts blank optional fields to null.
  - Preserves repair code, status, customer price decision, price, parent repair ID, receivedAt, readyAt, deliveredAt, and createdAt.
  - Updates only backend-owned `updatedAt`.
  - Preserves non-default status.
  - Preserves price workflow state.
  - Preserves warranty parent relationship.
  - Allows delivered and cancelled repairs to update normal details.
  - Missing repair throws `RepairNotFoundException`.
  - Invalid input leaves persisted repair unchanged.
  - `updateRepairUseCaseProvider` exposes the use case through Riverpod.

Existing test fakes were updated to satisfy the new repository interface.

## Validation Commands

- `dart format .`
- `flutter analyze`
- `flutter test test/features/repairs/data/repair_update_workflow_test.dart`
- `flutter test test/features/repairs/data/repair_price_workflow_test.dart`
- `flutter test test/features/repairs/data/warranty_return_workflow_test.dart`
- `flutter test test/features/repairs/data/repair_status_workflow_test.dart`
- `flutter test test/features/repairs/new_repair_test.dart`
- `flutter pub get`
- `flutter test`
- `flutter build windows`
- `git status --short`

## Validation Results

Dependency resolution: succeeded. `flutter pub get` completed successfully. Flutter reported that 12 packages have newer versions incompatible with current constraints.

Code generation: not run because no Drift schema or generated-code inputs changed.

Formatting: succeeded. `dart format .` completed successfully.

Static analysis: initially failed because the new update exception constructor used an invalid super-parameter form and the update workflow test was missing a `Repair` import. After fixes, `flutter analyze` reported no issues.

Focused update workflow tests: `flutter test test/features/repairs/data/repair_update_workflow_test.dart` passed.

Affected workflow tests:

- `flutter test test/features/repairs/data/repair_price_workflow_test.dart` passed.
- `flutter test test/features/repairs/data/warranty_return_workflow_test.dart` passed.
- `flutter test test/features/repairs/data/repair_status_workflow_test.dart` passed.
- `flutter test test/features/repairs/new_repair_test.dart` passed.

All tests: `flutter test` passed all tests.

Windows build: attempted but not executed successfully because the current host is not Windows. Flutter returned: `"build windows" only supported on Windows hosts.`

Repository status check: `git status --short` failed because the working directory did not appear to be a Git repository.

## Issues or Limitations

- Windows build validation remains blocked by the current non-Windows environment.
- The working directory did not appear to be a Git repository when `git status --short` was attempted.
- No optimistic locking or revision columns were added; this remains a local single-device MVP workflow.
- Edit Repair UI is intentionally deferred.
- Edit Repair price coordination is documented but not implemented.

## Next Safe Step

The next safe step is Edit Repair UI implementation using the approved Stitch reference, shared New Repair form structure, `UpdateRepairUseCase`, and the existing price workflow.
