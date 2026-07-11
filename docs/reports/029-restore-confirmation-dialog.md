# Prompt 029 — Restore Confirmation Dialog

## Summary

Implemented the approved Restore Confirmation Dialog and connected it to the existing safe local restore workflow. A valid selected backup now opens a centered destructive confirmation modal, can be cancelled safely, can restore through `LocalBackupService.restoreBackup`, prevents duplicate restore submissions, shows progress, handles failures safely, and refreshes relevant app state after success.

No Common Problems UI, cloud backup, automatic backup, restore history, backup format change, schema change, or extra confirmation step was added.

## Relevant Previous State

Reviewed:

- `docs/reports/013-local-backup-restore-foundation.md`
- `docs/reports/025-shop-settings-model-extension-foundation.md`
- `docs/reports/028-backup-restore-ui.md`
- `design_reference/NOVA_REPAIR_UI_SPEC.md`
- approved Restore Confirmation Dialog Stitch screenshot and HTML reference

Relevant starting state:

- Backup & Restore UI already selected and validated a backup file.
- `onRestoreRequested(SelectedBackupFile backup)` already existed.
- `LocalBackupService.restoreBackup` already handled validation, safety backup, database replacement, reopen, rollback, and migration.
- Drift schema version was `5`.

## Files Created

- `lib/features/backup/restore_confirmation_dialog.dart`
- `lib/features/backup/presentation/restore_confirmation_controller.dart`
- `lib/features/backup/presentation/restore_confirmation_state.dart`
- `test/features/backup/restore_confirmation_dialog_test.dart`
- `docs/reports/029-restore-confirmation-dialog.md`

## Files Modified

- `lib/app/app_shell.dart`
- `lib/features/backup/presentation/backup_restore_controller.dart`

## Dialog Behavior

The dialog is a centered modal over Backup & Restore with:

- warning icon
- title: `Restore Backup?`
- subtitle: `Current Nova Repair data will be replaced`
- selected backup basename only
- destructive warning text
- helper text recommending a backup first
- close icon
- Cancel
- Restore Data

The full backup path is not displayed.

While restoring:

- Cancel is disabled.
- Close is disabled.
- Restore Data is disabled.
- duplicate submissions are ignored.
- the destructive button shows `Restoring...`.
- the dialog cannot be popped.

## Restore Workflow

Restore Data calls the existing real restore API:

- `LocalBackupService.restoreBackup(backup.filePath)`

The dialog/controller does not copy database files and does not reimplement restore validation, safety backup, replacement, reopen, rollback, or migration behavior.

## Success Refresh

After successful restore:

- the dialog closes
- selected backup is cleared
- Backup & Restore remains open
- Backup summary is invalidated
- Settings load/controller providers are invalidated
- Dashboard is invalidated
- Repairs List is invalidated
- cached database/repository/data-source providers are invalidated so they do not retain the pre-restore database connection
- stale Repair Details/Edit/Print state is cleared from the app shell

The page shows `Backup restored successfully.`

## Failure Handling

Normal restore failures keep the dialog open and show:

- `Backup could not be restored. Your previous data has been kept.`

Rollback/catastrophic restore failures show:

- `Backup could not be restored. Please try again.`

The selected backup remains available after failure, and retry is possible. Raw SQLite errors, file paths, stack traces, and plugin details are not shown.

## Database Schema

Schema version remains `5`.

No tables, columns, indexes, migrations, backup-history tables, or generated Drift files were added.

## Tests Run

- `dart format lib/features/backup/restore_confirmation_dialog.dart lib/features/backup/presentation/restore_confirmation_controller.dart lib/features/backup/presentation/restore_confirmation_state.dart test/features/backup/restore_confirmation_dialog_test.dart lib/app/app_shell.dart`
- `flutter analyze`
- `flutter test test/features/backup/restore_confirmation_dialog_test.dart`
- `flutter test test/features/backup/backup_restore_page_test.dart`
- `flutter test test/features/backup/local_backup_service_test.dart`
- `flutter test test/app_shell_test.dart`

Per prompt, `flutter test` and `flutter build windows` were not run.

## Validation Results

Formatting: succeeded.

Static analysis: succeeded. `flutter analyze` reported no issues.

Focused Restore Confirmation tests passed:

- dialog content and basename-only display
- cancel without restore call
- duplicate restore prevention
- restoring progress and disabled dismissal controls
- safe failure message and retry
- app-shell success path clears selected backup and remains on Backup & Restore
- real restore integration restores active database data and keeps schema version `5`

Affected Backup & Restore, local backup service, and app shell tests all passed.

## Limitations

- Common Problems UI remains deferred.
- No restore history or audit log was added.
- No cloud or automatic backup behavior was added.
- Native Windows dialog/manual restore testing was not performed in this Linux environment.
- Catastrophic database reopen failure is surfaced as a safe error only; no recovery wizard was added.

## Next Step

Prompt 030 — Common Problems Foundation
