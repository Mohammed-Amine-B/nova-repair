# Prompt 004 — Repair Creation Workflow

## Summary

Implemented repair code sequence persistence, safe visible repair code generation, and the first real repair creation workflow. The database schema is now version 4 with a singleton `repair_code_sequence` table. New repairs are created from `CreateRepairInput`, automatically receive a visible code from current shop settings, and are inserted atomically with sequence advancement in one Drift transaction.

No repair UI, form, list, search, filters, printing, QR generation, backup, online tracking, dashboard statistics, deletion, or sample data were added.

## Previous State Reviewed

Reports `docs/reports/001-project-foundation.md`, `docs/reports/002-repair-domain-database.md`, and `docs/reports/003-shop-settings-foundation.md` were read.

Relevant starting state:

- Flutter desktop foundation and app shell existed.
- Drift schema version was 3.
- `repairs` and `shop_settings` tables existed.
- Repair domain and settings domain existed.
- Shop settings stored the normalized repair code prefix and number width.
- Repair creation still required externally supplied visible repair codes.
- No repair code sequence, generator, or creation workflow existed.

## Files Inspected

- `docs/reports/001-project-foundation.md`
- `docs/reports/002-repair-domain-database.md`
- `docs/reports/003-shop-settings-foundation.md`
- `lib/database/app_database.dart`
- `lib/features/repairs/domain/repositories/repair_repository.dart`
- `lib/features/repairs/data/repositories/drift_repair_repository.dart`
- `lib/features/repairs/data/datasources/repair_local_data_source.dart`
- `lib/features/repairs/repair_providers.dart`
- `lib/features/settings/data/datasources/shop_settings_local_data_source.dart`
- `lib/features/settings/data/repositories/drift_shop_settings_repository.dart`
- `test/features/repairs/data/repair_persistence_test.dart`
- `test/features/repairs/domain/repair_domain_test.dart`
- `test/features/settings/data/shop_settings_persistence_test.dart`
- Existing file list under `lib/`, `test/`, and `docs/`

## Files Created

- `lib/features/repairs/application/create_repair_use_case.dart`
- `lib/features/repairs/data/datasources/repair_code_sequence_local_data_source.dart`
- `lib/features/repairs/data/tables/repair_code_sequence_table.dart`
- `lib/features/repairs/domain/entities/create_repair_input.dart`
- `lib/features/repairs/domain/services/repair_code_generator.dart`
- `test/features/repairs/data/repair_creation_workflow_test.dart`
- `docs/reports/004-repair-creation-workflow.md`

## Files Modified

- `lib/database/app_database.dart`
- `lib/database/app_database.g.dart`
- `lib/features/repairs/data/mappers/repair_mapper.dart`
- `lib/features/repairs/data/repositories/drift_repair_repository.dart`
- `lib/features/repairs/domain/repositories/repair_repository.dart`
- `lib/features/repairs/repair_providers.dart`
- `lib/features/settings/data/datasources/shop_settings_local_data_source.dart`
- `test/database/app_database_test.dart`
- `test/features/repairs/data/repair_persistence_test.dart`
- `test/features/repairs/domain/repair_domain_test.dart`
- `test/features/settings/data/shop_settings_persistence_test.dart`

## Repair Sequence Design

Sequence structure:

- Table: `repair_code_sequence`
- Singleton row ID: `1`
- Stored value: `last_used_sequence`

Singleton strategy:

- `id` is the primary key.
- A table-level `CHECK(id = 1)` prevents additional logical sequence rows.
- The sequence local data source always writes row ID `1`.

Initial value:

- Fresh databases behave as though `lastUsedSequence = 0`.
- The first created repair advances to sequence `1`.

How sequence advances:

- Repair creation reads the singleton sequence row.
- If it exists, `last_used_sequence + 1` is the starting next sequence.
- If it does not exist, the repository computes a safe baseline from compatible existing repair codes, then advances from there.
- The updated `last_used_sequence` is persisted before repair insertion, inside the same transaction.

Persistence behavior:

- Successfully created repairs permanently consume their sequence number.
- Later cancellation or status changes do not reuse numbers.

Prefix-change behavior:

- The sequence is global, not per-prefix.
- If the shop changes `REP` to `FIX` after `REP-0002`, the next generated code can be `FIX-0003`.

Width-change behavior:

- Width is read from current shop settings at creation time.
- Existing codes are not rewritten.
- Width changes do not reset the sequence.

Overflow behavior:

- Width is minimum padding, not a maximum length.
- With width `4` and sequence `10000`, the generated code is `REP-10000`.

