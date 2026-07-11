# Prompt 007 — Customer Price Approval Workflow

## Summary

Implemented the customer price proposal and approval workflow without changing UI or database schema. Repairs now support focused operations to propose or update a price, clear a price, and record a customer approval or rejection for the active pending price proposal.

No repair UI, dialogs, general editing, warranty workflow, deletion, printing, QR generation, online tracking, backup, dashboard statistics, search, filters, or sample data were added.

## Previous State Reviewed

Reports `docs/reports/001-project-foundation.md` through `docs/reports/006-repair-status-workflow.md` were read.

Relevant starting state:

- Flutter desktop foundation, Riverpod root, and app shell existed.
- Drift schema version was `4`.
- Repair creation, generated repair codes, repair queries, and repair status workflow existed.
- The `repairs` table already had `price_amount`, `customer_price_decision`, and `updated_at`.
- `CustomerPriceDecision` already existed with stable database values.
- No customer price approval workflow existed.

## Files Inspected

- `docs/reports/001-project-foundation.md`
- `docs/reports/002-repair-domain-database.md`
- `docs/reports/003-shop-settings-foundation.md`
- `docs/reports/004-repair-creation-workflow.md`
- `docs/reports/005-repair-query-foundation.md`
- `docs/reports/006-repair-status-workflow.md`
- `lib/features/repairs/domain/repositories/repair_repository.dart`
- `lib/features/repairs/domain/entities/repair.dart`
- `lib/features/repairs/domain/entities/create_repair_input.dart`
- `lib/features/repairs/domain/entities/change_repair_status_input.dart`
- `lib/features/repairs/domain/customer_price_decision.dart`
- `lib/features/repairs/domain/errors/repair_status_workflow_exception.dart`
- `lib/features/repairs/data/datasources/repair_local_data_source.dart`
- `lib/features/repairs/data/repositories/drift_repair_repository.dart`
- `lib/features/repairs/data/tables/repairs_table.dart`
- `lib/features/repairs/repair_providers.dart`
- `lib/features/repairs/application/create_repair_use_case.dart`
- `lib/features/repairs/application/change_repair_status_use_case.dart`
- `test/features/repairs/data/repair_status_workflow_test.dart`
- `test/features/repairs/data/repair_creation_workflow_test.dart`
- `test/features/repairs/data/repair_persistence_test.dart`
- `test/features/repairs/domain/repair_domain_test.dart`
- Existing file list under `lib/`, `test/`, and `docs/`

## Files Created

- `lib/features/repairs/domain/entities/propose_repair_price_input.dart`
- `lib/features/repairs/domain/entities/clear_repair_price_input.dart`
- `lib/features/repairs/domain/entities/record_customer_price_decision_input.dart`
- `lib/features/repairs/domain/errors/repair_price_workflow_exception.dart`
- `lib/features/repairs/application/propose_repair_price_use_case.dart`
- `lib/features/repairs/application/clear_repair_price_use_case.dart`
- `lib/features/repairs/application/record_customer_price_decision_use_case.dart`
- `test/features/repairs/data/repair_price_workflow_test.dart`
- `docs/reports/007-customer-price-approval-workflow.md`

## Files Modified

- `lib/features/repairs/domain/repositories/repair_repository.dart`
- `lib/features/repairs/data/datasources/repair_local_data_source.dart`
- `lib/features/repairs/data/repositories/drift_repair_repository.dart`
- `lib/features/repairs/repair_providers.dart`

## Price Proposal Rules

Allowed repair statuses:

- `diagnosing`
- `waitingForCustomerApproval`

Forbidden statuses:

- `received`
- `waitingForPart`
- `repairing`
- `readyForPickup`
- `delivered`
- `cancelled`

Price validation:

- Price is an integer DZD amount.
- Negative prices are rejected by `ProposeRepairPriceInput`.
- Floating-point prices are not represented by the API.

Decision reset behavior:

- A valid proposal writes `priceAmount`.
- A valid proposal sets `customerPriceDecision` to `pending`.
- Changing an `approved` or `rejected` price resets the decision to `pending`.

Same-price behavior:

- If the stored price is the same and the current decision is not `pending`, proposing it again is allowed and resets the decision to `pending`.
- If the stored price is the same and the current decision is already `pending`, the operation throws `RepairPriceProposalAlreadyPendingException` as an explicit no-op rejection.

Final-state behavior:

- Delivered and cancelled repairs cannot receive price proposals or price clearing.

## Clear Price Behavior

`clearPrice` is allowed only while the repair status is `diagnosing` or `waitingForCustomerApproval`.

When successful, it:

- sets `priceAmount` to `null`
- sets `customerPriceDecision` to `notRequested`
- updates `updatedAt`
- preserves repair status, customer message, internal notes, lifecycle timestamps, repair code, and other unrelated fields

## Customer Decision Rules

Approval preconditions:

- Repair must exist.
- Repair status must be `waitingForCustomerApproval`.
- `priceAmount` must not be null.
- Current `customerPriceDecision` must be `pending`.
- Target decision must be `approved`.

