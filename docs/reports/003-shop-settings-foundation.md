# Prompt 003 — Shop Settings Foundation

## Summary

Implemented the shop settings domain and local persistence foundation. The app now has a validated singleton `ShopSettings` domain entity, a Drift `shop_settings` table, schema version 3 migration from version 2, lazy default settings creation, explicit Drift-row-to-domain mapping, a small local data source, a focused repository, Riverpod providers, and tests for domain validation, persistence, singleton behavior, defaults, and migration.

No Settings UI, repair creation, repair code generation, repair counters, printing, QR generation, online tracking, or sample shop branding were added.

## Previous State Reviewed

Reports `docs/reports/001-project-foundation.md` and `docs/reports/002-repair-domain-database.md` were read.

Relevant starting state:

- Flutter desktop foundation and `NavigationRail` shell existed.
- Riverpod was available at the application root.
- Dashboard, Repairs, and Settings pages were placeholders.
- Drift database schema version was 2.
- The `repairs` table, repair domain, repair repository foundation, and repair persistence tests existed.
- There was no shop settings persistence, repair code generator, repair creation workflow, or Settings UI.

## Files Inspected

- `docs/reports/001-project-foundation.md`
- `docs/reports/002-repair-domain-database.md`
- `pubspec.yaml`
- `analysis_options.yaml`
- `lib/database/app_database.dart`
- `lib/database/database_provider.dart`
- `lib/database/app_database.g.dart`
- `lib/features/settings/settings_page.dart`
- `lib/features/repairs/data/tables/repairs_table.dart`
- `test/database/app_database_test.dart`
- `test/features/repairs/data/repair_persistence_test.dart`
- Existing file list under `lib/`, `test/`, and `docs/`

## Files Created

- `lib/features/settings/domain/entities/shop_settings.dart`
- `lib/features/settings/domain/repositories/shop_settings_repository.dart`
- `lib/features/settings/data/tables/shop_settings_table.dart`
- `lib/features/settings/data/mappers/shop_settings_mapper.dart`
- `lib/features/settings/data/datasources/shop_settings_local_data_source.dart`
- `lib/features/settings/data/repositories/drift_shop_settings_repository.dart`
- `lib/features/settings/settings_providers.dart`
- `test/features/settings/domain/shop_settings_domain_test.dart`
- `test/features/settings/data/shop_settings_persistence_test.dart`
- `docs/reports/003-shop-settings-foundation.md`

## Files Modified

- `lib/database/app_database.dart`
- `lib/database/app_database.g.dart`
- `test/database/app_database_test.dart`
- `test/features/repairs/data/repair_persistence_test.dart`

## Domain Model

The shop settings entity is `ShopSettings` in `lib/features/settings/domain/entities/shop_settings.dart`. It represents the one local shop profile for this desktop installation.

Required fields:

- `shopName`
- `repairCodePrefix`
- `repairCodeNumberWidth`
- `createdAt`
- `updatedAt`

Optional fields:

- `phoneNumber`
- `address`
- `logoPath`
- `ticketFooter`
- `warrantyTerms`

Validation rules:

- `shopName` is trimmed and cannot be blank.
- `repairCodePrefix` is trimmed, uppercased, and cannot be blank.
- `repairCodePrefix` must contain only Latin letters and digits.
- `repairCodePrefix` length must be 2 to 10 characters.
- `repairCodeNumberWidth` must be between 3 and 8.
- Optional text fields are trimmed and stored as null when blank.

Prefix normalization:

- Prefix values are normalized in the domain constructor.
- Example: ` fix42 ` becomes `FIX42`.

Number width rules:

- Default width is `4`.
- Minimum width is `3`.
- Maximum width is `8`.

Timestamp strategy:

- The repository and local data source use UTC timestamps.
- Values are converted to UTC before persistence.
- The mapper converts read timestamps back to UTC because Drift may return local `DateTime` instances for stored instants.

## Singleton Settings Strategy

The `shop_settings` table uses a fixed singleton row ID.

- The only valid settings row ID is `1`.
- The table has an auto-increment primary key plus a table-level `CHECK(id = 1)` constraint.
- The local data source always writes with ID `1`.
- `saveSettings()` uses `insertOnConflictUpdate`, so saving updates the singleton row instead of creating duplicates.
- The repository API exposes only `getSettings()` and `saveSettings(...)`; it does not expose list, delete, or multi-shop operations.

## Default Settings Strategy

Defaults are created lazily when settings are first requested.

This was chosen because it keeps schema migration focused on structure, avoids inserting fake shop data during database upgrades, and is easy to test through the repository.

Default values:

- `shopName`: `My Repair Shop`
- `repairCodePrefix`: `REP`
- `repairCodeNumberWidth`: `4`
- `phoneNumber`: null
- `address`: null
- `logoPath`: null
- `ticketFooter`: null
- `warrantyTerms`: null
- `createdAt`: current UTC time from the repository clock
- `updatedAt`: same as `createdAt`

## Database Schema

Table name: `shop_settings`

Columns:

