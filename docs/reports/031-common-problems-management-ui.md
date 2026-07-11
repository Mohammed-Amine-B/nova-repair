# Prompt 031 — Common Problems Management UI

## Summary

Implemented the Common Problems management UI inside Settings. The app now has a Settings navigation card, a Common Problems sub-screen, real loading from SQLite, debounced backend search, add/edit dialogs, delete confirmation, empty/search-empty/error states, usage-count display, and focused Riverpod presentation state.

No New Repair integration, Edit Repair integration, backend semantic change, schema change, categories, device-type grouping, icons, archive behavior, cloud sync, or seed data was added.

## Relevant Previous State

Reviewed:

- `docs/reports/026-settings-ui.md`
- `docs/reports/029-restore-confirmation-dialog.md`
- `docs/reports/030-common-problems-foundation.md`
- `design_reference/NOVA_REPAIR_UI_SPEC.md`

Starting state:

- Settings already had sub-screen navigation for Backup & Restore.
- Common Problems backend/local-data foundation existed.
- Schema version was `6`.
- No Common Problems management UI existed.

## Settings Integration

Added a `Common Problems` navigation card inside Settings with:

- title: `Common Problems`
- description: `Manage frequently used repair problems`
- trailing chevron

The card opens the Common Problems management sub-screen. Backup & Restore remains available in the same Data section.

## Page Layout

The Common Problems page uses:

- `Back to Settings`
- shared `PageHeader`
- title: `Common Problems`
- subtitle: `Manage frequently used repair problem templates`
- centered desktop content with max width `960`
- top toolbar with search and `Add Common Problem`
- list card for persisted templates

Each list row shows:

- problem title
- usage label such as `Used 1 time` or `Used 4 times`
- Edit action
- Delete action

No category, device type, icon, color, created date, or internal ID is shown.

## Search

The search field uses placeholder:

`Search common problems...`

Behavior:

- debounced at `280ms`
- blank search uses normal list
- results come from the existing repository SQL-side search
- backend ordering is preserved

No local presentation sorting/filtering was added.

## Add / Edit / Delete

Add:

- opens a centered `Add Common Problem` dialog
- field label: `Problem`
- placeholder: `Enter a frequently used problem`
- actions: Cancel, Add Problem
- blank input shows `Problem is required.`
- duplicate input shows `This problem already exists.`

Edit:

- opens a centered `Edit Common Problem` dialog
- prefills the current title
- actions: Cancel, Save Changes
- duplicate rename shows `This problem already exists.`
- usage count and timestamps remain backend-owned

Delete:

- uses the shared confirmation dialog style
- title: `Delete Common Problem?`
- message: `This removes the template from your Common Problems list.`
- clarification: `Existing repairs will not be changed.`
- actions: Cancel, Delete

Deleting a template does not modify existing repair `reportedProblem` values.

## Empty and Error States

No data:

- `No common problems yet`
- `Add frequently used repair problems to speed up repair intake.`
- `Add Common Problem`

No search result:

- `No matching problems`
- `Try a different search.`

Load error:

- `Common problems could not be loaded.`
- Retry action

No fake rows are shown.

## Navigation

Implemented:

```text
Settings
   -> Common Problems
Common Problems
   -> Back to Settings
Settings
```

The Settings sidebar destination remains selected while Common Problems is open. No routing package was added.

## Database Schema

Schema version remains `6`.

No tables, columns, indexes, migrations, generated Drift files, repair fields, or backup semantics were changed.

## Tests Run

- `dart format lib/features/common_problems/common_problems_page.dart lib/features/common_problems/presentation/common_problems_controller.dart lib/features/common_problems/presentation/common_problems_state.dart lib/features/settings/settings_page.dart lib/app/app_shell.dart test/features/common_problems/common_problems_page_test.dart test/features/settings/settings_page_test.dart test/app_shell_test.dart`
- `flutter analyze`
- `flutter test test/features/common_problems/common_problems_page_test.dart`
- `flutter test test/features/settings/settings_page_test.dart`
- `flutter test test/app_shell_test.dart`

## Validation Results

Formatting: passed with no remaining changes.

Static analysis: passed with no issues.

Focused Common Problems page tests: passed.

Settings page tests: passed.

App shell tests: passed.

Per prompt instruction, full `flutter test`, persistence tests, and `flutter build windows` were not run.

## Limitations

- Common Problems are not integrated into New Repair yet.
- Common Problems are not integrated into Edit Repair yet.
- Usage count is displayed but is not incremented by this UI.
- No categories, device-type grouping, archive behavior, cloud sync, or seed templates were added.
- No backend Common Problems semantics were changed.

## Next Step

Prompt 032 — New/Edit Repair Common Problems Integration
