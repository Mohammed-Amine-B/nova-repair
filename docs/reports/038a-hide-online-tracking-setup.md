# Prompt 038A — Hide Online Tracking Setup from Normal Users

## Summary

Hid Online Tracking setup from normal Settings users while preserving the secure credential storage, verifier client, connection controller, and Supabase verification foundation from Prompt 038.

Online installation setup is now reachable only through a hidden in-app installer shortcut. No outbox publishing, retry processing, QR changes, repair workflow changes, Supabase function changes, or schema changes were added.

## Removed Normal Settings Access

Removed the visible `Online Tracking` card from the normal Settings page.

Normal Settings now shows only:

- Common Problems
- Backup & Restore

Normal users no longer see:

- Online Tracking navigation
- Public Shop ID
- Installation Secret field
- Connect button
- Remove Credential button
- Supabase/backend setup language

No placeholder was left behind.

## Hidden Installer Shortcut

Added a hidden Flutter in-app shortcut in `AppShell`:

```text
Ctrl + Shift + Alt + T
```

Behavior:

- works only while the Nova Repair app window has focus
- opens the hidden Online Installation Setup sub-screen
- keeps Settings selected in the sidebar
- does not register a system-global hotkey
- does not add a visible menu item, tooltip, help text, or Settings card

Implementation uses Flutter `Shortcuts`, `Actions`, and `SingleActivator`.

## Setup Flow

The hidden setup screen reuses the Prompt 038 connection logic and now presents installer-focused text:

- title: `Online Installation Setup`
- subtitle: `Configure secure online tracking credentials for this installation`
- close action: `Close`

Disconnected state shows:

- read-only real `Public Shop ID`
- obscured `Installation Secret` input
- `Connect`
- helper text: `The installation secret is stored securely on this device.`

Connect behavior remains unchanged:

1. trim the entered secret
2. reject blank input
3. prevent duplicate submission
4. verify credentials with `verify-tracking-installation`
5. save only after successful verification
6. clear the input after success
7. show safe errors

## Connected State

Connected/configured state is based on local secure credential presence.

The hidden setup screen shows:

- status: `Configured`
- read-only real `Public Shop ID`
- `Remove Credential`

It does not display, reveal, copy, or log the raw Installation Secret.

## Credential Removal

Renamed the installer removal action from Disconnect to:

```text
Remove Credential
```

Confirmation dialog:

- title: `Remove Online Tracking Credential?`
- message: `This device will stop publishing repair tracking updates until a valid credential is configured again.`
- clarification: `Local repairs and pending sync data will not be deleted.`
- actions: Cancel, Remove Credential

On confirm, only the OS secure credential is deleted.

Kept unchanged:

- `publicShopId`
- repair tracking tokens
- `tracking_sync_outbox` rows
- repairs
- backend public data

## Security Behavior

Preserved:

- `InstallationCredentialStore`
- `SecureInstallationCredentialStore`
- secure storage key
- verifier client
- connection controller/state
- safe error messages
- verification-before-save behavior

The raw Installation Secret is still not stored in SQLite, `ShopSettings`, Documents, backups, Dart constants, source code, logs, SharedPreferences, or committed files.

No Supabase Edge Functions were changed.

## Normal User Experience

Normal users can use Nova Repair without seeing or configuring online setup.

The app does not:

- show setup automatically at startup
- block normal offline workflows when no credential exists
- warn normal users about missing credentials
- expose Supabase, Edge Functions, Installation Secret, or publicShopId details in visible Settings

Future publisher behavior should be automatic when a valid secure credential exists.

## Database Schema

Local Drift schema remains version `7`.

Supabase PostgreSQL schema remains unchanged.

No migrations, generated Drift files, tables, columns, indexes, QR changes, repair workflow changes, or outbox processing changes were added.

## Validation Run

Commands run:

- `dart format lib/app/app_shell.dart lib/features/settings/settings_page.dart lib/features/online_tracking/online_tracking_settings_page.dart lib/features/online_tracking/presentation/online_tracking_connection_controller.dart test/features/settings/settings_page_test.dart`
- `flutter analyze`
- static `rg` inspections for the removed Settings card, hidden shortcut, setup title, Installation Secret field, and Remove Credential labels

No Flutter tests and no Windows build were run, per mandatory prompt rule.

## Validation Results

Formatting: succeeded.

Static analysis: succeeded. `flutter analyze` reported no issues.

Static inspection confirmed:

- no `settings-online-tracking-card` remains
- no `onOpenOnlineTracking` Settings callback remains
- hidden `Ctrl + Shift + Alt + T` shortcut exists in `AppShell`
- setup screen title is `Online Installation Setup`
- credential removal label is `Remove Credential`

Flutter tests: not run, per prompt rule.

Windows build: not run, per prompt rule.

## Limitations

- Hidden shortcut behavior was not manually exercised in a running desktop window.
- No automated widget tests were added or run, per prompt rule.
- The installer setup remains available to anyone who knows the hidden shortcut while the app is focused.
- Restore limitation from Prompt 038 remains: a restored database may have a different `publicShopId` than the secure credential on the current device.
- Outbox publishing and retry behavior remain unimplemented.

## Next Step

Prompt 039 — Desktop Publisher and Retry Integration
