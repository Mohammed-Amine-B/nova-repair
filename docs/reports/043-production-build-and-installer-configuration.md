# Prompt 043 — Production Build and Installer Configuration

## Summary

Added production build and distribution documentation for Nova Repair Windows releases and tightened ignore rules for local secrets, databases, and generated build artifacts.

No Flutter Desktop behavior, repair workflow, Supabase backend, Next.js website, QR generation logic, local SQLite schema, dependencies, or installer generator was changed.

## Production Tracking Domain

The current working public tracking website is:

```text
https://nova-repair-tracking.vercel.app
```

Production desktop builds must pass this domain through:

```text
NOVA_TRACKING_WEB_BASE_URL
```

The old broken domain `https://nova-repair.vercel.app` is documented as not to be used for production builds.

## Build Configuration

Documented official Windows production build command:

```text
flutter build windows --dart-define=NOVA_TRACKING_WEB_BASE_URL=https://nova-repair-tracking.vercel.app
```

Documented Linux development verification command:

```text
flutter run -d linux --dart-define=NOVA_TRACKING_WEB_BASE_URL=https://nova-repair-tracking.vercel.app
```

The Windows build command was intentionally not run in this prompt.

## Portable Distribution

Documented that Flutter Windows release output is normally under:

```text
build/windows/x64/runner/Release/
```

The portable ZIP should include the release folder contents together, including executable, DLLs, `data/`, Flutter assets, bundled print fonts, and native plugin outputs.

## Installer Strategy

Recommended v1 distribution strategy:

```text
Portable ZIP first
Installer later
```

Reasoning documented:

- safer during pilot sales
- fewer installer-specific bugs
- database already lives in Documents
- secure credential is stored by OS secure storage
- updates can replace the app folder without touching user data

Future installer options such as Inno Setup or MSIX were mentioned as future work only.

## Database and User Data

Documented canonical production database path:

```text
Documents/Nova Repair/nova_repair.sqlite
```

Documented expected Windows shape:

```text
C:\Users\<User>\Documents\Nova Repair\nova_repair.sqlite
```

The guide explains that app folders can be replaced during updates while the database remains in Documents. It also warns not to ship real customer databases, commit SQLite files, or delete user Documents data during updates.

## Secure Credential Setup

Documented that the Installation Secret is stored in OS-backed secure storage with the existing app-owned key:

```text
nova_repair.online_tracking.installation_secret
```

Documented that the secret is not stored in SQLite, not included in backups, not committed, and not bundled inside the executable.

Documented hidden installer shortcut:

```text
Ctrl + Shift + Alt + T
```

Added a first-shop setup checklist covering install, hidden setup, Installation Secret entry, sync verification, ticket printing, and QR scan verification.

## Update Strategy

Documented safe update flow:

1. close app
2. replace app folder/files
3. do not touch Documents database, backups, or OS secure storage
4. restart app
5. verify repairs still exist
6. verify Online Tracking remains configured
7. create or update one repair to confirm publisher behavior

## Git Ignore / Secret Safety

Updated `.gitignore` to ignore local secret files, SQLite/database files, generated web build folders, Node dependencies, and generated output folders.

Added/confirmed ignore coverage for:

- `.env`
- `.env.*`
- `.env.example` exceptions
- `supabase/scripts/.env`
- `*.sqlite`
- `*.db`
- app build outputs
- `.dart_tool`
- `.next`
- `node_modules`

Committed `.env.example` files remain allowed.

## Documentation Added

Created:

- `docs/production-build-and-distribution.md`
- `docs/reports/043-production-build-and-installer-configuration.md`

The production guide includes:

- production tracking domain
- Windows build command
- development run command
- portable ZIP distribution
- installer strategy
- database location
- secure credential storage
- first shop setup checklist
- updating an existing installation
- what not to commit or ship
- end-to-end production verification
- future installer notes

## Validation Run

Commands run:

- `dart format docs/production-build-and-distribution.md docs/reports/043-production-build-and-installer-configuration.md`
- `flutter analyze`

No Flutter tests were run.

No Windows build was run.

## Validation Results

`dart format` was attempted on the changed Markdown files as requested, but exited with code `65` because Dart formatter only parses Dart source files. No files were formatted by that command.

Static analysis succeeded. `flutter analyze` reported no issues.

## Limitations

- No Windows release build was produced in this prompt.
- No installer was generated.
- No portable ZIP was assembled.
- No Flutter tests were run, per prompt instruction.
- No Windows build was run, per prompt instruction.
- Hidden Online Tracking setup was documented but not manually exercised.
- Physical Windows packaging and QR scan validation remain manual verification tasks.

## Next Step

Prompt 044 — Windows Release Build Manual Verification
