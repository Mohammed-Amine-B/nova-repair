# Prompt 039A — Fix Tracking Sync Coordinator Startup Wiring

## Summary

Fixed the tracking sync coordinator startup wiring so the desktop publisher has one app-lifetime owner while `AppShell` is alive.

The coordinator is now retained through a manual Riverpod subscription owned by `AppShell`, starts immediately without blocking UI rendering, keeps its 30-second timer alive, restarts cleanly if the coordinator provider is invalidated, and stops when `AppShell` is disposed.

No publisher redesign, retry-policy change, backend API change, outbox schema change, QR behavior change, tests, or Windows build were added.

## Confirmed Runtime Symptom

Manual runtime verification before this prompt showed:

- Online Tracking credential state was connected.
- A secure credential existed.
- The local outbox contained 2 pending due entries.
- Both entries had `attempt_count = 0`.
- Both entries had `last_error = NULL`.
- The app stayed open longer than the 30-second periodic interval.
- Outbox rows remained unchanged.

That symptom indicated the coordinator was not reliably reaching `TrackingSyncProcessor.processDue()`.

## Root Cause

The coordinator provider was not `autoDispose`, so the issue was not an explicit auto-dispose declaration.

The actual startup wiring problem was that `AppShell` used a one-shot post-frame call:

```dart
ref.read(trackingSyncCoordinatorProvider).start();
```

That created and started a coordinator through `read`, but `AppShell` did not keep a Riverpod listener/subscription or store the returned coordinator as an app-lifetime object. A timer-based coordinator needs an explicit owner for the shell lifetime; a temporary `read` is not reliable lifecycle wiring.

Restore handling repeated the same pattern by invalidating the coordinator provider and immediately using another one-shot `read(...).start()`, again without a retained app-lifecycle subscription.

## Fix Applied

`AppShell` now owns a `ProviderSubscription<TrackingSyncCoordinator>` created with `ref.listenManual(...)` in `initState`.

The listener:

- fires immediately
- starts the coordinator once for the current provider instance
- stops the previous coordinator if Riverpod replaces it
- keeps the provider actively retained while `AppShell` is alive

`AppShell.dispose()` closes the subscription.

Restore invalidation now invalidates `trackingSyncCoordinatorProvider` only. The existing app-lifetime subscription receives the replacement coordinator and starts it, instead of restore code manually creating a temporary read-start instance.

## Coordinator Lifecycle

Expected lifecycle after the fix:

```text
AppShell created
    ↓
manual provider subscription is opened
    ↓
current TrackingSyncCoordinator is started
    ↓
one immediate async process cycle runs
    ↓
30-second periodic timer remains active
    ↓
provider invalidation replaces coordinator if needed
    ↓
previous coordinator is stopped, replacement starts
    ↓
AppShell disposed
    ↓
subscription closes and coordinator is disposed/stopped
```

`TrackingSyncCoordinator.start()` remains idempotent. If called again on the same instance, it does not create a second timer.

`TrackingSyncCoordinator.trigger()` still prevents overlapping cycles with its in-process guard.

## Riverpod Lifetime Behavior

`trackingSyncCoordinatorProvider` remains a normal non-autoDispose provider.

The important change is that `AppShell` now actively listens to the provider for the app shell lifetime instead of only reading it once.

This means:

- one coordinator instance is retained while `AppShell` is alive
- provider replacement is observed
- old timers are stopped
- new replacement coordinators are started
- there is no global singleton outside Riverpod

## Diagnostics

Added minimal safe diagnostics through `debugPrint`:

- `Tracking sync coordinator started`
- `Tracking sync cycle triggered`
- `Tracking sync skipped: no credential`
- `Tracking sync skipped: no due entries`
- `Tracking sync processing N entries`

Diagnostics do not log:

- Installation Secret
- authentication headers
- request payload
- customer message
- raw backend responses

## Database Schema

Local Drift schema remains version `7`.

No migrations, generated Drift files, tables, columns, indexes, outbox schema changes, QR changes, or backend API changes were added.

## Validation Run

Commands run:

- `dart format lib/app/app_shell.dart lib/features/online_tracking/application/tracking_sync_coordinator.dart lib/features/online_tracking/application/tracking_sync_processor.dart lib/features/online_tracking/tracking_publisher_providers.dart`
- `flutter analyze`

Per Prompt 039A, no Flutter tests and no Windows build were run.

## Validation Results

Formatting succeeded.

Static analysis succeeded. `flutter analyze` reported no Dart issues.

Flutter emitted a git object warning before analysis:

```text
fatal: You are attempting to fetch 7a45ab4ae4bd5e640f799d01305dd05439eca3c8, which is in the commit graph file but not in the object database.
```

Despite that environment warning, analysis completed and reported:

```text
No issues found!
```

## Manual Verification

Recommended manual verification:

1. Start the app with a connected Online Tracking credential.
2. Confirm the log shows `Tracking sync coordinator started`.
3. Confirm the log shows `Tracking sync cycle triggered`.
4. If no credential exists, confirm `Tracking sync skipped: no credential`.
5. If no due rows exist, confirm `Tracking sync skipped: no due entries`.
6. If due rows exist, confirm `Tracking sync processing N entries`.
7. Confirm due outbox rows either disappear on successful publish or receive updated retry metadata on failure.
8. Wait at least 30 seconds and confirm another cycle can run.
9. Confirm duplicate concurrent cycles do not occur.

## Limitations

- Real publishing against the deployed backend was not manually executed in this environment.
- Flutter tests were not run, per prompt instruction.
- Windows build was not run, per prompt instruction.
- Physical Windows runtime validation remains separate.
- The existing Flutter/git environment emitted a repository object warning before analysis, although analyzer completed successfully.