## Existing Repair Migration Behavior

The version 3 to version 4 migration creates the `repair_code_sequence` table but does not insert a sequence row.

The first creation after migration initializes the sequence lazily and safely:

- Existing `repairs.repair_code` values are scanned.
- Codes with a final hyphen followed by digits are considered compatible generated codes.
- The numeric suffix after the final hyphen is parsed.
- The maximum parsed suffix becomes the baseline.
- Example: existing `REP-0001`, `REP-0002`, and `REP-0007` make the next generated sequence `8`.

Arbitrary manually supplied codes that do not match the simple trailing-number pattern are ignored by baseline parsing. The creation workflow still checks for generated-code collisions and advances again if the formatted code already exists.

## Repair Code Generation

Formatting rule:

```text
<PREFIX>-<ZERO_PADDED_SEQUENCE>
```

Examples:

- prefix `REP`, width `4`, sequence `1` -> `REP-0001`
- prefix `FIX`, width `5`, sequence `42` -> `FIX-00042`
- prefix `PC`, width `3`, sequence `123` -> `PC-123`
- prefix `REP`, width `4`, sequence `10000` -> `REP-10000`

Settings dependency:

- Prefix comes from persisted `ShopSettings.repairCodePrefix`.
- Number width comes from persisted `ShopSettings.repairCodeNumberWidth`.
- Defaults naturally produce `REP-0001`.

Uniqueness protection:

- `repairs.repair_code` remains unique.
- The transaction checks whether the generated code already exists.
- If a collision is found, the sequence advances until an unused generated code is found.
- SQLite uniqueness remains the final database protection.

Normalization:

- Prefix normalization is owned by `ShopSettings`.
- `CreateRepairInput` trims text fields before the repair entity is built.

## Creation Input

New input type: `CreateRepairInput`

Fields accepted:

- `customerName`: optional
- `customerPhone`: optional
- `deviceType`: optional
- `brand`: optional
- `model`: optional
- `reportedProblem`: required
- `receivedAccessories`: optional
- `deviceAccessInfo`: optional
- `priceAmount`: optional integer DZD amount
- `internalNotes`: optional
- `customerMessage`: optional
- `parentRepairId`: optional warranty parent reference
- `receivedAt`: optional

Defaults:

- `status = RepairStatus.received`
- `customerPriceDecision = CustomerPriceDecision.notRequested`
- `createdAt = current UTC time`
- `updatedAt = current UTC time`
- `receivedAt = supplied value converted to UTC, or current UTC time if omitted`

Callers cannot provide:

- internal database ID
- visible repair code
- `createdAt`
- `updatedAt`

Validation:

- Reported problem cannot be blank.
- Price cannot be negative.
- Optional text fields are trimmed and blank values become null.
- Parent repair ID must refer to an existing repair when provided.

## Creation Workflow

The creation workflow is:

1. Start a Drift database transaction.
2. Load persisted shop settings, lazily creating defaults if needed.
3. Read the singleton repair sequence row.
4. If no sequence row exists, compute the baseline from compatible existing repair codes.
5. Advance and persist the next sequence number.
6. Generate a visible repair code from current settings and sequence.
7. If the generated code already exists, advance sequence and try again.
8. Validate parent repair existence when `parentRepairId` is provided.
9. Build a validated `Repair` domain entity.
10. Insert the repair row.
11. Reload and return the created domain `Repair`.
12. Commit the transaction.

## Transaction Design

Transaction ownership lives in `DriftRepairRepository.createRepair`.

Atomic operations:

- settings read/default creation
- sequence initialization
- sequence advancement
- repair code generation collision checks
- parent repair existence validation
- repair insertion
- created repair reload

Rollback behavior:

- If any step throws, the Drift transaction rolls back.
- If insertion or validation fails after sequence advancement, the sequence update rolls back too.
- A test confirms a failed parent repair creation leaves no repair row and the next valid repair still receives `REP-0001`.

Sequence rollback behavior:

- Failed creation does not permanently consume a sequence number.
- Successful creation permanently consumes its sequence number.

## Architecture Changes

New use case/application service:

- `CreateRepairUseCase` delegates the first real repair creation operation to the repair repository.

Repository changes:

- `RepairRepository.createRepair` now accepts `CreateRepairInput` and returns the created `Repair`.
- The public repository no longer exposes a method that accepts a fully formed `Repair` with an arbitrary visible code.
- Low-level `RepairLocalDataSource.insertRepair(Repair)` remains internal to persistence tests and repository implementation.

Data source changes:

