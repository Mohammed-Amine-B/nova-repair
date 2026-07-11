# Prompt 002 — Repair Domain and Database

## Summary

Implemented the repair domain and local persistence foundation. The app now has a validated repair entity, stable repair status and customer price decision domain enums, a Drift `repairs` table, schema version 2 migration from the empty version 1 database, explicit Drift-row-to-domain mapping, a small local data source, a focused repository, Riverpod providers for the repository path, and meaningful domain/database/repository tests.

No repair UI, forms, lists, search, filters, printing, QR generation, online tracking, shop settings, backup, or sample business data were added.

## Previous State Reviewed

The previous report `docs/reports/001-project-foundation.md` was read. The relevant starting state was:

- Flutter desktop foundation existed.
- Riverpod was installed and used at the application root.
- The app shell used a desktop `NavigationRail`.
- Dashboard, Repairs, and Settings were placeholder pages only.
- Drift SQLite infrastructure existed with schema version 1.
- There were no business tables, no repair CRUD, and no online functionality.

## Files Inspected

- `docs/reports/001-project-foundation.md`
- `pubspec.yaml`
- `analysis_options.yaml`
- `lib/database/app_database.dart`
- `lib/database/database_provider.dart`
- `lib/database/app_database.g.dart`
- `lib/features/repairs/repairs_page.dart`
- `test/database/app_database_test.dart`
- `test/app_shell_test.dart`
- Existing file list under `lib/`, `test/`, and `docs/`

## Files Created

- `lib/features/repairs/domain/repair_status.dart`
- `lib/features/repairs/domain/customer_price_decision.dart`
- `lib/features/repairs/domain/entities/repair.dart`
- `lib/features/repairs/domain/repositories/repair_repository.dart`
- `lib/features/repairs/data/tables/repairs_table.dart`
- `lib/features/repairs/data/mappers/repair_mapper.dart`
- `lib/features/repairs/data/datasources/repair_local_data_source.dart`
- `lib/features/repairs/data/repositories/drift_repair_repository.dart`
- `lib/features/repairs/repair_providers.dart`
- `test/features/repairs/domain/repair_domain_test.dart`
- `test/features/repairs/data/repair_persistence_test.dart`
- `docs/reports/002-repair-domain-database.md`

## Files Modified

- `lib/database/app_database.dart`
- `lib/database/app_database.g.dart`
- `test/database/app_database_test.dart`
- `pubspec.yaml`
- `pubspec.lock`

## Domain Model

The repair entity is `Repair` in `lib/features/repairs/domain/entities/repair.dart`. It represents one repair job and keeps the internal database ID separate from the visible repair code.

Required fields:

- `repairCode`
- `reportedProblem`
- `createdAt`
- `updatedAt`
- `receivedAt`

Optional fields:

- `id`
- `customerName`
- `customerPhone`
- `deviceType`
- `brand`
- `model`
- `receivedAccessories`
- `deviceAccessInfo`
- `priceAmount`
- `internalNotes`
- `customerMessage`
- `parentRepairId`
- `readyAt`
- `deliveredAt`

Repair statuses:

- `received` stored as `received`
- `diagnosing` stored as `diagnosing`
- `waitingForCustomerApproval` stored as `waiting_for_customer_approval`
- `waitingForPart` stored as `waiting_for_part`
- `repairing` stored as `repairing`
- `readyForPickup` stored as `ready_for_pickup`
- `delivered` stored as `delivered`
- `cancelled` stored as `cancelled`

Customer price decision states:

- `notRequested` stored as `not_requested`
- `pending` stored as `pending`
- `approved` stored as `approved`
- `rejected` stored as `rejected`

Validation rules:

- Repair code cannot be blank.
- Reported problem cannot be blank.
- Price cannot be negative when provided.
- A repair with an ID cannot reference itself as `parentRepairId`.
- Invalid stored repair status values throw `FormatException`.
- Invalid stored customer price decision values throw `FormatException`.

Warranty relationship:

- Normal repairs have `parentRepairId == null`.
- Warranty-return repairs may reference one earlier repair through `parentRepairId`.
- SQLite foreign keys are enabled for app database connections, and the table has a self-reference to preserve the relationship.

Timestamp strategy:

- The domain uses `DateTime`.
- The local data source converts timestamps to UTC before insertion.
- UTC storage was chosen to remain predictable across restarts and to leave room for future online synchronization without changing stored meaning.
- `readyAt` and `deliveredAt` are nullable because not every repair reaches those lifecycle points.

`deviceAccessInfo` is documented in code as internal-only. It is persisted for local repair-shop use but is not exposed through UI, printing, or online tracking in this prompt.

## Database Schema

Table name: `repairs`

Columns:

- `id`: integer, non-null, auto-increment primary key.
- `repair_code`: text, non-null, unique. Stores the visible repair code such as `REP-0001`.
- `customer_name`: text, nullable.
- `customer_phone`: text, nullable.
- `device_type`: text, nullable.
- `brand`: text, nullable.
- `model`: text, nullable.
- `reported_problem`: text, non-null.
- `received_accessories`: text, nullable.
- `device_access_info`: text, nullable. Internal-only access details.
- `status`: text, non-null. Stores explicit stable repair status values.
- `price_amount`: integer, nullable, with `CHECK(price_amount >= 0)` when present. Stores DZD amounts with no decimals.
- `customer_price_decision`: text, non-null, default `not_requested`. Stores explicit stable customer price decision values.
- `internal_notes`: text, nullable.
- `customer_message`: text, nullable.
- `parent_repair_id`: integer, nullable, self-references `repairs(id)` with `ON UPDATE RESTRICT ON DELETE RESTRICT`.
- `created_at`: datetime, non-null.
- `updated_at`: datetime, non-null.
- `received_at`: datetime, non-null.
- `ready_at`: datetime, nullable.
- `delivered_at`: datetime, nullable.

