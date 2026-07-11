# Prompt 030 — Common Problems Foundation

## Summary

Implemented the backend/local-data foundation for dynamic Common Problems. The app now has a focused Common Problems feature with a domain entity, title normalization, duplicate protection, Drift persistence, schema version `6`, repository workflows, Riverpod providers, migration coverage, and backup/restore compatibility.

No Common Problems UI, New Repair UI changes, Edit Repair UI changes, device categories, static seed data, cloud sync, or repair foreign-key relationship was added.

## Relevant Previous State

Relevant reports and references were reviewed:

- `docs/reports/004-repair-creation-workflow.md`
- `docs/reports/009-repair-search-filter-logic.md`
- `docs/reports/020-repair-update-workflow-foundation.md`
- `docs/reports/025-shop-settings-model-extension-foundation.md`
- `docs/reports/029-restore-confirmation-dialog.md`
- `design_reference/NOVA_REPAIR_UI_SPEC.md`

Starting state:

- Drift schema version was `5`.
- Repairs stored permanent `reportedProblem` text directly.
- Shop settings already included printer preferences.
- Backup/restore validation supported schema versions through `5`.
- No Common Problems feature existed.

## Data Model

Added immutable `CommonProblem` with:

- `id`
- `title`
- `usageCount`
- `createdAt`
- `updatedAt`

Added `common_problems` table with:

- `id`
- `title`
- `normalized_title`
- `usage_count`
- `created_at`
- `updated_at`

No repair column, `commonProblemId`, foreign key, join table, category, device type, icon, color, description, sort position, archive flag, or seed rows were added.

## Normalization and Duplicate Policy

Title normalization:

- trims outer whitespace
- collapses repeated internal whitespace
- lowercases only for duplicate comparison

The user-facing `title` is preserved after trim/collapse. Arabic is not transliterated, accents are not removed, and no aggressive linguistic normalization is performed.

Duplicate protection:

- `normalized_title` has database-level uniqueness.
- repository workflows check duplicates and throw `DuplicateCommonProblemTitleException`.
- blank titles throw `InvalidCommonProblemTitleException`.

## Workflows

Repository operations added:

- create common problem
- update title
- delete
- get by ID
- list
- search
- increment usage

Use cases added:

- `CreateCommonProblemUseCase`
- `UpdateCommonProblemUseCase`
- `DeleteCommonProblemUseCase`
- `IncrementCommonProblemUsageUseCase`

Focused errors added:

- `InvalidCommonProblemTitleException`
- `DuplicateCommonProblemTitleException`
- `CommonProblemNotFoundException`

Deleting or renaming a Common Problem does not modify existing repairs because repairs continue storing permanent `reportedProblem` text.

## Ordering and Search

Default listing is SQL-side ordered by:

1. `usage_count DESC`
2. `updated_at DESC`
3. `id ASC`

Search:

- trims the query
- blank query behaves like list
- searches `title` and `normalized_title`
- applies SQL-side `LIKE` matching with escaped `%`, `_`, and backslashes
- uses case-insensitive matching where practical through lowercased text
- returns the same ordered result shape

## Usage Count

Usage count starts at `0`.

`incrementUsage`:

- atomically increments `usage_count` by `1`
- updates `updated_at`
- throws `CommonProblemNotFoundException` for missing rows

No arbitrary usage-count setter was exposed.

## Schema Migration

Schema version changed from `5` to `6`.

Migration adds only `common_problems`.

Confirmed behavior:

- v5 databases migrate to v6.
- existing repairs are preserved.
- existing settings are preserved.
- printer preferences are preserved.
- repair sequence is preserved.
- `common_problems` starts empty after migration.

## Backup Compatibility

`BackupValidator` now supports schema version `6`.

Confirmed behavior:

- v6 backups validate.
- v6 backup/restore preserves Common Problems and usage counts.
- older supported backups still restore.
- pre-v6 backups migrate to schema version `6`.
- `common_problems` is empty after restoring a pre-v6 backup.

Restore refresh invalidation now includes the Common Problems repository/data-source providers.

## Files Created

- `lib/features/common_problems/application/create_common_problem_use_case.dart`
- `lib/features/common_problems/application/delete_common_problem_use_case.dart`
- `lib/features/common_problems/application/increment_common_problem_usage_use_case.dart`
- `lib/features/common_problems/application/update_common_problem_use_case.dart`
- `lib/features/common_problems/common_problem_providers.dart`
- `lib/features/common_problems/data/datasources/common_problem_local_data_source.dart`
- `lib/features/common_problems/data/mappers/common_problem_mapper.dart`
- `lib/features/common_problems/data/repositories/drift_common_problem_repository.dart`
- `lib/features/common_problems/data/tables/common_problems_table.dart`
- `lib/features/common_problems/domain/entities/common_problem.dart`
- `lib/features/common_problems/domain/entities/create_common_problem_input.dart`
- `lib/features/common_problems/domain/entities/update_common_problem_input.dart`
- `lib/features/common_problems/domain/errors/common_problem_exception.dart`
- `lib/features/common_problems/domain/repositories/common_problem_repository.dart`
- `lib/features/common_problems/domain/services/common_problem_title_normalizer.dart`
- `test/features/common_problems/data/common_problem_persistence_test.dart`
- `docs/reports/030-common-problems-foundation.md`

## Files Modified

- `lib/app/app_shell.dart`
- `lib/database/app_database.dart`
- `lib/database/app_database.g.dart`
- `lib/features/backup/infrastructure/backup_validator.dart`
- `test/database/app_database_test.dart`
- `test/features/backup/local_backup_service_test.dart`
- `test/features/backup/restore_confirmation_dialog_test.dart`
- `test/features/settings/data/shop_settings_persistence_test.dart`
- `test/features/repairs/data/repair_persistence_test.dart`
- `test/features/repairs/data/repair_creation_workflow_test.dart`

## Tests Run

- `dart run build_runner build`
- `dart format lib/features/common_problems lib/database/app_database.dart lib/features/backup/infrastructure/backup_validator.dart lib/app/app_shell.dart test/features/common_problems/data/common_problem_persistence_test.dart test/database/app_database_test.dart test/features/backup/local_backup_service_test.dart test/features/backup/restore_confirmation_dialog_test.dart test/features/settings/data/shop_settings_persistence_test.dart test/features/repairs/data/repair_persistence_test.dart test/features/repairs/data/repair_creation_workflow_test.dart`
- `flutter analyze`
- `flutter test test/features/common_problems/`
- `flutter test test/database/app_database_test.dart`
- `flutter test test/features/backup/local_backup_service_test.dart`

## Validation Results

Code generation: passed. Drift output was regenerated for schema version `6`.

Formatting: passed with no remaining changes.

Static analysis: passed with no issues.

Focused Common Problems tests: passed.

Database schema test: passed.

Backup service tests: passed.

The Common Problems migration/restore tests emitted Drift debug warnings about multiple `AppDatabase` instances during database replacement scenarios, but the focused tests passed.

Per prompt instruction, full `flutter test` and `flutter build windows` were not run.

## Limitations

- No Common Problems UI was implemented.
- New Repair and Edit Repair do not use Common Problems yet.
- Usage count is not automatically incremented anywhere; future selection behavior should call the explicit increment workflow.
- No static default Common Problems are seeded.
- No device-type grouping, categories, icons, archive behavior, cloud sync, or repair relationship was added.
- Physical backup/restore workflows beyond automated local tests were not manually exercised.

## Next Step

Prompt 031 — Common Problems Management UI