- `id`: integer, non-null, auto-increment primary key, table-level `CHECK(id = 1)` singleton constraint.
- `shop_name`: text, non-null, `CHECK(length(trim(shop_name)) > 0)`.
- `phone_number`: text, nullable.
- `address`: text, nullable.
- `logo_path`: text, nullable. Stores only a local path string.
- `repair_code_prefix`: text, non-null, `CHECK(length(repair_code_prefix) BETWEEN 2 AND 10)`.
- `repair_code_number_width`: integer, non-null, `CHECK(repair_code_number_width BETWEEN 3 AND 8)`.
- `ticket_footer`: text, nullable.
- `warranty_terms`: text, nullable.
- `created_at`: datetime, non-null.
- `updated_at`: datetime, non-null.

No repair counters, repair sequence tables, customers, employees, licenses, cloud settings, online tracking configuration, printer configuration, inventory, suppliers, payments, or invoices were added.

## Schema Migration

Previous version: `2`

New version: `3`

Upgrade behavior:

- New databases create both current tables through Drift `createAll()`.
- Existing version 2 databases run `onUpgrade`.
- If `from < 3`, the migration explicitly creates `shop_settings`.
- Existing repairs are not modified, dropped, or regenerated.
- Defaults are not inserted by the migration; they are lazily created by `getSettings()`.
- No destructive migration or database deletion is used.

Migration tests performed:

- Created a controlled schema version 2 SQLite database with a `repairs` table and one repair row.
- Opened it with schema version 3 `AppDatabase`.
- Confirmed `shop_settings` exists.
- Confirmed the existing repair row remains.
- Called the settings repository and confirmed default settings become available.
- Confirmed SQLite `user_version` becomes `3`.

## Architecture Changes

Settings domain pieces added:

- `ShopSettings` entity.
- `ShopSettingsRepository` interface.

Data pieces added:

- `ShopSettingsTable` Drift table.
- `ShopSettingsRowMapper` for explicit Drift-row-to-domain mapping.
- `ShopSettingsLocalDataSource` for raw Drift operations.
- `DriftShopSettingsRepository` for default creation, saving, timestamp handling, and domain-returning API.

Riverpod providers added:

- `shopSettingsLocalDataSourceProvider`
- `shopSettingsRepositoryProvider`

Intentionally deferred layers:

- No Settings UI.
- No Settings form controller or notifier.
- No logo picker provider.
- No printer provider.
- No use cases.
- No repair code sequence service.
- No repair creation workflow.

## Repair Code Configuration Decision

The settings foundation now stores:

- normalized repair code prefix, default `REP`
- repair code number width, default `4`

This supports future visible repair codes such as `REP-0001`, `FIX-0001`, or `PC-00042`.

Sequence generation remains deferred. No repair counters or sequence tables were added, and existing `repairs.repair_code` uniqueness was not changed.

## Dependencies

None.

No dependencies were added, removed, or changed during this prompt.

## Tests Added

- `test/features/settings/domain/shop_settings_domain_test.dart`
  - Valid settings creation.
  - Blank shop name rejection.
  - Blank repair prefix rejection.
  - Invalid prefix character rejection.
  - Prefix normalization to uppercase.
  - Minimum number width enforcement.
  - Maximum number width enforcement.

- `test/features/settings/data/shop_settings_persistence_test.dart`
  - Default settings are available on a fresh database.
  - Default prefix is `REP`.
  - Default number width is `4`.
  - Optional fields persist as null.
  - Settings can be updated.
  - Saving does not create duplicate rows.
  - Prefix normalization persists.
  - Timestamps persist consistently as UTC domain values.
  - Singleton row constraint rejects a second row.
  - Controlled version 2 database upgrades to version 3.
  - Existing repair data survives upgrade.
  - Settings become available after upgrade.
  - Schema user version becomes `3`.

Existing database and repair persistence tests were updated to expect schema version 3.

## Validation Commands

- `dart run build_runner build`
- `dart format .`
- `flutter analyze`
- `flutter test`
- `flutter pub get`
- `flutter build windows`

## Validation Results

Dependency resolution: succeeded. `flutter pub get` completed successfully. Flutter reported that 12 packages have newer versions incompatible with current constraints.

Code generation: succeeded. `dart run build_runner build` completed successfully and regenerated Drift output for schema version 3.

Formatting: succeeded. `dart format .` completed successfully.

Static analysis: initially failed while the Drift table used the wrong table-name override and a column-level singleton primary-key constraint. After switching to `tableName` and a table-level singleton `CHECK`, `flutter analyze` reported no issues.

Tests: initially failed for the same Drift table primary-key issue, then later caught local-time `DateTime` reads from Drift. After normalizing settings mapper timestamps to UTC, `flutter test` passed all tests.

Windows build: attempted but not executed successfully because the current host is not Windows. Flutter returned: `"build windows" only supported on Windows hosts.`

## Issues or Limitations

- Windows build validation remains blocked by the current non-Windows environment.
- Intermediate analyzer and test failures occurred during implementation and were resolved before the final validation pass.
- Defaults are lazily created by repository access rather than inserted during migration.
- No Settings UI was implemented.
- No repair code sequence generation was implemented.
- No repair creation workflow was implemented.
- No printing, QR generation, online tracking, backup/restore, customer accounts, inventory, suppliers, employees, authentication, licensing, reports, analytics, or sample data were implemented.
- Logo support is only a nullable local path string; no file access, copying, upload, or image processing was added.

## Next Safe Step

The next safe development step is repair code sequence foundation, safe repair code generation, and the first real repair creation workflow.