No customers, employees, inventory, suppliers, payments, invoices, activity logs, online tracking, QR token, or shop settings tables were added.

## Schema Migration

Previous schema version: `1`

New schema version: `2`

Upgrade behavior:

- New databases use Drift `onCreate` with `createAll()` and create the current `repairs` table.
- Existing version 1 databases run `onUpgrade`.
- If `from < 2`, the migration explicitly creates the `repairs` table.
- No existing database is deleted.
- No destructive migration shortcut is used.

Migration tests performed:

- Created a controlled SQLite database file with `PRAGMA user_version = 1`.
- Opened it with the current `AppDatabase`.
- Confirmed the `repairs` table exists after upgrade.
- Confirmed `PRAGMA user_version` becomes `2`.

## Architecture Changes

New Repairs feature layers introduced:

- `domain`: repair entity, repair status enum, customer price decision enum, and a focused repository interface.
- `data/tables`: Drift table definition for the real `repairs` table.
- `data/mappers`: explicit mapping from generated `RepairRow` to the domain `Repair`.
- `data/datasources`: small local data source for insert and lookup operations.
- `data/repositories`: Drift-backed repository implementation.

Repository decisions:

- A repository was created because this prompt introduced real persistence behavior.
- The repository currently supports only `createRepair`, `getRepairById`, and `getRepairByCode`.
- No delete, search, filtering, pagination, dashboard counts, status workflow, archive behavior, printing queries, or UI state APIs were added.

Data source decisions:

- A local data source was added because it keeps raw Drift calls separate from repository/domain mapping.
- It remains small and only covers operations needed by the current persistence foundation.

Mapping approach:

- Generated Drift rows are not exposed as the public domain model.
- `RepairRowMapper` converts `RepairRow` to `Repair`.
- The local data source converts domain values into `RepairsCompanion` values during insertion.

Riverpod providers added:

- `repairLocalDataSourceProvider`
- `repairRepositoryProvider`

Layers intentionally not created:

- No use cases.
- No presentation controllers or notifiers.
- No repair list state.
- No repair form state.
- No search or filter state.
- No dashboard repair providers.
- No fake data layers for features that do not exist yet.

## Repair Code Decision

The schema stores visible repair codes in `repair_code` and enforces uniqueness. The domain validates that a repair code cannot be blank.

The final repair code generator was intentionally deferred because shop settings and configurable prefixes do not exist yet. The current design keeps `repair_code` separate from the internal auto-increment `id`, so a future generator can use a configurable prefix without coupling database identity directly to the `REP` prefix.

The expected next step for code generation is to add a minimal repair creation workflow foundation that can create validated repair codes when real creation behavior is introduced.

## Dependencies

Added:

- `sqlite3` as a dev dependency. It is used only by migration tests to create a controlled version 1 SQLite database file before opening it with the current Drift database.

Removed: none.

Changed:

- `pubspec.lock` was updated by dependency resolution.

## Tests Added

- `test/features/repairs/domain/repair_domain_test.dart`
  - Valid repair creation.
  - Blank repair code rejection.
  - Blank reported problem rejection.
  - Negative price rejection.
  - Self-referencing warranty parent rejection.
  - Stable repair status serialization and deserialization.
  - Stable customer price decision serialization and deserialization.
  - Invalid enum database values fail with `FormatException`.

- `test/features/repairs/data/repair_persistence_test.dart`
  - Current-version database creates the `repairs` table.
  - Repository inserts and retrieves repairs by ID and visible code.
  - Nullable fields persist as null.
  - Unique repair code constraint is enforced.
  - Integer DZD price values persist.
  - Warranty parent relationship persists.
  - Missing warranty parent references are rejected by foreign-key enforcement.
  - Invalid stored enum values fail during mapping.
  - Version 1 database upgrades to schema version 2 and creates the `repairs` table.

- `test/database/app_database_test.dart`
  - Updated to expect schema version 2 and SQLite `user_version` 2.

## Validation Commands

- `dart run build_runner build`
- `dart format .`
- `flutter analyze`
- `flutter test`
- `flutter pub add dev:sqlite3`
- `flutter pub get`
- `flutter build windows`

## Validation Results

Dependency resolution: succeeded. `flutter pub add dev:sqlite3` and `flutter pub get` completed successfully. Flutter reported that 12 packages have newer versions incompatible with current constraints.

Code generation: succeeded. `dart run build_runner build` completed successfully and regenerated Drift output for schema version 2.

Formatting: succeeded. `dart format .` completed successfully.

Static analysis: initially failed on a recursive Drift column check and test import ambiguity. After fixes, `flutter analyze` reported no issues.

Tests: initially failed while foreign-key enforcement was not enabled for test database connections. After enabling `PRAGMA foreign_keys = ON`, `flutter test` passed all tests.

Windows build: attempted but not executed successfully because the current host is not Windows. Flutter returned: `"build windows" only supported on Windows hosts.`

## Issues or Limitations

- Windows build validation remains blocked by the current non-Windows environment.
- Intermediate analyzer and test failures occurred during implementation and were resolved before the final validation pass.
- Repair code generation is deferred.
- No repair creation UI, repair list UI, search, filters, printing, QR code generation, backup/restore, online tracking, shop settings, customer accounts, inventory, suppliers, employees, authentication, licensing, reports, analytics, or sample business data were implemented.
- Status workflow rules were not implemented; statuses are represented and persisted only.
- Customer price approval workflow was not implemented; decision states are represented and persisted only.
- Device access information is stored as plain optional text for local internal use only. Encryption and exposure rules can be reconsidered later if required.

## Next Safe Step

The next safe development step is the first real repair creation workflow foundation.
