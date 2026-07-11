# Prompt 036 — Local Tracking Identity and Sync Outbox Foundation

## Summary

Implemented the local persistence foundation for future online tracking publishing. Nova Repair now persists a stable internal `publicShopId`, assigns stable per-repair tracking tokens, and records deduplicated pending `upsertSnapshot` work in a local tracking sync outbox.

No backend, HTTP networking, Supabase SDK, retry worker, background timer, QR payload change, public website, tracking UI, or Settings UI change was added.

## Public Shop Identity

Added internal `ShopSettings.publicShopId`.

Behavior:

- generated once when settings are created or first loaded without one
- stored locally in `shop_settings.public_shop_id`
- preserved across app restarts
- preserved by backup/restore
- not derived from shop name, hostname, database path, or machine identity
- not shown in normal Settings UI

The installation secret/API credential remains deferred.

## Repair Tracking Tokens

Added internal `Repair.trackingToken` backed by `repairs.tracking_token`.

New repairs receive a token inside the repair creation transaction. UI callers cannot supply the token.

Existing repairs are backfilled during schema migration with generated unique random tokens.

Tokens are generated with `Random.secure()`, base64url encoding, no padding, and at least 128 bits of entropy. They are not derived from repair code, internal ID, phone number, timestamps, or sequential values.

## Outbox Model

Added `tracking_sync_outbox` with:

- `id`
- `repair_id`
- `operation`
- `attempt_count`
- `last_error`
- `next_attempt_at`
- `created_at`
- `updated_at`

Supported v1 operation:

- `upsertSnapshot`

The outbox stores only a repair reference and operation metadata. It does not store serialized snapshot JSON. Future publishing should load the latest repair and build the latest public snapshot at publish time.

## Enqueue Semantics

There is one pending row per repair through a unique `repair_id`.

Enqueue behavior:

- missing row inserts `attemptCount = 0`, `lastError = null`, and `nextAttemptAt = now`
- existing row keeps the same row identity
- existing row resets `attemptCount` to `0`
- existing row clears `lastError`
- existing row sets `nextAttemptAt = now`
- existing row updates `updatedAt`

Outbox operations added:

- enqueue/refresh repair
- list due pending entries ordered by `nextAttemptAt`, `createdAt`, then `id`
- mark publish success by deleting the row
- mark publish failure by SQL-side incrementing `attemptCount`, storing a short safe error, and setting `nextAttemptAt`
- drop stale entries for future missing-repair publisher cases

## Transactional Integration

Repair mutation paths enqueue tracking refreshes inside existing SQLite transactions:

- repair creation
- warranty return creation through normal repair creation
- normal repair detail update
- status change
- price proposal/update
- price clearing
- customer price decision update

The v1 rule is intentionally simple: any successful repair mutation queues one deduplicated `upsertSnapshot`, because public `updatedAt` can change and duplicate queue rows are prevented.

No network failure concept is introduced into local repair workflows.

## Migration

Schema changed from `6` to `7`.

Migration behavior:

- adds `repairs.tracking_token`
- adds `shop_settings.public_shop_id`
- creates `tracking_sync_outbox`
- backfills a generated `publicShopId` for the singleton shop settings row when present
- backfills generated unique tracking tokens for existing repairs
- creates or refreshes one pending outbox row for every existing repair

Normal app startup does not regenerate existing tokens or public shop IDs.

## Backup / Restore

`BackupValidator` now supports schema version `7`.

Backup/restore behavior:

- v7 backups preserve `publicShopId`
- v7 backups preserve repair tracking tokens
- v7 backups preserve pending outbox rows
- pre-v7 backups restore and migrate to v7
- pre-v7 restored repairs receive generated tracking tokens
- pre-v7 restored settings receive a generated public shop ID when a settings row exists
- pre-v7 restored repairs receive pending outbox rows for future publication

Restore provider invalidation now includes online tracking generator/outbox providers.

## Database Schema

Final schema version: `7`.

Added:

- `shop_settings.public_shop_id`
- `repairs.tracking_token`
- `tracking_sync_outbox`

No remote IDs, backend credentials, network tables, status history, QR tables, or serialized snapshot tables were added.

## Tests Run

- `dart run build_runner build`
- `dart format lib/database/app_database.dart lib/features/online_tracking lib/features/repairs lib/features/settings lib/features/backup test/features/online_tracking test/database/app_database_test.dart test/features/backup/local_backup_service_test.dart test/features/backup/restore_confirmation_dialog_test.dart test/features/repairs/data/repair_creation_workflow_test.dart test/features/repairs/data/repair_status_workflow_test.dart test/features/repairs/data/repair_update_workflow_test.dart test/features/settings/data/shop_settings_persistence_test.dart test/features/common_problems/data/common_problem_persistence_test.dart`
- `flutter analyze`
- `flutter test test/features/online_tracking/`
- `flutter test test/database/app_database_test.dart`
- `flutter test test/features/backup/local_backup_service_test.dart`
- `flutter test test/features/repairs/data/repair_creation_workflow_test.dart`
- `flutter test test/features/repairs/data/repair_status_workflow_test.dart`
- `flutter test test/features/repairs/data/repair_update_workflow_test.dart`
- `flutter analyze`

## Validation Results

Code generation: passed. Drift output was regenerated for schema version `7`.

Formatting: passed.

Static analysis: passed with no issues.

Focused online tracking tests: passed.

Database schema tests: passed.

Backup service tests: initially failed due to one remaining schema `6` expectation. After updating it to `7`, the suite passed.

Repair creation workflow tests: passed.

Repair status workflow tests: passed.

Repair update workflow tests: passed.

The online tracking migration/restore tests emitted Drift debug warnings about multiple `AppDatabase` instances during intentional database reopen/replace scenarios, but tests passed.

Per Prompt 036, full `flutter test` and `flutter build windows` were not run.

## Limitations

- No backend or network publisher exists yet.
- No retry timer, background worker, or retry policy exists yet.
- No installation secret/API credential is stored yet.
- No QR payload change was made; QR still uses the visible repair code.
- No public tracking website was implemented.
- Public shop ID generation for a database with no settings row happens when settings are first initialized.
- The outbox stores only pending latest-state work, not sync history.

## Next Step

Prompt 037 — Online Backend Foundation.
