# Prompt 008 — Warranty Return Workflow

## Summary

Implemented the warranty return workflow without changing UI or database schema. The app can now validate a delivered original repair, create a new repair linked through `parentRepairId`, reuse the normal repair code sequence, preserve the original repair unchanged, and query direct warranty returns for a repair.

No UI, dialogs, general repair editing, warranty expiry logic, search, filters, delayed repair logic, printing, QR generation, backup/restore, online functionality, or sample data were added.

## Previous State Reviewed

Reports `docs/reports/001-project-foundation.md` through `docs/reports/007-customer-price-approval-workflow.md` were read.

Relevant starting state:

- Flutter desktop foundation, Riverpod root, and app shell existed.
- Drift schema version was `4`.
- Repairs already had `parent_repair_id`.
- Safe repair creation, repair code sequence, shop settings, query foundation, status workflow, and customer price workflow existed.
- There was no dedicated warranty return creation workflow.

## Files Inspected

- `docs/reports/001-project-foundation.md`
- `docs/reports/002-repair-domain-database.md`
- `docs/reports/003-shop-settings-foundation.md`
- `docs/reports/004-repair-creation-workflow.md`
- `docs/reports/005-repair-query-foundation.md`
- `docs/reports/006-repair-status-workflow.md`
- `docs/reports/007-customer-price-approval-workflow.md`
- `lib/features/repairs/domain/entities/create_repair_input.dart`
- `lib/features/repairs/domain/entities/repair.dart`
- `lib/features/repairs/domain/repositories/repair_repository.dart`
- `lib/features/repairs/data/datasources/repair_local_data_source.dart`
- `lib/features/repairs/data/repositories/drift_repair_repository.dart`
- `lib/features/repairs/repair_providers.dart`
- `test/features/repairs/data/repair_creation_workflow_test.dart`
- `test/features/repairs/data/repair_persistence_test.dart`
- Existing file list under `lib/`, `test/`, and `docs/`

## Files Created

- `lib/features/repairs/domain/entities/create_warranty_return_input.dart`
- `lib/features/repairs/domain/errors/warranty_return_workflow_exception.dart`
- `lib/features/repairs/application/create_warranty_return_use_case.dart`
- `test/features/repairs/data/warranty_return_workflow_test.dart`
- `docs/reports/008-warranty-return-workflow.md`

## Files Modified

- `lib/features/repairs/domain/entities/create_repair_input.dart`
- `lib/features/repairs/domain/repositories/repair_repository.dart`
- `lib/features/repairs/data/datasources/repair_local_data_source.dart`
- `lib/features/repairs/data/repositories/drift_repair_repository.dart`
- `lib/features/repairs/repair_providers.dart`
- `test/features/repairs/data/repair_creation_workflow_test.dart`
- `test/features/repairs/data/repair_persistence_test.dart`

## Warranty Eligibility Rules

Valid parent status:

- `delivered`

Invalid statuses:

- `received`
- `diagnosing`
- `waitingForCustomerApproval`
- `waitingForPart`
- `repairing`
- `readyForPickup`
- `cancelled`

Warranty-chain prevention:

- A repair with `parentRepairId != null` cannot be used as the parent of another warranty return, even if it has later reached `delivered`.
- This keeps the MVP relationship to one direct level: original repair to warranty return.

## Warranty Return Input

`CreateWarrantyReturnInput` accepts:

- `originalRepairId`
- `reportedProblem`
- `receivedAccessories`
- `deviceAccessInfo`
- `internalNotes`
- `customerMessage`
- `receivedAt`

The reported problem is required and cannot be blank. Optional text fields are trimmed through the existing normal repair creation path.

## Inherited Data

Copied from the original repair:

- `customerName`
- `customerPhone`
- `deviceType`
- `brand`
- `model`

Not copied from the original repair:

- repair code
- status
- price
- customer price decision
- created timestamp
- updated timestamp
- ready timestamp
- delivered timestamp
- original `parentRepairId`
- original reported problem
- original received accessories
- original device access information
- original internal notes
- original customer-visible message

The new warranty return gets a new repair code, `status = received`, `priceAmount = null`, `customerPriceDecision = notRequested`, `parentRepairId = originalRepair.id`, and new timestamps.

## Warranty Creation Workflow

1. Start one Drift database transaction in `DriftRepairRepository.createWarrantyReturn`.
2. Load the original repair by internal ID.
3. Throw `WarrantyParentRepairNotFoundException` if it does not exist.
4. Convert the row to the domain `Repair`.
5. Validate that the original repair status is `delivered`.
6. Validate that the original repair is not already a warranty return.
7. Build normal repair creation data with inherited customer and device fields.
8. Use the shared internal repair creation helper.
9. Load or create shop settings as usual.
10. Advance the normal global repair sequence as usual.
11. Generate the next normal visible repair code.
12. Insert the new repair with `parentRepairId` pointing to the original repair.
13. Reload and return the created domain `Repair`.
14. Commit the transaction.

## Transaction Design

Transaction ownership:

