# Prompt 028 — Backup & Restore UI

## Summary

Implemented the approved Backup & Restore UI and wired it into the existing Settings area. The app now has a Settings → Backup & Restore → Settings flow, real current-data summary loading, local backup creation through a save-file dialog, valid backup-file selection through an open-file dialog, safe success/error feedback, and a restore request boundary for the future destructive confirmation dialog.

No Restore Confirmation Dialog, actual restore execution from the UI, Settings redesign, Backup redesign, cloud backup, automatic backup, printer changes, QR changes, schema changes, or sample data were added.

## Previous State Reviewed

Reports `docs/reports/001-project-foundation.md` through `docs/reports/027-printer-preference-execution-wiring.md` were read.

Relevant starting state:

- Drift schema version was `5`.
- Settings UI existed and displayed a Backup & Restore card boundary.
- Local backup and restore services already existed.
- Backup validation already accepted current and older supported schemas.
- Printer preference execution was already wired into printing.
- No Backup & Restore screen or file-picker UI existed.

`design_reference/NOVA_REPAIR_UI_SPEC.md` and the approved Backup & Restore Stitch references were reviewed.

## Design References Used

- `design_reference/NOVA_REPAIR_UI_SPEC.md`
- `design_reference/stitch/stitch_nova_repair_dashboard_management/nova_repair_backup_restore_refined/screen.png`
- `design_reference/stitch/stitch_nova_repair_dashboard_management/nova_repair_backup_restore_refined/code.html`
- `design_reference/stitch/stitch_nova_repair_dashboard_management/nova_repair_design_system/DESIGN.md`

The screenshot was treated as the strongest visual reference, with `code.html` used only as supporting layout reference.

## Files Inspected

- Prompt 028 attachment text
- `docs/reports/001-project-foundation.md` through `docs/reports/027-printer-preference-execution-wiring.md`
- `design_reference/NOVA_REPAIR_UI_SPEC.md`
- approved Backup & Restore Stitch screenshot and HTML reference
- `pubspec.yaml`
- `lib/app/app_shell.dart`
- `lib/features/settings/settings_page.dart`
- `lib/features/backup/application/local_backup_service.dart`
- `lib/features/backup/backup_providers.dart`
- `lib/features/backup/infrastructure/backup_validator.dart`
- `lib/features/repairs/domain/repositories/repair_repository.dart`
- `lib/features/repairs/data/datasources/repair_local_data_source.dart`
- `lib/features/repairs/data/repositories/drift_repair_repository.dart`
- existing backup, settings, app shell, and repair query tests

## Files Created

- `lib/features/backup/application/backup_file_dialog_service.dart`
- `lib/features/backup/backup_restore_page.dart`
- `lib/features/backup/presentation/backup_restore_controller.dart`
- `lib/features/backup/presentation/backup_restore_state.dart`
- `test/features/backup/backup_restore_page_test.dart`
- `docs/reports/028-backup-restore-ui.md`

## Files Modified

- `lib/app/app_shell.dart`
- `lib/features/backup/application/local_backup_service.dart`
- `lib/features/repairs/domain/repositories/repair_repository.dart`
- `lib/features/repairs/data/datasources/repair_local_data_source.dart`
- `lib/features/repairs/data/repositories/drift_repair_repository.dart`
- `pubspec.yaml`
- `pubspec.lock`
- `test/features/repairs/change_status_dialog_test.dart`
- `test/features/repairs/edit_repair_test.dart`
- `test/features/repairs/new_repair_test.dart`
- `test/features/repairs/repair_details_test.dart`
- `test/features/repairs/repairs_list_test.dart`

## Navigation Integration

Settings now opens Backup & Restore through the existing Settings card callback. The app shell stores a local `isManagingBackupRestore` state while keeping the Settings sidebar destination selected.

Flow:

- Settings → Backup & Restore
- Backup & Restore → Back to Settings

No routing package was added.

## Backup & Restore Layout

The screen uses:

