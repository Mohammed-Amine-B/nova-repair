# Prompt 013 — Local Backup and Restore Foundation

## Summary

Implemented the local backup and restore foundation. The app can now create validated full SQLite database backups, validate backup files, restore a selected backup safely, roll back if replacement fails, and reopen the database through a small lifecycle manager.

No UI, file picker, cloud backup, scheduled backup, background backup, encryption, online functionality, schema changes, backup tables, or backup history were added.

## Previous State Reviewed

Reports `docs/reports/001-project-foundation.md` through `docs/reports/012-qr-generation-foundation.md` were read.

Relevant starting state:

- Flutter desktop foundation, Riverpod root, and desktop app shell existed.
- Drift schema version was `4`.
- The production database used a persistent SQLite file resolved through `resolveAppDatabaseFile`.
- Repairs, shop settings, repair code sequence, warranty relationships, statuses, prices, timestamps, printing data, and QR generation foundations existed.
- There was no local backup service, restore workflow, backup validation, backup metadata model, lifecycle restore coordinator, Backup & Restore UI, cloud backup, or online functionality.

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
- Attached Prompt 013 request text
- `lib/database/app_database.dart`
- `lib/database/database_provider.dart`
- `pubspec.yaml`
- Existing file list under `lib/`, `test/`, and `docs/`

## Files Created

- `lib/database/database_lifecycle_manager.dart`
- `lib/features/backup/domain/entities/backup_metadata.dart`
- `lib/features/backup/domain/errors/backup_exception.dart`
- `lib/features/backup/infrastructure/backup_validator.dart`
- `lib/features/backup/application/local_backup_service.dart`
- `lib/features/backup/backup_providers.dart`
- `test/features/backup/local_backup_service_test.dart`
- `docs/reports/013-local-backup-restore-foundation.md`

## Files Modified

- `lib/database/app_database.dart`
- `lib/database/database_provider.dart`
- `pubspec.yaml`
- `pubspec.lock`

## Backup Strategy

The backup strategy is a full SQLite database backup.

Creation flow:

1. Resolve the current live database file.
2. Validate and create the destination directory.
3. Build a deterministic backup filename from the injected clock.
4. Create a temporary backup file in the destination directory.
5. Run SQLite `VACUUM INTO ?` through the active Drift database connection.
6. Validate the temporary backup.
7. Rename the temporary file to the final backup filename.
8. Validate the final backup and return metadata.

Journal/WAL handling:

- Backup creation uses SQLite `VACUUM INTO` through the live connection.
- This creates a consistent standalone SQLite database file and avoids blindly copying a possibly incomplete main database while WAL/SHM sidecars may exist.

Temporary file behavior:

- Backups are first written to a hidden `.<backup-file-name>.tmp` file.
- If creation or validation fails, the temporary file is removed where practical.

Atomic finalization:

- The final user-visible backup appears only after the temporary backup validates and is renamed.
- Existing final backup names are not overwritten.

## Backup Metadata

`BackupMetadata` contains:

- `filePath`: full backup file path.
- `fileName`: backup file name.
- `createdAt`: UTC creation timestamp used by backup creation, or file modified time when validating an existing file.
- `fileSizeBytes`: backup file size.
- `schemaVersion`: SQLite `PRAGMA user_version`.
- `repairCount`: count of rows in `repairs`, or `0` when validating a schema without the repairs table.

## Backup File Naming

Format:

- `nova_repair_backup_yyyy-MM-dd_HHmmss.sqlite`

Example:

- `nova_repair_backup_2026-07-05_143000.sqlite`

Timezone strategy:

- File names use local time for user readability.
- Metadata timestamps returned by backup creation use UTC.

The filename contains no colon characters and uses the `.sqlite` extension.

## Backup Validation

Validation checks:

- file exists
- path is a file
- file is non-empty
- SQLite can open and query it
- `PRAGMA user_version` is supported
- required tables exist for the backup schema version

Supported schema versions:

- `1`
- `2`
- `3`
- `4`

Required tables by schema version:

- version `1`: no business tables required, matching the original empty foundation schema
- version `2`: `repairs`
- version `3`: `repairs`, `shop_settings`
- version `4`: `repairs`, `shop_settings`, `repair_code_sequence`

Unsupported future or unknown schema versions fail clearly with `UnsupportedBackupSchemaException`.

## Restore Strategy

Restore flow:

1. Validate the selected backup file.
2. Resolve the current live database file.
3. Reject restore when the selected backup path is the current live database path.
4. Create a safety backup of the current database with `VACUUM INTO`.
5. Validate the safety backup.
6. Close the current `AppDatabase`.
7. Delete SQLite sidecar files for the live database path.
8. Copy the selected backup file over the live database path.
9. Reopen the database through `DatabaseLifecycleManager`.
10. Run a simple query to force the database open.
11. Validate the restored database file.
12. Return metadata for the restored live database.

If an older supported backup is restored, the current `AppDatabase` migration logic runs when the database reopens and upgrades it to schema version `4`.

## Safety Rollback

Before replacement, the service creates an internal safety backup of the current database.

If replacement, reopen, migration, or validation fails:

- the current database connection is closed if needed
- SQLite sidecar files are removed
- the safety backup is copied back to the live database path
- the database is reopened

If rollback itself fails, `RestoreRollbackException` is thrown.

Cleanup:

- safety backup files are removed after successful restore where practical
- incomplete backup temp files are removed after backup failure where practical

## Database Lifecycle

`DatabaseLifecycleManager` was added to own the current `AppDatabase` instance.

Behavior:

- exposes the current database through `database`
- resolves the live database file path
- closes the current database before restore replacement
- reopens a fresh `AppDatabase` after restore
- prevents duplicate close work on an already closed instance

Riverpod:

- `databaseLifecycleManagerProvider` owns the lifecycle manager.
- `appDatabaseProvider` now returns `databaseLifecycleManagerProvider.database`.
- Backup UI can later use `localBackupServiceProvider`; no UI state or progress providers were added.

## Architecture Changes

Backup feature structure:

- `lib/features/backup/domain/entities/`
  - `BackupMetadata`
- `lib/features/backup/domain/errors/`
  - focused backup and restore exceptions
- `lib/features/backup/infrastructure/`
  - `BackupValidator`
- `lib/features/backup/application/`
  - `LocalBackupService`
- `lib/features/backup/backup_providers.dart`
  - Riverpod providers for validation and service access

Database lifecycle:

- `lib/database/database_lifecycle_manager.dart`
- `openNativeDatabaseFile(File file)` was extracted in `app_database.dart` so production and tests can open file-backed databases consistently.

Intentionally deferred layers:

- no Backup & Restore page
- no file picker
- no progress controller
- no snackbar/dialog provider
- no backup history controller
- no scheduled/background backups
- no cloud backup
- no encryption

## Database Schema

Schema version remains `4`.

No backup tables were added because backups are explicit file operations, not business records stored inside the application database. Backup history is intentionally deferred.

## Dependencies

Changed:

- `sqlite3` moved from `dev_dependencies` to regular `dependencies`.

Why:

- Backup validation is production code and needs to open selected SQLite files directly without relying on a dev-only dependency.

Added: none beyond moving the existing package to runtime dependencies.

Removed: none.

## Tests Added

- `test/features/backup/local_backup_service_test.dart`
  - creates a backup file
  - backup file is non-empty
  - backup metadata contains deterministic filename, file size, schema version, UTC creation timestamp, and repair count
  - live database remains unchanged after backup
  - backup contains repairs, shop settings, and repair code sequence
  - deterministic backup filename contains no colon characters and uses `.sqlite`
  - valid backup validation succeeds
  - missing file validation fails
  - empty file validation fails
  - non-SQLite file validation fails
  - SQLite file missing required tables fails
  - unsupported schema version fails clearly
  - restore returns live database from state B to backed-up state A
  - restore preserves repairs, shop settings, and sequence state
  - restore from schema version 2 migrates to schema version 4
  - restore from the current live database path fails clearly
  - restore rollback reopens the previous live database after replacement failure
  - invalid backup destination fails clearly

## Validation Commands

- `flutter pub add sqlite3`
- `dart format .`
- `flutter analyze`
- `flutter test test/features/backup/local_backup_service_test.dart`
- `flutter test`
- `flutter pub get`
- `flutter build windows`

## Validation Results

Dependency resolution: succeeded. `flutter pub add sqlite3` moved `sqlite3 3.3.4` from `dev_dependencies` to regular `dependencies`. `flutter pub get` completed successfully. Flutter reported that 12 packages have newer versions incompatible with current constraints.

Formatting: succeeded. `dart format .` completed successfully.

Static analysis: initially reported deprecated `sqlite3.dispose()` calls and one unused test import. After switching to `close()` and removing the unused import, `flutter analyze` reported no issues.

Focused backup tests: initially one deterministic filename assertion failed because the test seed advanced the injected clock before backup creation. After resetting the fixed backup time before creating that backup, `flutter test test/features/backup/local_backup_service_test.dart` passed.

All tests: succeeded. `flutter test` passed all tests.

Windows build: attempted but not executed successfully because the current host is not Windows. Flutter returned: `"build windows" only supported on Windows hosts.`

## Security and Limitations

- Backup files are unencrypted SQLite database files.
- Backup files contain the same local application data as the live database and should be stored securely by the user.
- External files referenced by path, such as logo image files, are not copied into backups.
- Generated QR output, PDFs, logs, caches, application binaries, and temporary files are not included.
- No backup contents are logged or exposed by backup metadata.
- Windows build validation remains blocked by the current non-Windows environment.

## Issues or Limitations

- Restore support is file-based and intended for the local SQLite database only.
- Backup validation checks schema version and required app tables but does not perform a full semantic audit of every row.
- Backup filename collisions within the same second fail rather than overwrite an existing backup.
- Cloud backup, encryption, scheduled backup, automatic backup, file-picker UI, progress UI, restore confirmation UI, backup history, and online functionality are intentionally deferred.

## Next Safe Step

The backend/offline core is now ready to pause.

The next development work should be UI implementation using approved Stitch designs, starting with the first screen the user provides.