- Added `RepairCodeSequenceLocalDataSource` for raw sequence row operations.
- Reused `RepairLocalDataSource` for repair insertion and lookup.
- Reused `ShopSettingsLocalDataSource` for settings access within the creation transaction.
- Added `upsertSettings` to the settings data source so defaults can be created inside the repair transaction without opening a separate top-level transaction.

Riverpod providers added or changed:

- Added `repairCodeSequenceLocalDataSourceProvider`.
- Added `createRepairUseCaseProvider`.
- Updated `repairRepositoryProvider` to inject the database, repair local data source, sequence data source, and shop settings local data source.

Intentionally deferred presentation layers:

- No repair creation controller.
- No form state.
- No repair creation UI.
- No repair list UI.

## Database Schema

New table: `repair_code_sequence`

Columns:

- `id`: integer, non-null, auto-increment primary key, table-level `CHECK(id = 1)`.
- `last_used_sequence`: integer, non-null, `CHECK(last_used_sequence >= 0)`.

No daily, yearly, monthly, per-prefix, per-device, per-user, or multi-shop sequence tables were added.

## Schema Migration

Previous schema version: `3`

New schema version: `4`

Version 3 to version 4 upgrade behavior:

- Creates `repair_code_sequence`.
- Does not modify `repairs`.
- Does not modify `shop_settings`.
- Does not rewrite existing visible repair codes.
- Does not insert fake repair rows.
- Does not delete or drop data.

Preservation:

- Migration tests confirm existing repairs survive.
- Migration tests confirm existing shop settings survive.

Sequence initialization:

- No sequence row is inserted during migration.
- The first repair creation after migration initializes from compatible existing repair code suffixes.

## Dependencies

None.

No dependencies were added, removed, or changed during this prompt.

## Tests Added

- `test/features/repairs/data/repair_creation_workflow_test.dart`
  - Fresh sequence creates `REP-0001` then `REP-0002`.
  - Generated codes use current settings.
  - Default status is `received`.
  - Default customer price decision is `notRequested`.
  - Timestamps are deterministic UTC values.
  - Optional fields persist after trimming.
  - Prefix changes do not reset sequence.
  - Number width changes do not reset sequence.
  - Width is minimum padding and does not truncate.
  - Sequence persists across database reopen.
  - Failed creation rolls back sequence advancement and repair insertion.
  - Existing generated-code conflicts are skipped safely.
  - Version 3 databases upgrade to version 4.
  - Existing repairs and shop settings survive migration.
  - Future generated codes do not collide with compatible existing repairs.

- `test/features/repairs/domain/repair_domain_test.dart`
  - Added `CreateRepairInput` validation and normalization coverage.
  - Added `RepairCodeGenerator` formatting and overflow coverage.

Existing tests updated:

- `test/database/app_database_test.dart` expects schema version 4.
- `test/features/repairs/data/repair_persistence_test.dart` uses the safe creation API.
- `test/features/settings/data/shop_settings_persistence_test.dart` expects final schema version 4 after migration.

## Validation Commands

- `dart run build_runner build`
- `dart format .`
- `flutter analyze`
- `flutter test`
- `flutter pub get`
- `flutter build windows`

## Validation Results

Dependency resolution: succeeded. `flutter pub get` completed successfully. Flutter reported that 12 packages have newer versions incompatible with current constraints.

Code generation: succeeded. `dart run build_runner build` completed successfully and regenerated Drift output for schema version 4.

Formatting: succeeded. `dart format .` completed successfully.

Static analysis: initially reported a missing test import for Drift `Value` and one unused import after test cleanup. After fixes, `flutter analyze` reported no issues.

Tests: succeeded. `flutter test` passed all tests.

Windows build: attempted but not executed successfully because the current host is not Windows. Flutter returned: `"build windows" only supported on Windows hosts.`

## Issues or Limitations

- Windows build validation remains blocked by the current non-Windows environment.
- Intermediate analyzer issues occurred during implementation and were resolved before the final validation pass.
- No repair creation UI or presentation state was implemented.
- No repair list UI, search, filters, printing, QR generation, online tracking, backup/restore, dashboard statistics, deletion, cancellation workflow, customer accounts, inventory, suppliers, employees, authentication, licensing, reports, analytics, or sample data were implemented.
- The sequence is one global local-installation sequence only. Per-prefix, daily, monthly, yearly, per-device, and per-user numbering are intentionally not supported.
- Existing-code baseline parsing is intentionally simple: it only parses numeric suffixes after the final hyphen.

## Next Safe Step

The next safe development step is repair creation presentation state and the first real repair creation form UI.
