# Prompt 038 — Secure Installation Connection Setup

## Summary

Implemented secure installation connection setup for Online Tracking. The app now has OS-backed secure storage for the Installation Secret, a Settings sub-screen for connecting/disconnecting online tracking, a focused verifier client/controller, a centralized backend functions URL config, and a new Supabase verification Edge Function.

No outbox publishing, retry processing, QR payload changes, customer website, repair workflow changes, local Drift schema changes, or Supabase PostgreSQL migrations were added.

## Secure Credential Storage

Added:

- `InstallationCredentialStore`
- `SecureInstallationCredentialStore`

The raw Installation Secret is stored with `flutter_secure_storage` under the stable app-owned key:

```text
nova_repair.online_tracking.installation_secret
```

The key does not include `publicShopId`, repair IDs, machine username, or any rotating value.

The secret is not stored in SQLite, `ShopSettings`, Documents, backups, Dart constants, source code, logs, SharedPreferences, or committed files.

Dependency decision:

- Added `flutter_secure_storage` for OS-backed credential storage with Windows and Linux support.
- Added `http` as a direct minimal dependency for the Edge Function verifier client.

## Verification Endpoint

Created:

- `supabase/functions/verify-tracking-installation/index.ts`

Registered in `supabase/config.toml`:

```toml
[functions.verify-tracking-installation]
verify_jwt = false
```

Behavior:

- accepts `POST`
- requires `X-Nova-Shop-Id`
- requires `X-Nova-Installation-Secret`
- loads an enabled installation by `public_shop_id`
- hashes the supplied secret with SHA-256
- compares against `installation_secret_hash`
- returns `{ "ok": true }` on success
- returns the same safe unauthorized response for bad shop ID, bad secret, or disabled installation

The endpoint does not publish snapshots, mutate repair tracking data, expose installation IDs, expose stored hashes, or expose raw secrets.

## Settings Integration

Added an `Online Tracking` navigation card inside Settings, placed with the other settings sub-screens:

- Common Problems
- Online Tracking
- Backup & Restore

Created:

- `OnlineTrackingSettingsPage`
- `OnlineTrackingConnectionController`
- `OnlineTrackingConnectionState`

The Settings sidebar destination remains selected while Online Tracking is open.

## Connect Flow

Disconnected state shows:

- `Not Connected`
- read-only real `Public Shop ID`
- obscured `Installation Secret` field
- helper text: `The installation secret is stored securely on this device and is not included in backups.`
- `Connect`

Connect behavior:

1. trims the entered secret
2. rejects blank input
3. prevents duplicate submissions
4. sends `publicShopId` and Installation Secret to `verify-tracking-installation`
5. saves the secret to secure storage only after successful verification
6. clears the input after success
7. shows safe errors for invalid credentials, server/network failure, and secure-storage save failure

## Connected State

Connected/configured state is based on whether a secure credential exists locally.

Connected state shows:

- `Connected`
- read-only real `Public Shop ID`
- `Disconnect`
- helper text: `This installation can publish repair tracking updates.`

The page does not display, reveal, or copy the Installation Secret.

The v1 behavior does not re-verify automatically on every rebuild. Future publisher work will handle invalid credential failures safely.

## Disconnect Flow

Disconnect uses a confirmation dialog:

- title: `Disconnect Online Tracking?`
- message: `This device will stop publishing repair tracking updates until it is connected again.`
- clarification: `Local repairs and pending sync data will not be deleted.`

On confirm, the app deletes only the secure credential.

It keeps:

- `publicShopId`
- repair tracking tokens
- outbox rows
- local repairs
- backend public projections

No Supabase delete call is made.

## Security Behavior

Confirmed by implementation inspection:

- raw Installation Secret is not written to SQLite
- raw Installation Secret is not written to backup files
- raw Installation Secret is not committed
- secure credential storage is used
- Connect verifies before saving
- Disconnect deletes only the secure credential
- `publicShopId` remains unchanged
- tracking tokens remain unchanged
- outbox rows remain unchanged
- verification endpoint does not mutate tracking data
- verification endpoint does not expose sensitive backend details
- request authentication headers are not logged

## Restore Limitation

The Installation Secret is outside SQLite. After restore, the secure credential remains on the current device.

This is acceptable when restored data belongs to the same `publicShopId`.

If a different shop database is restored onto a connected device, the saved credential may no longer match the restored `publicShopId`. This prompt does not automatically delete or overwrite credentials. Future publisher/auth failure handling must fail safely.

## Database Schema

Local Drift schema remains version `7`.

Supabase PostgreSQL schema is unchanged.

No local migrations, generated Drift changes, Supabase migrations, tables, columns, indexes, QR changes, repair workflow changes, or outbox processing changes were added.

## Validation Run

Commands run:

- `flutter pub add flutter_secure_storage http`
- `dart format lib/app/app_shell.dart lib/app/widgets/form/app_text_field.dart lib/features/settings/settings_page.dart lib/features/online_tracking`
- `flutter analyze`
- `deno check supabase/functions/verify-tracking-installation/index.ts`
- `dart format lib/app/app_shell.dart lib/app/widgets/form/app_text_field.dart lib/features/settings/settings_page.dart lib/features/online_tracking test/features/settings/settings_page_test.dart`
- `flutter analyze`
- static `rg` inspections for credential storage, headers, config, and backend function structure
- `git status --short`

No Flutter tests and no Windows build were run, per mandatory prompt rule.

## Validation Results

Dependency resolution: succeeded. `flutter pub add flutter_secure_storage http` completed and updated `pubspec.yaml` and `pubspec.lock`.

Formatting: succeeded.

Static analysis: initially failed because existing Settings test harnesses needed the new required `onOpenOnlineTracking` callback for analyzer compilation. After updating those harnesses, `flutter analyze` reported no issues.

Deno check: not run successfully because Deno is not installed in this environment. The command failed with `deno: command not found`.

Backend deployment: not attempted. `supabase functions deploy verify-tracking-installation` was intentionally not run.

Repository status: `git status --short` failed because the working directory did not appear to be a Git repository.

## Limitations

- The verification Edge Function was not type-checked locally because Deno is unavailable.
- The verification Edge Function was not deployed.
- No physical Windows secure-storage validation was performed.
- `flutter_secure_storage` may require platform credential-store availability at runtime, especially on Linux development machines.
- Online Tracking connection state is local credential presence, not continuous backend verification.
- Outbox publishing and retry behavior remain unimplemented.
- If a different shop database is restored onto a device with an existing secure credential, the saved credential may not match the restored `publicShopId`.

## Next Step

Prompt 039 — Desktop Publisher and Retry Integration
