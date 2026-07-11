# Prompt 039 — Desktop Publisher and Retry Integration

## Summary

Implemented the automatic Desktop tracking publisher. Nova Repair now processes the existing local `tracking_sync_outbox` while the app is running, builds the latest safe public repair snapshot at publish time, sends it to the deployed `publish-repair-tracking` Edge Function, deletes successful outbox entries, and schedules safe retries for failures.

No Flutter tests, Windows build, QR changes, customer website, Settings redesign, repair workflow changes, local Drift schema changes, Supabase schema changes, or backend function changes were added.

## Publish Client

Added:

- `RepairTrackingPublishClient`

Behavior:

- calls only `publish-repair-tracking`
- sends `POST`
- sends `Content-Type: application/json`
- sends `X-Nova-Shop-Id` from the snapshot public shop ID
- sends `X-Nova-Installation-Secret` from secure credential storage
- sends the existing `PublicRepairTrackingSnapshot.toJson()` contract
- uses a finite 15-second timeout
- maps backend success results and safe failure categories

The Desktop app does not query or write Supabase tables directly and does not use the Supabase Flutter SDK.

## Latest Snapshot Flow

Added:

- `TrackingSyncProcessor`

For each due outbox entry, the processor:

1. reads the current Installation Secret from secure storage
2. stops quietly if no credential exists
3. loads due outbox entries with limit `20`
4. loads current `ShopSettings`
5. loads the latest repair by `repairId`
6. drops the outbox entry if the repair is missing
7. builds `PublicTrackingIdentity` from repair `trackingToken` and current `publicShopId`
8. builds a fresh `PublicRepairTrackingSnapshot`
9. publishes the snapshot

Snapshots are not serialized into the outbox.

## Automatic Processing

Added:

- `TrackingSyncCoordinator`
- publisher Riverpod providers in `tracking_publisher_providers.dart`

Behavior:

- starts from `AppShell` after the first frame
- triggers one immediate async processing cycle
- checks periodically every 30 seconds while the app is open
- prevents overlapping cycles with one in-process lock
- stops its timer when disposed
- does not block app startup, first frame, navigation, or local repair workflows

No OS background service, platform scheduler, connectivity package, sync UI, or normal user-facing status indicator was added.

## Retry Policy

Added:

- `TrackingSyncRetryPolicy`

Temporary retry delays:

- attempt 1: 30 seconds
- attempt 2: 2 minutes
- attempt 3: 10 minutes
- attempt 4: 30 minutes
- attempt 5+: 60 minutes

Safe error categories:

- `network_error`
- `timeout`
- `rate_limited`
- `server_error`
- `authentication_failed`
- `invalid_payload`
- `ownership_conflict`
- `unexpected_response`

No stack traces, raw HTTP response bodies, authentication headers, Installation Secret, or customer message text are stored in outbox metadata.

## Authentication Failure

HTTP `401` and `403` are treated as authentication failure.

Behavior:

- keep the outbox entry
- mark `lastError = authentication_failed`
- increment attempt count
- set next retry to 1 hour later
- stop the current processing cycle

The publisher does not delete the secure credential, clear the outbox, regenerate tracking tokens, or modify `publicShopId`.

## Outbox Success and Failure

Successful backend results:

- `published`
- `already_current`
- `ignored_stale`

All three delete the outbox row because the backend has an equal or newer public projection.

Temporary failures keep the outbox row and schedule retry.

Permanent-style failures:

- `invalid_payload`: retry after 24 hours
- `ownership_conflict`: retry after 24 hours

Missing repairs drop stale outbox entries safely.

## Offline-First Behavior

Local repair workflows remain offline-first.

Repair creation, edit, status changes, price changes, customer-message changes, and other local mutations still commit to SQLite first. Publishing runs afterward from the outbox and cannot make local repair saves fail.

No credential behavior:

- no network publish attempt
- outbox entries remain pending
- no failure is recorded
- normal app usage continues

No due work behavior:

- no HTTP request is made

## Restore Compatibility

Restored outbox rows remain pending.

The secure Installation Secret remains device-local and outside SQLite. If a restored database has a different `publicShopId` than the saved credential, the publish endpoint will reject authentication. The publisher keeps the outbox entry, marks authentication failure, and stops the cycle safely.

No restore logic was broadly changed.

## Database Schema

Local Drift schema remains version `7`.

No local migrations, generated Drift changes, tables, columns, indexes, Supabase migrations, Edge Function changes, or PostgreSQL schema changes were added.

## Validation Run

Commands run:

- `dart format lib/app/app_shell.dart lib/features/online_tracking/application/repair_tracking_publish_client.dart lib/features/online_tracking/application/tracking_sync_retry_policy.dart lib/features/online_tracking/application/tracking_sync_processor.dart lib/features/online_tracking/application/tracking_sync_coordinator.dart lib/features/online_tracking/application/online_tracking_backend_config.dart lib/features/online_tracking/tracking_publisher_providers.dart lib/features/online_tracking/online_tracking_providers.dart`
- `flutter analyze`
- `dart format lib/features/online_tracking/application/tracking_sync_processor.dart`
- `flutter analyze`
- `dart format lib/features/online_tracking/application/repair_tracking_publish_client.dart`
- `flutter analyze`
- `dart format lib/features/online_tracking/application/tracking_sync_coordinator.dart`
- `flutter analyze`
- static `rg` and file inspections for publisher endpoint usage, outbox success/failure handling, timer setup, and credential/header safety

No Flutter tests and no Windows build were run, per mandatory prompt rule.

## Validation Results

Formatting: succeeded.

Static analysis: initially reported one style issue in `RepairTrackingPublishResult.failure`. After fixing it, `flutter analyze` reported no issues.

Code generation: not run because no Drift schema or generated inputs changed.

Flutter tests: not run, per prompt rule.

Windows build: not run, per prompt rule.

## Limitations

- Real publishing against deployed Supabase was not manually validated in this prompt.
- No Flutter tests were added or run by instruction.
- No normal user-facing sync status, pending count, retry button, or diagnostics UI was added.
- Shop name/subtitle changes do not yet mass-republish all repairs.
- Publishing runs only while Nova Repair is open.
- Missing `publicShopId` stops a processing cycle quietly.
- A missing repair tracking token is treated as `invalid_payload` and retried later; normal migrated/current repairs should already have tokens.

## Next Step

Manually validate real publish flow against deployed Supabase, then implement the public customer tracking website.
