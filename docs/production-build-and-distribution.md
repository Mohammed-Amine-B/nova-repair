# Nova Repair Production Build and Distribution

## Production Tracking Domain

The current production customer tracking website is:

```text
https://nova-repair-tracking.vercel.app
```

Production desktop builds must use this domain for Customer Ticket QR tracking URLs. Do not use the old broken domain:

```text
https://nova-repair.vercel.app
```

## Windows Build Command

Official production build command:

```text
flutter build windows --dart-define=NOVA_TRACKING_WEB_BASE_URL=https://nova-repair-tracking.vercel.app
```

Do not put secrets in `--dart-define`. The tracking web base URL is public configuration only.

## Development Run Command

Linux development verification command:

```text
flutter run -d linux --dart-define=NOVA_TRACKING_WEB_BASE_URL=https://nova-repair-tracking.vercel.app
```

This lets the developer verify that Customer Ticket QR payloads point at the production tracking website while still running locally.

## Portable ZIP Distribution

Flutter Windows release output is normally created under:

```text
build/windows/x64/runner/Release/
```

For v1 distribution, package the contents of that release folder as a portable ZIP. The distributed folder must include:

- the executable
- required DLLs
- the `data/` folder
- Flutter assets
- bundled font assets, including the Noto print fonts declared in `pubspec.yaml`
- native plugin files produced by the Windows build, including file selector, secure storage, printing, and FFI plugin outputs

Do not hand-pick only the executable. Ship the release folder contents together so Flutter assets and plugin binaries stay in the expected relative locations.

## Installer Strategy

Recommended v1 strategy:

```text
Portable ZIP first
Installer later
```

This is safer during pilot installs because it avoids installer-specific bugs, the database already lives outside the application folder, and updates can replace the app folder without touching user data.

A future installer can be added later with tools such as Inno Setup or MSIX. That future installer should preserve the same user-data rules documented here.

## Database Location

Production SQLite data lives in the user's Documents directory:

```text
Documents/Nova Repair/nova_repair.sqlite
```

On Windows, the expected shape is:

```text
C:\Users\<User>\Documents\Nova Repair\nova_repair.sqlite
```

Important rules:

- the app binary folder can be replaced during updates
- the database remains in Documents
- backups remain separate from the app folder
- never ship a real customer database in an installer or ZIP
- never commit `.sqlite` or `.db` files
- never delete `Documents/Nova Repair` during updates

The app may migrate an older database from the legacy application-support location into Documents on first startup. The legacy file is left untouched as a safety fallback.

## Secure Credential Storage

The Online Tracking Installation Secret is stored in OS-backed secure storage through `flutter_secure_storage`.

The secure storage key is app-owned:

```text
nova_repair.online_tracking.installation_secret
```

The Installation Secret is not stored in SQLite, not included in backups, not committed, and not bundled inside the executable.

Hidden installer setup shortcut:

```text
Ctrl + Shift + Alt + T
```

Normal shop users should not need this setup screen. Use it during installation or support visits to configure the shop once.

## First Shop Setup Checklist

1. Install or unzip the app.
2. Start Nova Repair once.
3. Open hidden setup with `Ctrl + Shift + Alt + T`.
4. Enter the Installation Secret generated during Supabase provisioning.
5. Confirm the state becomes configured.
6. Create or update a repair.
7. Wait for sync.
8. Confirm the public row appears in Supabase.
9. Print a Customer Ticket.
10. Scan the QR code and confirm the tracking page opens.

Do not write real secrets into source files, documentation, screenshots, tickets, or chat logs.

## Updating an Existing Installation

Safe update flow:

1. Close Nova Repair.
2. Replace the application folder/files with the new portable release folder.
3. Do not touch:
   - `Documents/Nova Repair/nova_repair.sqlite`
   - user backup files
   - OS secure storage
4. Start Nova Repair.
5. Verify existing repairs still exist.
6. Verify Online Tracking still appears configured through the hidden setup screen if needed.
7. Create or update one repair to confirm the publisher still works.

If the app is moved to a replacement PC, use the official Backup & Restore flow for customer data and configure or verify the secure Installation Secret on that device.

## What Not to Commit or Ship

Do not commit:

- `.env`
- `.env.local`
- `web/.env.local`
- `supabase/scripts/.env`
- Installation Secrets
- Supabase service role keys
- database passwords
- real customer `.sqlite` or `.db` files
- generated build folders
- `.dart_tool/`
- `.next/`
- `node_modules/`

Do not ship inside the public portable ZIP:

- source `.env` files
- Supabase service role keys
- developer-only scripts with secrets
- real customer databases
- local backup files unless intentionally transferring that customer's data

Committed `.env.example` files are allowed because they document required variables without secrets.

## End-to-End Production Verification

1. Run or build with:

   ```text
   --dart-define=NOVA_TRACKING_WEB_BASE_URL=https://nova-repair-tracking.vercel.app
   ```

2. Confirm Customer Ticket QR points to:

   ```text
   https://nova-repair-tracking.vercel.app/track/<trackingToken>
   ```

3. Confirm Device Label QR remains repair-code-only.
4. Confirm the public tracking page shows only safe data:
   - shop name
   - optional shop subtitle
   - repair code
   - device display name
   - public status
   - optional customer-visible message
   - received date
   - last updated date
5. Confirm the public page does not show customer phone, device access information, internal notes, price, internal database IDs, or Installation Secret data.
6. Change a repair status or customer-visible message and confirm the public page updates after sync.
7. Disconnect internet and confirm local repair workflows still work offline.
8. Reconnect internet and confirm pending sync outbox entries retry later.

## Future Installer Notes

When adding an installer later:

- preserve `Documents/Nova Repair/nova_repair.sqlite`
- do not delete user backups
- do not clear OS secure storage during normal updates
- install all release-folder runtime files together
- do not bundle real customer data
- do not display Online Tracking setup to normal users
- keep `NOVA_TRACKING_WEB_BASE_URL` fixed to the production domain for production builds
- document uninstall behavior clearly before deleting any user data
