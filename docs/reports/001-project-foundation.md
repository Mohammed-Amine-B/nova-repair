# Prompt 001 — Project Foundation

## Summary

Established the initial offline Flutter desktop foundation for Nova Repair. The default counter scaffold was replaced with a Riverpod-enabled application root, a desktop-first app shell, simple internal navigation, three feature placeholder pages, a light theme foundation, and Drift-based SQLite infrastructure ready for future schema additions.

## Files Inspected

- `pubspec.yaml`
- `analysis_options.yaml`
- `lib/main.dart`
- `test/widget_test.dart`
- `README.md`
- Existing project file list under `lib/`, `test/`, and `docs/`

## Files Created

- `lib/app/app.dart`
- `lib/app/app_shell.dart`
- `lib/app/navigation/app_destination.dart`
- `lib/app/theme/app_theme.dart`
- `lib/database/app_database.dart`
- `lib/database/app_database.g.dart`
- `lib/database/database_provider.dart`
- `lib/features/dashboard/dashboard_page.dart`
- `lib/features/repairs/repairs_page.dart`
- `lib/features/settings/settings_page.dart`
- `test/app_shell_test.dart`
- `test/database/app_database_test.dart`
- `docs/reports/001-project-foundation.md`

## Files Modified

- `analysis_options.yaml`
- `lib/main.dart`
- `pubspec.yaml`
- `pubspec.lock`
- `test/widget_test.dart` was removed and replaced by focused foundation tests.

## Architecture Created

The project now uses a small feature-first structure:

- `lib/main.dart` starts Flutter, initializes bindings, and wraps the app in `ProviderScope`.
- `lib/app/` contains application setup, shell layout, navigation metadata, and theme setup.
- `lib/database/` contains local SQLite infrastructure and the Riverpod database provider.
- `lib/features/` contains only the currently visible placeholder feature pages: dashboard, repairs, and settings.

Lightweight clean architecture was chosen because this prompt only requires application foundation, not business behavior. No feature data layers, domain layers, repository interfaces, use cases, entities, controllers, or fake providers were created. Those layers should be introduced only when future repair or settings behavior requires them.

The app shell uses a desktop-oriented `NavigationRail` with simple local page switching. This is enough for the current foundation and avoids adding a routing package before it provides real value.

Riverpod is established at the application root and currently exposes only the database provider. Future repositories and controllers can be registered through Riverpod when real behavior exists.

The theme foundation provides a Material 3 light theme with consistent typography, a restrained blue seed color, navigation rail styling, and divider styling. It is intentionally small and easy to extend.

The database infrastructure uses Drift over SQLite with schema versioning, a generated database class, injectable query executors for tests, and persistent app-support storage for the production database file.

## Implementation Details

The scaffold counter app was removed. `NovaRepairApp` now owns the `MaterialApp`, and `AppShell` owns the selected navigation destination. Dashboard, Repairs, and Settings pages contain only a title and a short placeholder message.

Navigation destinations are defined in `AppDestination`, which keeps labels and icons in one place and makes adding future top-level pages straightforward.

The database can be opened with the default persistent connection or with an injected executor such as `NativeDatabase.memory()` for tests. The persistent database file resolves to an application support directory subfolder named `Nova Repair` with the file name `nova_repair.sqlite`.

Generated Drift files are excluded from analyzer input because the intentionally empty initial schema produces generated helper code with an unused field warning.

## Database Changes

Database technology selected: Drift with SQLite.

Storage location strategy: `path_provider` resolves the platform application support directory, then the app stores the database under a `Nova Repair` subdirectory as `nova_repair.sqlite`. This avoids temporary folders, build output, source folders, and the repository root.

Schema version setup: `AppDatabase.schemaVersion` is `1`.

Migration foundation: Drift's `MigrationStrategy` is configured with `onCreate` calling `createAll()`. `onUpgrade` is present and currently has no migration steps because schema version 1 has no business tables yet.

Tables created: none.

## Dependencies

Added:

- `flutter_riverpod`: application-wide dependency injection and future state management foundation.
- `drift`: SQLite abstraction, schema versioning, migrations, and testable database access.
- `sqlite3_flutter_libs`: bundled SQLite runtime support for Flutter desktop/mobile targets.
- `path_provider`: resolves the correct persistent application support directory.
- `path`: builds platform-safe database file paths.
- `drift_dev`: Drift code generation.
- `build_runner`: runs Drift code generation.

Removed: none.

Changed: `pubspec.lock` was updated by dependency resolution.

## Validation Commands

- `flutter pub add flutter_riverpod drift sqlite3_flutter_libs path_provider path`
- `flutter pub add dev:drift_dev dev:build_runner`
- `dart run build_runner build --delete-conflicting-outputs`
- `dart format .`
- `flutter analyze`
- `flutter test`
- `flutter pub get`
- `flutter build windows`

## Validation Results

Dependency installation: succeeded. `flutter pub add` and `flutter pub get` completed successfully. Flutter reported that 12 packages have newer versions incompatible with current constraints.

Code generation: succeeded. `dart run build_runner build --delete-conflicting-outputs` generated Drift output. Build Runner reported that `--delete-conflicting-outputs` was removed and ignored by this version.

Formatting: succeeded. `dart format .` completed successfully.

Static analysis: succeeded. `flutter analyze` reported no issues after excluding generated `*.g.dart` files.

Tests: succeeded. `flutter test` passed all tests.

Windows build: attempted but not executed successfully because the current host is not Windows. Flutter returned: `"build windows" only supported on Windows hosts.`

## Issues or Limitations

- Windows build validation is blocked by the current non-Windows environment.
- The initial Drift schema intentionally contains no business tables.
- No repair CRUD, shop settings, printing, QR generation, backup/restore, online tracking, authentication, inventory, suppliers, reports, or sample business data were implemented.
- The database migration strategy has no version-to-version migration steps yet because only schema version 1 exists and there are no tables.
- The working directory did not appear to be a Git repository when `git status --short` was attempted.

## Next Safe Step

The next safe development step is the repair database domain and schema foundation.
