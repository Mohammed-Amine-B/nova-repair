# Prompt 032 — New/Edit Repair Common Problems Integration

## Summary

Integrated existing Common Problems into the shared New Repair and Edit Repair form. Technicians can now use top problem chips or debounced search results to append Common Problem template text into the final editable Reported Problem field, while usage counts increment only after a successful insertion.

No Common Problems backend semantic change, schema change, repair relationship, static templates, category/device grouping, automatic template creation, or broad form redesign was added.

## Relevant Previous State

Reviewed:

- `docs/reports/017-new-repair-ui.md`
- `docs/reports/021-edit-repair-ui.md`
- `docs/reports/030-common-problems-foundation.md`
- `docs/reports/031-common-problems-management-ui.md`
- `design_reference/NOVA_REPAIR_UI_SPEC.md`

Starting state:

- New Repair and Edit Repair used shared `RepairFormContent`.
- Common Problems existed as local SQLite templates.
- Common Problems management UI existed in Settings.
- Repairs still stored only permanent `reportedProblem` text.

## Shared Picker

Added reusable `CommonProblemPicker` in the Repairs presentation layer.

Responsibilities:

- load top Common Problems
- render compact chips
- search Common Problems through the repository
- render compact search results
- emit selected `CommonProblem`

The picker does not own the repair form text permanently and does not create, edit, delete, or persist selected template relationships.

## Most Used Problems

The picker shows up to the top 5 Common Problems using existing backend ordering.

If no Common Problems exist, it shows the restrained helper:

`Manage Common Problems in Settings to add quick problem templates.`

No fake examples or seed data are shown.

## Search

Search field:

`Search common problems...`

Behavior:

- debounced at `280ms`
- uses SQL-side repository search
- preserves backend ordering
- displays title plus compact usage label in results
- clears search after successful result selection

Search failure shows a safe inline error and keeps manual typing available.

## Text Insertion

Added `CommonProblemTextInserter` and `CommonProblemInsertionController`.

Insertion format:

```text
Existing manual text
Selected common problem
Another selected problem
```

The selected template title is appended on a new line. Existing manual text is preserved. The Reported Problem text area remains the final editable source of truth.

## Duplicate Prevention

Before inserting, current Reported Problem text is split into lines and compared with the selected problem title using the Common Problem title normalizer.

If an equivalent line is already present:

- text is not inserted again
- usage count is not incremented again
- manual editing remains available

## Usage Count

Usage count increments through `IncrementCommonProblemUsageUseCase` only after explicit successful selection.

It does not increment when:

- chips render
- search results render
- the form loads existing text
- duplicate insertion is blocked
- usage increment fails

If usage increment fails, the text is not inserted and the UI shows:

`The problem could not be added. Please try again.`

After successful insertion, top/search picker providers are refreshed so usage ordering can update.

## New Repair Integration

New Repair now shows the Common Problems assistant inside the existing Reported Problem section.

Existing behavior remains:

- Initial Status is `Received`
- Save Repair uses existing creation workflow
- Save & Print uses existing creation and print-preview flow
- final saved repair stores only `reportedProblem`

## Edit Repair Integration

Edit Repair uses the same shared Common Problems assistant.

Existing persisted `reportedProblem` loads unchanged and does not increment usage. Selecting a new Common Problem appends it to the current text, and Save Changes persists the final combined text through the existing update workflow.

Deleting a Common Problem later does not alter saved repair text.

## Failure Handling

Common Problems load/search failures do not block the repair form.

Manual typing and existing Reported Problem validation remain available. Repair save behavior remains unchanged.

## Database Schema

Schema version remains `6`.

No tables, columns, indexes, migrations, generated Drift files, repair foreign keys, Common Problem IDs on repairs, or backup behavior changed.

## Tests Run

- `dart format lib/features/repairs/presentation/common_problem_picker.dart lib/features/repairs/presentation/common_problem_insertion_controller.dart lib/features/repairs/presentation/repair_form_content.dart test/features/common_problems/common_problem_picker_test.dart test/features/repairs/new_repair_test.dart test/features/repairs/edit_repair_test.dart`
- `flutter analyze`
- `flutter test test/features/common_problems/common_problem_picker_test.dart`
- `flutter test test/features/repairs/new_repair_test.dart`
- `flutter test test/features/repairs/edit_repair_test.dart`

## Validation Results

Formatting: passed with no remaining changes.

Static analysis: passed with no issues.

Focused Common Problem picker tests: passed.

New Repair tests: passed.

Edit Repair tests: passed.

Per prompt instruction, full `flutter test`, persistence tests, and `flutter build windows` were not run.

## Limitations

- Common Problems management still lives only in Settings.
- No automatic template creation from typed repair text was added.
- No Save as Common Problem action was added.
- No categories, device-type grouping, archive behavior, cloud sync, or static templates were added.
- Search results are simple inline results, not a generic autocomplete framework.

## Next Step

Full focused regression validation for the complete Common Problems feature.
