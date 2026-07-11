# Prompt 034 — Flexible Repair Status Workflow

## Summary

Changed the repair status workflow so technicians can move any existing repair from its current status to any other repair status. The only invalid target is the current status itself.

No status history table, schema change, broad Repair Details redesign, customer price decision UI, Warranty Return UI, or unrelated workflow change was added.

## Relevant Previous State

Reviewed:

- `docs/reports/006-repair-status-workflow.md`
- `docs/reports/018-repair-details-ui.md`
- `docs/reports/019-change-status-dialog.md`
- `docs/reports/021-edit-repair-ui.md`
- `docs/reports/033-common-problems-regression-validation.md`
- `design_reference/NOVA_REPAIR_UI_SPEC.md`

Starting state:

- `RepairStatusTransitionPolicy` used an ordered transition graph.
- `delivered` and `cancelled` had no outgoing transitions.
- Leaving `readyForPickup` back to `repairing` cleared `readyAt`.
- Change Status dialog showed all statuses but disabled targets not allowed by the ordered graph.

## New Transition Rule

The status policy now allows:

```text
current status -> any different status
```

Same-status transitions remain invalid.

The policy is still the shared source of truth for the repository and Change Status dialog.

## Final Status Reopening

`delivered` and `cancelled` are no longer immutable final workflow endpoints.

Examples now allowed:

- `delivered -> repairing`
- `cancelled -> diagnosing`
- `received -> repairing`
- `waitingForPart -> readyForPickup`

Status counts, active counts, Repairs List, and Dashboard derive from the repair's current status, so reopened repairs appear under their new active status.

## readyAt Semantics

Entering `readyForPickup` sets `readyAt` to the current backend UTC time.

Leaving `readyForPickup` no longer clears `readyAt`. The stored value remains the latest persisted evidence that the repair became ready.

If the repair later re-enters `readyForPickup`, `readyAt` is overwritten with the new backend UTC time.

## deliveredAt Semantics

Entering `delivered` sets `deliveredAt` to the current backend UTC time.

Leaving `delivered` does not clear `deliveredAt`. The stored value remains the latest persisted delivery evidence.

If the repair later re-enters `delivered`, `deliveredAt` is overwritten with the new backend UTC time.

## Change Status Dialog

The existing dialog design was preserved.

The dialog still shows all eight statuses:

- current status is marked `Current` and disabled
- all seven other statuses are selectable

Customer message behavior remains unchanged:

- untouched preserves the current message
- edited nonblank replaces it
- blank clears it

## Downstream Compatibility

Validated compatibility with:

- Repair Details refresh after status change
- Repairs List showing the new status
- Dashboard status/active counts refreshing after a status change
- reopened delivered/cancelled repairs becoming active again
- ready/delivered timestamp display continuing to use persisted milestone timestamps

No search/filter semantics were changed.

## Database Schema

Schema version remains `6`.

No tables, columns, indexes, migrations, generated Drift files, status history table, status event table, `reopenedAt`, or extra lifecycle timestamp columns were added.

## Tests Run

- `dart format lib/features/repairs/domain/services/repair_status_transition_policy.dart lib/features/repairs/data/repositories/drift_repair_repository.dart test/features/repairs/domain/repair_status_transition_policy_test.dart test/features/repairs/data/repair_status_workflow_test.dart test/features/repairs/change_status_dialog_test.dart`
- `flutter analyze`
- `flutter test test/features/repairs/data/repair_status_workflow_test.dart`
- `flutter test test/features/repairs/change_status_dialog_test.dart`
- `flutter test test/features/repairs/repair_details_test.dart`
- `flutter test test/features/repairs/repairs_list_test.dart`
- `flutter test test/features/dashboard/dashboard_test.dart`
- `flutter test test/features/repairs/domain/repair_status_transition_policy_test.dart`

## Validation Results

Formatting: passed.

Static analysis: passed with no issues. Flutter emitted a git object-database warning before analysis, but analyzer completed successfully.

Focused status workflow tests: passed.

Change Status dialog tests: passed.

Repair Details tests: passed.

Repairs List tests: passed.

Dashboard tests: passed.

Transition policy tests: passed.

Per Prompt 034, full `flutter test` and `flutter build windows` were not run.

## Limitations

- There is still no full status history table, so only `readyAt` and `deliveredAt` milestone timestamps are persisted.
- Preserved `readyAt` and `deliveredAt` values are historical milestone evidence, not proof of current status.
- Customer price decision workflow remains separate and unchanged.
- Warranty Return behavior remains separate and unchanged.
- Physical Windows build validation was not performed in this prompt.

## Next Step

The next safe step is whichever focused product workflow is next on the roadmap; a future status-history feature can be considered separately if audit-level history becomes necessary.