- Back to Settings action
- shared `PageHeader`
- Current Data section
- Create Backup section
- Restore Backup section
- soft warning panel before restore

Title:

- `Backup & Restore`

Subtitle:

- `Protect and recover your Nova Repair data`

No unrelated settings, Common Problems panel, cloud backup panel, or decorative dashboard content was added.

## Current Data

The Current Data summary loads real local data:

- Repairs: SQL-side repair count through `RepairRepository.getRepairCount()`.
- Database Size: actual database file size from `DatabaseLifecycleManager.resolveDatabaseFile().stat()`.
- Last Updated: latest truthful timestamp among latest repair `updatedAt`, shop settings `updatedAt`, and database file modified time.

No fake values from the Stitch reference are used.

## Create Backup Flow

Create Backup opens a save-file dialog through `BackupFileDialogService`.

When the user selects a destination, the controller calls:

- `LocalBackupService.createBackupFile(destinationPath)`

The backup service writes to the exact chosen destination path through a temporary file, validates the generated backup, renames it into place, validates again, and returns metadata.

Successful creation shows:

- `Backup created successfully.`

The existing directory-based `createBackup(directory)` API remains available and unchanged.

## Suggested Filename

The UI suggests:

- `NovaRepair_Backup_YYYY-MM-DD.nrbackup`

The date comes from the local current date supplied by `backupRestoreClockProvider`.

## Last Backup State

The screen shows the last backup created in the current screen session only.

No backup history, print history, database table, or persisted backup log was added.

## Restore File Selection

Choose Backup File opens an open-file dialog through `BackupFileDialogService`.

The selected file is validated through:

- `LocalBackupService.validateBackup(path)`

Invalid files are rejected safely with:

- `The selected backup file is not valid.`

## Selected Backup Display

When a valid backup is selected, the UI displays only the basename, for example:

- `Selected: Valid_Selected_Backup.nrbackup`

The full filesystem path is intentionally not displayed.

## Restore Action Boundary

The Restore Backup button is disabled until a valid backup file is selected.

When enabled, it invokes:

- `onRestoreRequested(SelectedBackupFile backup)`

The app shell currently receives the validated file boundary and intentionally does not call the destructive restore service. Restore confirmation and execution are deferred.

## Backup Restore State

Added:

- `BackupDataSummary`
- `SelectedBackupFile`
- `BackupRestoreState`
- `BackupRestoreController`
- `backupDataSummaryProvider`
- `backupRestoreControllerProvider`
- `backupRestoreClockProvider`
- `backupFileDialogServiceProvider`

State tracks backup creation progress, file selection progress, the session last backup, the selected valid backup, success messages, and safe error messages.

## Loading States

The Current Data section shows a calm loading state while summary data is being read.

Buttons expose loading states during backup creation and file selection.

No shimmer dependency or decorative loading animation was added.

## Error States

Current Data load failure shows:

- `Current data summary could not be loaded.`
- Retry action

Create Backup failure shows:

- `Backup could not be created. Please try again.`

Invalid backup selection shows:

- `The selected backup file is not valid.`

Raw SQLite errors, stack traces, plugin errors, and full file paths are not shown.

## File Dialog Decision

Added `file_selector` because the repository did not already contain a suitable file picker/save dialog abstraction.

The new `BackupFileDialogService` is intentionally small and supports:

- save location selection for backup creation
- file selection for backup validation
- accepted extensions: `nrbackup`, `sqlite`

Tests use a fake dialog service and do not open native dialogs.

## Shared Widgets Reused

Reused:

- `PageHeader`
- `SectionCard`
- `PrimaryButton`
- `SecondaryButton`
- `GhostButton`
- `EmptyValueText`
- shared theme colors, spacing, and radius tokens

No duplicate sidebar, app shell, page header, card, or button system was added.

## Architecture Changes

Added a focused Backup presentation layer:

- `BackupRestorePage`
- `BackupRestoreController`
- `BackupRestoreState`

Extended existing backend/query surfaces:

