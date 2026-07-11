# Prompt 025 — Shop Settings Model Extension Foundation

## Summary

Extended the shop settings model and local persistence foundation for the future Settings UI. `ShopSettings` now supports an optional shop subtitle, optional default customer-ticket printer ID, and optional default device-label printer ID. The Drift schema is now version `5` with a safe v4 to v5 migration, backup validation accepts v5 while preserving older supported restores, and customer ticket print data can carry the shop subtitle when present.

No Settings UI, printer dropdowns, printer discovery changes, print execution preference wiring, Backup UI, online behavior, authentication, cloud sync, or sample data were added.

## Previous State Reviewed

Reports `docs/reports/001-project-foundation.md` through `docs/reports/024-unicode-print-font-foundation.md` were read.

Relevant starting state:

- Drift schema version was `4`.
- `shop_settings` already stored shop name, phone, address, logo path, ticket footer, warranty terms, repair code prefix, repair code number width, and timestamps.
- Settings persistence used a singleton `ShopSettings` entity, mapper, local data source, and repository.
- Print Preview and Windows printer integration existed, but printer preferences were not persisted.
- Unicode PDF font support already existed.

## Existing Settings Capability Review

Existing settings fields before this change:

- `shopName`
- `phoneNumber`
- `address`
- `logoPath`
- `repairCodePrefix`
- `repairCodeNumberWidth`
- `ticketFooter`
- `warrantyTerms`
- `createdAt`
- `updatedAt`

No shop subtitle, customer-ticket printer preference, or device-label printer preference was persisted before this prompt.

## Files Inspected

- Prompt 025 attachment text
- `docs/reports/001-project-foundation.md` through `docs/reports/024-unicode-print-font-foundation.md`
- `design_reference/NOVA_REPAIR_UI_SPEC.md`
- `pubspec.yaml`
- `lib/database/app_database.dart`
- `lib/database/app_database.g.dart`
- `lib/features/settings/domain/entities/shop_settings.dart`
- `lib/features/settings/domain/repositories/shop_settings_repository.dart`
- `lib/features/settings/data/tables/shop_settings_table.dart`
- `lib/features/settings/data/mappers/shop_settings_mapper.dart`
- `lib/features/settings/data/datasources/shop_settings_local_data_source.dart`
- `lib/features/settings/data/repositories/drift_shop_settings_repository.dart`
- `lib/features/settings/settings_providers.dart`
- `lib/features/backup/infrastructure/backup_validator.dart`
- `lib/features/printing/domain/entities/customer_ticket_data.dart`
- `lib/features/printing/domain/entities/local_printer.dart`
- `lib/features/printing/application/build_repair_print_data_use_case.dart`
- `lib/features/printing/application/local_printer_service.dart`
- `lib/features/printing/infrastructure/pdf/repair_pdf_document_renderer.dart`
- `lib/features/printing/infrastructure/printers/printing_local_printer_service.dart`
- `lib/features/printing/presentation/print_preview_request.dart`
- `lib/features/printing/presentation/widgets/customer_ticket_preview.dart`
- `lib/features/printing/presentation/widgets/device_label_preview.dart`
- Existing settings, backup, printer integration, print data, repair persistence, and database tests

## Files Created

- `docs/reports/025-shop-settings-model-extension-foundation.md`

## Files Modified

- `lib/database/app_database.dart`
- `lib/database/app_database.g.dart`
- `lib/features/settings/domain/entities/shop_settings.dart`
- `lib/features/settings/data/tables/shop_settings_table.dart`
- `lib/features/settings/data/mappers/shop_settings_mapper.dart`
- `lib/features/settings/data/datasources/shop_settings_local_data_source.dart`
- `lib/features/backup/infrastructure/backup_validator.dart`
- `lib/features/printing/domain/entities/customer_ticket_data.dart`
- `lib/features/printing/application/build_repair_print_data_use_case.dart`
- `lib/features/printing/infrastructure/pdf/repair_pdf_document_renderer.dart`
- `lib/features/printing/presentation/widgets/customer_ticket_preview.dart`
- `test/database/app_database_test.dart`
- `test/features/settings/domain/shop_settings_domain_test.dart`
- `test/features/settings/data/shop_settings_persistence_test.dart`
- `test/features/backup/local_backup_service_test.dart`
- `test/features/repairs/data/repair_persistence_test.dart`
- `test/features/repairs/data/repair_creation_workflow_test.dart`
- `test/features/printing/application/build_repair_print_data_use_case_test.dart`
- `test/features/printing/infrastructure/printer_integration_test.dart`