- Normal repair creation owns a transaction through `createRepair`.
- Warranty return creation owns a transaction through `createWarrantyReturn`.
- Both call the shared internal `_createRepair` helper so warranty creation does not open a nested top-level transaction.

Atomic operations:

- parent lookup
- eligibility validation
- warranty-chain validation
- settings lookup/default creation
- sequence advancement
- repair code generation and collision checks
- new repair insertion
- created repair reload

Rollback behavior:

- If validation or insertion fails, the whole transaction rolls back.
- Failed warranty creation creates no repair row.
- Failed warranty creation does not modify the original repair.

Sequence rollback behavior:

- Failed warranty creation does not consume a repair sequence number.
- Successful warranty creation consumes the next normal global sequence number.

## Repair Code Behavior

Warranty returns use the same normal global repair sequence as all repairs.

Examples:

- `REP-0042` original repair can produce a later warranty return like `REP-0087`.
- If normal repairs use `REP-0001` and `REP-0002`, a warranty return created next uses `REP-0003`.

No warranty-specific prefix, suffix, or separate sequence was added.

## Original Repair Integrity

Warranty return creation does not modify the original repair.

Preserved original fields include:

- repair code
- status
- price
- customer price decision
- internal notes
- customer-visible message
- created timestamp
- updated timestamp
- received timestamp
- ready timestamp
- delivered timestamp

Only a new child repair row is inserted.

## Repository API

Added:

- `createWarrantyReturn(CreateWarrantyReturnInput input)`
- `getWarrantyReturnsForRepair(int repairId)`

Changed:

- `CreateRepairInput` no longer accepts `parentRepairId`.
- Normal public repair creation now always creates repairs with `parentRepairId = null`.
- The repository keeps parent assignment internal to the dedicated warranty workflow.

## Warranty Queries

`getWarrantyReturnsForRepair(int repairId)` returns direct child repairs where `parentRepairId = repairId`.

Behavior:

- returns domain `Repair` objects
- returns only direct warranty children
- excludes unrelated repairs
- orders by `receivedAt` descending, then internal ID descending
- returns an empty list when there are no children

No recursive relationship graph or warranty chain query was added.

## Errors

`WarrantyParentRepairNotFoundException`:

- Thrown when the original repair ID does not exist.

`RepairNotEligibleForWarrantyReturnException`:

- Thrown when the original repair exists but its status is not `delivered`.

`WarrantyReturnFromWarrantyReturnNotAllowedException`:

- Thrown when the candidate parent repair already has a `parentRepairId`.

Invalid warranty input:

- Blank reported problem throws `ArgumentError`.

## Architecture Changes

Input type:

- Added `CreateWarrantyReturnInput`.

Use case:

- Added `CreateWarrantyReturnUseCase`.

Repository changes:

- Added `createWarrantyReturn`.
- Added `getWarrantyReturnsForRepair`.
- Refactored repair creation to share an internal `_createRepair` helper between normal and warranty creation.

Persistence changes:

- Added `RepairLocalDataSource.getWarrantyReturnsForRepair`.

Riverpod providers:

- Added `createWarrantyReturnUseCaseProvider`.

Presentation layers intentionally deferred:

- No warranty dialog controller.
- No repair details controller.
- No repair list controller.
- No form state.
- No UI state providers.
- No Stitch UI implementation.

## Database Schema

Schema version remains `4`.

No schema change was required because the existing `repairs.parent_repair_id` column already supports the direct warranty relationship with SQLite referential integrity.

No migration was created, and Drift code generation was not required.

## Dependencies

None.

No dependencies were added, removed, or changed.

## Tests Added

- `test/features/repairs/data/warranty_return_workflow_test.dart`
  - Delivered original repair can create a warranty return.
  - Warranty return gets a new generated repair code.
  - Warranty return stores `parentRepairId = original.id`.
  - Warranty return starts at `received`.
  - Warranty return price is null.
  - Warranty return decision is `notRequested`.
  - Customer and device information are inherited.
  - New reported problem is used.
  - Original repair remains unchanged.
  - Normal repair creation creates `parentRepairId = null`.
  - Invalid parent statuses are rejected.
  - Missing parent fails clearly.
  - Missing parent creates no row and does not consume sequence.
  - Warranty return cannot become parent of another warranty return.
  - Failed chain attempt creates no new repair, does not consume sequence, and does not modify existing repairs.
  - Warranty return uses the next normal global sequence.
  - Warranty return query returns only direct children, newest first.
  - Empty warranty return query returns an empty list.
  - Blank warranty return reported problem is rejected.

Existing tests updated:

- Removed public `parentRepairId` usage from normal repair creation tests.
- Existing creation, query, status, price, settings, and migration tests continue to pass.

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
- No warranty expiry dates were implemented.
- No automatic warranty eligibility calculation was implemented.
- No warranty terms inspection was implemented.
- No warranty chain support was implemented.
- No original repair reopening was implemented.
- No general repair editing, search, filters, delayed repair logic, printing, QR generation, online tracking, backup/restore, deletion, customer management, inventory, suppliers, employees, authentication, licensing, reports, analytics, or sample data were implemented.

## Next Safe Step

The next safe development step is repair search and filter logic.