Rejection preconditions:

- Repair must exist.
- Repair status must be `waitingForCustomerApproval`.
- `priceAmount` must not be null.
- Current `customerPriceDecision` must be `pending`.
- Target decision must be `rejected`.

Allowed target decisions:

- `approved`
- `rejected`

Invalid decision transitions:

- `notRequested` cannot become `approved` or `rejected` through the decision operation.
- `approved` cannot directly become `rejected`.
- `rejected` cannot directly become `approved`.
- Callers cannot set `pending` or `notRequested` through `RecordCustomerPriceDecisionInput`.

## Relationship With Repair Status

The price workflow does not automatically change repair status.

- Proposing a price does not move the repair to `waitingForCustomerApproval`.
- Approving a price does not move the repair to `repairing`.
- Rejecting a price does not move the repair to `cancelled`.

Status changes remain separate and continue through the existing status workflow.

## Workflow Inputs

`ProposeRepairPriceInput` accepts:

- `repairId`
- `priceAmount`

`ClearRepairPriceInput` accepts:

- `repairId`

`RecordCustomerPriceDecisionInput` accepts:

- `repairId`
- `decision`, limited to `approved` or `rejected`

## Timestamp Behavior

Every successful price workflow operation sets `updatedAt` to the repository clock converted to UTC.

The workflow does not modify:

- `createdAt`
- `receivedAt`
- `readyAt`
- `deliveredAt`

## Errors

Repair not found:

- Throws the existing `RepairNotFoundException`.

Invalid price editing status:

- Throws `InvalidRepairPriceWorkflowStateException`.

Missing proposed price:

- Throws `RepairPriceProposalNotPresentException`.

Invalid customer decision transition:

- Throws `InvalidCustomerPriceDecisionTransitionException`.

Same pending price proposal:

- Throws `RepairPriceProposalAlreadyPendingException`.

Invalid input price:

- Negative proposal amounts throw `ArgumentError`.

Invalid target customer decision:

- Attempting to construct a customer decision input with `pending` or `notRequested` throws `ArgumentError`.

## Architecture Changes

Use cases/application services added:

- `ProposeRepairPriceUseCase`
- `ClearRepairPriceUseCase`
- `RecordCustomerPriceDecisionUseCase`

Repository changes:

- Added `proposePrice`.
- Added `clearPrice`.
- Added `recordCustomerPriceDecision`.

Persistence changes:

- Added `RepairLocalDataSource.updateRepairPriceState`.
- `DriftRepairRepository` performs load, validation, focused update, reload, and return inside Drift transactions.
- The update touches only `price_amount`, `customer_price_decision`, and `updated_at`.

Riverpod providers added:

- `proposeRepairPriceUseCaseProvider`
- `clearRepairPriceUseCaseProvider`
- `recordCustomerPriceDecisionUseCaseProvider`

Presentation layers intentionally deferred:

- No price dialog controller.
- No repair details controller.
- No repair form controller.
- No repair list controller.
- No dashboard controller.
- No UI state providers.

## Database Schema

Schema version remains `4`.

No schema change was required because the existing `repairs` table already contains:

- `price_amount`
- `customer_price_decision`
- `updated_at`

No migration was created, and Drift code generation was not required.

## Dependencies

None.

No dependencies were added, removed, or changed.

## Tests Added

- `test/features/repairs/data/repair_price_workflow_test.dart`
  - Valid proposal stores integer DZD price.
  - Valid proposal sets decision to `pending`.
  - `updatedAt` changes and remains UTC.
  - Created, received, ready, and delivered timestamps are preserved.
  - Negative price is rejected.
  - Proposal succeeds in `diagnosing` and `waitingForCustomerApproval`.
  - Proposal fails in forbidden statuses, including final states.
  - Changing approved or rejected prices resets the decision to `pending`.
  - Previous price is replaced.
  - Same-price behavior is explicit.
  - Clearing price resets state to `notRequested`.
  - Clearing price preserves unrelated fields.
  - Pending proposal can be approved.
  - Pending proposal can be rejected.
  - Approval and rejection do not change repair status.
  - Approval or rejection without an active pending proposal fails.
  - Direct approved-to-rejected and rejected-to-approved changes fail.
  - Callers cannot set `pending` or `notRequested` through the customer response input.
  - Decision outside `waitingForCustomerApproval` fails.
  - Invalid operations preserve price, decision, `updatedAt`, and status.
  - Missing repair throws `RepairNotFoundException`.
  - Realistic flow from creation through diagnosis, price proposal, waiting for approval, and approval keeps the generated code and status separate.

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
- The working directory did not appear to be a Git repository when `git status --short` was attempted.
- No UI or presentation state was implemented.
- No automatic status transitions are performed by the price workflow.
- No general repair editing workflow was implemented.
- No warranty return workflow was implemented.
- No deletion, printing, QR generation, online tracking, backup/restore, search, filters, dashboard statistics, customer management, inventory, suppliers, employees, authentication, licensing, reports, analytics, or sample data were implemented.

## Next Safe Step

The next safe development step is the warranty return workflow.