## Settings Model Extension

Added to `ShopSettings`:

- `String? shopSubtitle`
- `String? defaultCustomerTicketPrinterId`
- `String? defaultDeviceLabelPrinterId`

The entity remains immutable. Existing full-replacement repository semantics were preserved through `ShopSettings.copyWith`.

## System Default Semantics

`null` means system default printer.

No sentinel values such as `Default Printer`, `SYSTEM_DEFAULT`, or an empty string are stored as printer preferences.

## Printer Identifier Decision

Persisted printer values are app-owned printer IDs corresponding to `LocalPrinter.id`.

Printer IDs are:

- trimmed
- blank-to-null
- otherwise preserved exactly, including case and punctuation

Unavailable saved printer IDs are not automatically deleted. Future Settings/printing integration can resolve a stored ID against discovered `LocalPrinter` values and fall back safely when unavailable.

## Normalization

- `shopName`: existing trim and nonblank validation preserved.
- `shopSubtitle`: trimmed; blank becomes `null`.
- `phoneNumber`: existing trim and blank-to-null behavior preserved.
- `address`: existing trim and blank-to-null behavior preserved.
- `ticketFooter`: existing trim and blank-to-null behavior preserved.
- `warrantyTerms`: existing trim and blank-to-null behavior preserved.
- `defaultCustomerTicketPrinterId`: trimmed; blank becomes `null`.
- `defaultDeviceLabelPrinterId`: trimmed; blank becomes `null`.
- `repairCodePrefix` and `repairCodeNumberWidth`: existing validation unchanged.

## Repository / Data Source

The existing settings repository and data source were extended only.

- No new settings repository was created.
- No separate printer settings repository was created.
- `ShopSettingsLocalDataSource` now writes the three new nullable fields.
- `ShopSettingsRowMapper` now maps the three new nullable fields into the domain entity.
- `DriftShopSettingsRepository` continues to own `createdAt` preservation and `updatedAt` refresh on save.

## Schema Migration

Previous schema version: `4`

New schema version: `5`

Added nullable columns to `shop_settings`:

- `shop_subtitle TEXT NULL`
- `default_customer_ticket_printer_id TEXT NULL`
- `default_device_label_printer_id TEXT NULL`

Migration behavior:

- New databases create the current schema through Drift `createAll()`.
- Existing v3/v4 databases add the three nullable columns.
- Older databases that did not yet have `shop_settings` create the current table shape directly and do not run duplicate `ADD COLUMN` operations.

## Migration Safety

Migration tests confirmed:

- v2 databases still upgrade to the current schema.
- v4 databases preserve existing settings.
- v4 databases preserve existing repairs.
- v4 databases preserve `repair_code_sequence`.
- new settings fields are `null` for existing v4 installations.
- `PRAGMA user_version` becomes `5`.

## Print Data Integration

`CustomerTicketData` now includes optional `shopSubtitle`.

`BuildRepairPrintDataUseCase` maps `ShopSettings.shopSubtitle` into customer ticket data. When the subtitle is absent, it remains `null` and no fallback text is invented.

The customer ticket preview and PDF renderer conditionally show the subtitle below the shop name when present.

## Device Label Decision

The device label remains compact and does not use `shopSubtitle`.

It continues to include only the approved compact fields: shop name, repair code, device, customer, phone, and QR.

## Backup / Restore Compatibility

`BackupValidator.supportedSchemaVersions` now accepts schema version `5`.

Backup tests confirm:

- current v5 backups validate and include the new settings columns.
- v2 backups still restore and migrate to schema version `5`.
- v4 backups restore and migrate to schema version `5`.
- restored v4 settings receive `null` for the new fields.

No backup/restore redesign was made.

## Database Schema

Final schema version: `5`.

Only `shop_settings` changed. No new tables, indexes, print jobs, printer cache, printer history, settings audit history, or migrations unrelated to these columns were added.

## Dependencies

None.

No package dependencies were added, removed, or changed.

## Tests Added

Updated settings domain tests cover:

- subtitle trim and blank-to-null behavior
- printer ID trim and blank-to-null behavior
- printer ID case/content preservation
- existing shop name and repair code validation

Updated settings persistence tests cover:

- default new fields are `null`
- subtitle saves and reloads
- both printer IDs save and reload
- blank subtitle/printer IDs persist as `null`
- full settings replacement preserves and clears printer IDs according to existing repository semantics
- `null` represents system default
- v4 to v5 migration preserves settings, repairs, and sequence data

Updated backup tests cover:

- v5 backup metadata and copied settings columns
- v2 restore to v5
- v4 restore to v5

Updated print tests cover:

- customer ticket print data includes persisted subtitle
- default subtitle is absent
- PDF customer ticket can render subtitle
- device label remains compact and excludes subtitle

## Validation Commands

- `dart run build_runner build`
- `dart format .`
- `flutter analyze`
- `flutter test test/features/settings/domain/shop_settings_domain_test.dart`
- `flutter test test/features/settings/data/shop_settings_persistence_test.dart`
- `flutter test test/features/printing/application/build_repair_print_data_use_case_test.dart`
- `flutter test test/features/printing/infrastructure/printer_integration_test.dart`
- `flutter test test/features/backup/local_backup_service_test.dart`
- `flutter test test/database/app_database_test.dart`
- `flutter pub get`
- `dart run build_runner build`
- `dart format .`
- `flutter analyze`
- `flutter test`
- `flutter build windows`
- `git status --short`

## Validation Results

Dependency resolution: succeeded. `flutter pub get` completed successfully. Flutter reported that 17 packages have newer versions incompatible with dependency constraints.

Code generation: succeeded. `dart run build_runner build` regenerated Drift output for schema version `5`.

Formatting: succeeded. `dart format .` completed successfully.

Static analysis: succeeded. `flutter analyze` reported no issues.

Focused tests:

- `test/features/settings/domain/shop_settings_domain_test.dart` passed.
- `test/features/settings/data/shop_settings_persistence_test.dart` initially failed because the first migration guard attempted to add v5 columns after creating the current settings table from a v2 database. After tightening the guard to only alter existing v3/v4 settings tables, it passed.
- `test/features/printing/application/build_repair_print_data_use_case_test.dart` passed.
- `test/features/printing/infrastructure/printer_integration_test.dart` passed.
- `test/features/backup/local_backup_service_test.dart` initially failed for the same migration guard issue during v2 restore. After the migration fix, it passed.
- `test/database/app_database_test.dart` passed.

All tests: `flutter test` passed all tests.

Windows build: attempted but not executed successfully because the current host is not Windows. Flutter returned: `"build windows" only supported on Windows hosts.`

Repository status check: `git status --short` failed because the working directory did not appear to be a Git repository.

## Issues or Limitations

- Windows build validation remains blocked by the current non-Windows environment.
- Physical printer validation was not performed.
- Printer IDs may refer to printers that are unavailable later; this prompt intentionally persists the preference without resolving or deleting it.
- Saved printer preferences are not wired into print execution yet. Print Preview still uses the current system-default print target behavior.
- No Settings UI was implemented.
- No printer dropdowns, printer management UI, Backup UI, or settings navigation card was implemented.
- No print history, printer capability cache, printer audit history, or printer preference fallback UI was added.
- The working directory did not appear to be a Git repository when `git status --short` was attempted.

## Next Safe Step

The next safe step is Settings UI implementation using the approved Stitch reference, real printer discovery, and persisted printer preferences.
