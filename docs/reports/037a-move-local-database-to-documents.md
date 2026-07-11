# Prompt 037A — Move Local Database to Documents

## Summary

Moved the production local SQLite database path to the platform Documents directory while preserving a one-time safe migration path from the previous application-support location.

No Supabase files, online tracking backend behavior, QR behavior, UI, local Drift schema, tables, columns, or dependencies were changed.

## Previous Database Location

The previous production resolver used:

```text
<Application Support>/Nova Repair/nova_repair.sqlite
```

On the current Linux development machine this is approximately:

```text
~/.local/share/com.example.nova_repair/Nova Repair/nova_repair.sqlite
```

This path is now treated as a legacy source for one-time migration only.

## New Canonical Location

The new canonical production database path is:

```text
<Documents>/Nova Repair/nova_repair.sqlite
```

Expected Windows shape:

```text
C:\Users\<User>\Documents\Nova Repair\nova_repair.sqlite
```

The `Nova Repair` directory is created automatically if missing.

## Legacy Migration Strategy

Added:

- `lib/database/local_database_path_resolver.dart`

Startup resolution behavior:

1. Resolve the canonical Documents database path.
2. If the canonical database already exists, use it.
3. If the canonical database is absent, resolve the legacy application-support path.
4. If the legacy database exists, checkpoint and copy it to a temporary file in the canonical directory.
5. Validate the temporary copy with SQLite.
6. Rename the temporary file to `nova_repair.sqlite`.
7. Leave the legacy database untouched.
8. Open only the canonical database.

The canonical database always wins. The legacy database never overwrites an existing canonical database.

## SQLite Safety

Before copying a legacy database, the resolver opens the legacy SQLite file directly and runs:

```text
PRAGMA wal_checkpoint(TRUNCATE)
PRAGMA optimize
```

Then it copies the main database file to a temporary canonical file, validates the copy with:

```text
PRAGMA integrity_check
PRAGMA user_version
```

Only after validation does it rename the temporary file into place.

If migration fails, the temporary file and temporary sidecars are removed where practical, the legacy file remains untouched, and startup fails instead of silently creating an empty database.

## Startup Behavior

`AppDatabase` continues using the existing lazy Drift connection, but the lazy open now resolves through `LocalDatabasePathResolver` before opening the production file.

`DatabaseLifecycleManager.resolveDatabaseFile()` and restore reopen behavior use the same canonical resolver, so backup/restore and diagnostics resolve the same database path as normal app startup.

## Backup Integration

`LocalBackupService` already resolves the source database through `DatabaseLifecycleManager.resolveDatabaseFile()`.

After this change:

- Create Backup reads the canonical Documents database.
- database size reads the canonical file.
- last-modified metadata reads the canonical file.
- backup file format remains unchanged and portable.

## Restore Integration

Restore still uses the existing safety flow:

- validate backup
- create safety backup
- close current database
- replace live database
- reopen database
- validate restored database
- roll back on failure

The live restore target is now:

```text
<Documents>/Nova Repair/nova_repair.sqlite
```

Restore does not write to the legacy application-support path.

## Online Identity Preservation

Moving the SQLite file preserves:

- `shop_settings.public_shop_id`
- repair `tracking_token` values
- `tracking_sync_outbox` rows

The move does not regenerate public shop identity, repair tracking tokens, or pending outbox work.

Copying the same database to another machine preserves these identities. That is correct for replacement-PC migration or backup recovery, but not intended for two active PCs using the same copied database simultaneously.

## Database Schema

Local Drift schema remains version `7`.

No migrations, generated Drift files, tables, columns, indexes, or backup format changes were added.

## Validation Run

Commands run:

- `dart format lib/database/app_database.dart lib/database/local_database_path_resolver.dart`
- `flutter analyze`
- `dart format lib/database/local_database_path_resolver.dart`
- `flutter analyze`

Per prompt rule, no Flutter tests and no Windows build were run.

## Validation Results

Formatting: succeeded.

Static analysis: initially reported two sqlite3 deprecation infos in the new resolver. After switching from `dispose()` to `close()`, `flutter analyze` reported no issues.

Code generation: not run because no Drift schema or generated inputs changed.

Flutter tests: not run, per mandatory prompt rule.

Windows build: not run, per mandatory prompt rule.

## Manual Verification

Recommended developer steps:

1. Close Nova Repair.
2. Note the old database path:
   `<Application Support>/Nova Repair/nova_repair.sqlite`
3. Launch the updated app.
4. Confirm the new file exists at:
   `<Documents>/Nova Repair/nova_repair.sqlite`
5. Confirm old data still appears in the app.
6. Confirm the old legacy database still exists.
7. Restart the app.
8. Confirm no second migration occurs and the canonical database remains in use.
9. Create one repair.
10. Confirm the new database modification time changes.

Do not manually copy SQLite files while the app is running. Backup/Restore remains the official transfer method.

## Limitations

- Manual filesystem verification was not executed in this environment.
- No Flutter tests were run by instruction.
- No Windows build was run by instruction.
- Legacy cleanup is intentionally deferred; the old database remains as a safety fallback.
- No multi-device detection was added for copied databases with shared online tracking identity.
- If a legacy database is locked or cannot be checkpointed, startup fails safely rather than creating a new empty canonical database.

## Next Step

Manually verify database migration, then continue installation provisioning and Desktop online integration.