- `LocalBackupService.createBackupFile`
- `RepairRepository.getRepairCount`
- `RepairRepository.getLatestRepairUpdatedAt`

No new backup repository, fake use case, routing system, restore workflow redesign, or database abstraction was added.

## Database Schema

Schema version remains `5`.

No tables, columns, indexes, migrations, generated Drift files, backup history tables, or restore audit tables were added.

## Dependencies

Added:

- `file_selector`

Changed:

- `pubspec.lock` was updated by dependency resolution.

Removed: none.

## Tests Added

- `test/features/backup/backup_restore_page_test.dart`
  - Current data summary reads real repair count, database size, and last-updated sources.
  - Exact-path backup creation writes the chosen file path through the real service.
  - Backup page renders approved title, subtitle, summary values, sections, warning, and empty selection state.
  - Create Backup uses the suggested filename and selected save path.
  - Create Backup failure records a safe error.
  - Duplicate backup creation is prevented.
  - Valid backup selection displays only basename and enables restore boundary.
  - Invalid backup selection is rejected safely.
  - App shell opens Backup & Restore from Settings and returns to Settings.

Updated repair test fakes to satisfy the expanded `RepairRepository` API.

## Validation Commands

- `flutter pub add file_selector`
- `dart format lib/features/backup lib/features/repairs lib/app/app_shell.dart`
- `flutter analyze`
- `dart format test/features/backup/backup_restore_page_test.dart`
- `flutter test test/features/backup/backup_restore_page_test.dart`
- `flutter test test/features/backup/local_backup_service_test.dart`
- `flutter test test/features/settings/settings_page_test.dart`
- `flutter test test/app_shell_test.dart`
- `flutter test test/features/repairs/data/repair_query_foundation_test.dart`
- `flutter pub get`
- `dart format .`
- `flutter analyze`
- `flutter test`
- `flutter build windows`
- `git status --short`

Code generation was not run because no Drift schema or generated-code inputs changed.

## Validation Results

Dependency resolution: succeeded. `flutter pub add file_selector` added the package, and `flutter pub get` completed successfully. Flutter reported 18 packages with newer versions incompatible with dependency constraints.

Formatting: succeeded. `dart format .` completed successfully.

Static analysis: initially found missing fake repository methods and one unused test import while the new tests were being completed. After fixes, `flutter analyze` reported no issues.

Focused Backup UI tests: initially exposed widget-test fake-async issues around real file I/O and unresolved provider work. The tests were split so real service/provider behavior is covered in normal async tests, while widget tests use fakes for native dialogs and long-running file operations. Final `flutter test test/features/backup/backup_restore_page_test.dart` passed.

Affected tests passed:

- `flutter test test/features/backup/local_backup_service_test.dart`
- `flutter test test/features/settings/settings_page_test.dart`
- `flutter test test/app_shell_test.dart`
- `flutter test test/features/repairs/data/repair_query_foundation_test.dart`

All tests: `flutter test` passed all tests.

Windows build: attempted but not executed successfully because the current host is not Windows. Flutter returned: `"build windows" only supported on Windows hosts.`

Repository status check: `git status --short` failed because the working directory did not appear to be a Git repository.

## Issues or Limitations

- Windows build validation remains blocked by the current non-Windows environment.
- Native file dialog behavior was not manually tested on Windows in this environment.
- Physical restore testing through UI was not performed because restore execution is intentionally deferred.
- Restore Confirmation Dialog is deferred.
- Restore Backup UI currently stops at a validated callback boundary.
- Last Backup is session-only and is not persisted.
- No backup history, automatic backup, cloud backup, restore audit history, Common Problems panel, or Backup & Restore settings were added.
- Widget tests use fake file dialogs and fake backup services for UI-triggered flows because Flutter widget fake-async is not a good fit for real native file dialogs and file I/O callbacks.
- The working directory did not appear to be a Git repository when `git status --short` was attempted.

## Next Safe Step

The next safe step is Restore Confirmation Dialog implementation using the approved Stitch reference and the existing safe restore workflow.
