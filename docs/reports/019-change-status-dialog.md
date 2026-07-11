# Prompt 019 — Change Status Dialog

## Summary

Implemented the approved Change Status dialog and wired it to the existing safe repair status workflow. Repair Details now opens a centered modal that shows the current repair context, all eight statuses, valid and invalid transition availability, a customer message field, submission state, inline errors, and refreshes Repair Details, Repairs List, and Dashboard after successful status changes.

No Edit Repair UI, Print Preview, Create Warranty Return UI, customer price decision UI, Settings UI, Backup UI, schema changes, dependency changes, or backend workflow changes were added.

## Previous State Reviewed

Reports `docs/reports/001-project-foundation.md` through `docs/reports/018-repair-details-ui.md` were read.

Relevant starting state:

- Repair Details existed with an `onChangeStatus(Repair repair)` callback boundary.
- `ChangeRepairStatusUseCase` and `RepairStatusTransitionPolicy` already existed.
- The backend already owned valid transition rules, `readyAt`, `deliveredAt`, ready timestamp clearing, and customer-message preserve/update/clear semantics.
- Shared buttons, status badges, form fields, dialog visual conventions, app shell navigation, Dashboard, Repairs List, and Repair Details provider invalidation patterns existed.

The UI specification and approved Change Status Stitch references were reviewed.

## Design References Used

- `design_reference/NOVA_REPAIR_UI_SPEC.md`
- `design_reference/stitch/stitch_nova_repair_dashboard_management/nova_repair_change_status_dialog_refined/screen.png`
- `design_reference/stitch/stitch_nova_repair_dashboard_management/nova_repair_change_status_dialog_refined/code.html`
- `design_reference/stitch/stitch_nova_repair_dashboard_management/nova_repair_design_system/DESIGN.md`

`screen.png` was treated as the strongest visual reference, with `code.html` used only as supporting layout reference.

## Files Inspected

- `docs/reports/001-project-foundation.md`
- `docs/reports/002-repair-domain-database.md`
- `docs/reports/003-shop-settings-foundation.md`
- `docs/reports/004-repair-creation-workflow.md`
- `docs/reports/005-repair-query-foundation.md`
- `docs/reports/006-repair-status-workflow.md`
- `docs/reports/007-customer-price-approval-workflow.md`
- `docs/reports/008-warranty-return-workflow.md`
- `docs/reports/009-repair-search-filter-logic.md`
- `docs/reports/010-ready-delayed-repair-logic.md`
- `docs/reports/011-ticket-print-data-foundation.md`
- `docs/reports/012-qr-generation-foundation.md`
- `docs/reports/013-local-backup-restore-foundation.md`
- `docs/reports/014-shared-ui-foundation.md`
- `docs/reports/015-dashboard-ui.md`
- `docs/reports/016-repairs-list-ui.md`
- `docs/reports/017-new-repair-ui.md`
- `docs/reports/018-repair-details-ui.md`
- Attached Prompt 019 request text
- `design_reference/NOVA_REPAIR_UI_SPEC.md`
- `design_reference/stitch/stitch_nova_repair_dashboard_management/nova_repair_change_status_dialog_refined/screen.png`
- `design_reference/stitch/stitch_nova_repair_dashboard_management/nova_repair_change_status_dialog_refined/code.html`
- `design_reference/stitch/stitch_nova_repair_dashboard_management/nova_repair_design_system/DESIGN.md`
- `lib/app/app_shell.dart`
- `lib/app/widgets/dialogs/confirmation_dialog.dart`
- `lib/app/widgets/buttons/app_buttons.dart`
- `lib/app/widgets/form/app_text_field.dart`
- `lib/app/widgets/status_badge.dart`
- `lib/app/theme/app_colors.dart`
- `lib/features/repairs/repair_details_page.dart`
- `lib/features/repairs/domain/entities/change_repair_status_input.dart`
- `lib/features/repairs/application/change_repair_status_use_case.dart`
- `lib/features/repairs/domain/services/repair_status_transition_policy.dart`
- `lib/features/repairs/data/repositories/drift_repair_repository.dart`
- `test/features/repairs/data/repair_status_workflow_test.dart`
- `test/features/repairs/repair_details_test.dart`

## Files Created

- `lib/features/repairs/change_status_dialog.dart`
- `lib/features/repairs/presentation/change_status_dialog_controller.dart`
- `lib/features/repairs/presentation/change_status_dialog_state.dart`
- `lib/features/repairs/presentation/repair_status_option_presentation.dart`
- `test/features/repairs/change_status_dialog_test.dart`
- `docs/reports/019-change-status-dialog.md`

## Files Modified

- `lib/app/app_shell.dart`

## Dialog Layout

The dialog is a centered modal over the real Repair Details screen.

Layout:

- Approximate max width: `560`
- Dark scrim
- White dialog surface
- Restrained radius
- Subtle shadow
- Header with title, real repair subtitle, and close action
- Current status panel with shared `StatusBadge`
- Scrollable status list
- Customer Message text area
- Footer with Cancel and Update Status

The dialog is not a full-screen page and does not add decorative animation.

## Status Descriptions

Status descriptions are centralized in `repair_status_option_presentation.dart`.

Descriptions:

- Received: `Device has been received by the repair shop`
- Diagnosing: `Device is being inspected and diagnosed`
- Waiting for Customer Approval: `Waiting for the customer to approve the proposed price`
- Waiting for Part: `Repair is paused while waiting for a required part`
- Repairing: `Repair work is currently in progress`
- Ready for Pickup: `Repair is complete and the device is ready for collection`
- Delivered: `Device has been returned to the customer`
- Cancelled: `Repair job has been cancelled`

## Transition Availability

The dialog uses the existing `RepairStatusTransitionPolicy`.

Valid targets are selectable.

Invalid targets remain visible but disabled.

The current status is disabled.

The backend `ChangeRepairStatusUseCase` and repository remain authoritative during submission. The UI does not duplicate or alter the transition matrix.

## Current Status

The current status is shown in the Current Status panel and marked `Current` in the status list.

Same-status transitions are not selectable and cannot enable the Update Status action.

## Selected Status

Selected valid targets show:

- soft semantic status background
- semantic border color
- check icon
- semantic text color

The selected styling uses the existing shared status color system through `AppColors.status`.

## Customer Message

The dialog uses the repair's current `customerMessage` as the initial text.

Semantics:

- Untouched field: sends `OptionalCustomerMessage.unchanged()` and preserves the stored message.
- Edited nonblank field: sends `OptionalCustomerMessage.replace(value)` and the backend trims it.
- Cleared or blank field: sends `OptionalCustomerMessage.replace(blank)` and the backend clears the stored message.

No SMS, WhatsApp, email, or notification controls were added.

## Dialog State

Added:

- `ChangeStatusDialogState`
- `ChangeStatusDialogController`
- `changeStatusDialogControllerProvider`

State tracks:

- current repair
- selected target status
- customer message text
- whether customer message was changed
- submission progress
- submission error

No generic dialog framework was created.

## Submission Workflow

Submission flow:

1. User selects a valid target status.
2. User optionally edits the customer message.
3. Controller builds `ChangeRepairStatusInput`.
4. Controller calls `ChangeRepairStatusUseCase`.
5. On success, dialog returns the updated `Repair` and closes.
6. On failure, dialog stays open and shows a calm inline error.

No low-level data source is called by the dialog.

No optimistic UI update is performed before the use case succeeds.

## Timestamp Behavior

Ready and delivered timestamps remain backend-owned.

The dialog does not set:

- `readyAt`
- `deliveredAt`
- `updatedAt`

Existing backend behavior is preserved:

- Entering `readyForPickup` sets `readyAt`.
- Returning from `readyForPickup` to `repairing` clears `readyAt`.
- Entering `delivered` sets `deliveredAt`.

## Refresh Integration

After a successful status change, the app shell invalidates:

- `repairDetailsControllerProvider(repairId)`
- `repairsListControllerProvider`
- `dashboardControllerProvider`

This refreshes:

- Repair Details status and timeline
- Repairs List status display
- Dashboard counts

No event bus, polling, or app-shell reconstruction was added.

## Final Status Behavior

For repairs currently in `delivered` or `cancelled`:

- The dialog can still open.
- Current status is shown.
- All targets remain visible but disabled.
- Update Status stays disabled.
- The dialog does not crash or silently close.

## Error State

Invalid transition failures show:

`This status change is no longer allowed. Refresh and try again.`

General failures show:

`Status could not be updated. Please try again.`

The dialog preserves selected status and customer message input after failure. Raw exceptions, stack traces, SQL details, and internal error types are not shown.

## Navigation / Dialog Integration

Repair Details now opens the dialog through the existing `onChangeStatus(Repair repair)` boundary.

Flow:

- Repair Details → Change Status → dialog
- Cancel closes the dialog and returns to Repair Details
- Successful Update Status closes the dialog and refreshes Repair Details

No routing package was added.

## Shared Widgets Reused

Reused:

- `StatusBadge`
- `AppTextArea`
- `PrimaryButton`
- `GhostButton`

The existing `ConfirmationDialog` was inspected but not used because the approved dialog needs richer status selection, current-state display, customer-message editing, and inline submission errors.

## Architecture Changes

Added feature-local presentation files only.

No new repository was created.

No fake use case was added.

No backend workflow or transition matrix was changed.

## Database Schema

Schema version remains `4`.

No tables, columns, indexes, migrations, or generated Drift files were changed.

## Dependencies

None.

No dependencies were added, removed, or changed.

## Tests Added

- `test/features/repairs/change_status_dialog_test.dart`
  - Dialog title, real repair code, real device display name, current status, all eight statuses, exact descriptions, current marker, customer message field, Cancel, and Update Status render.
  - Current status and invalid targets are disabled.
  - Valid targets can be selected.
  - Selected status shows selected-state behavior.
  - Representative transition availability is tested for Received, Repairing, Ready for Pickup, Delivered, and Cancelled.
  - Update Status is disabled with no selection.
  - Duplicate submission is prevented.
  - Successful submit uses the real use case and closes the dialog.
  - Failure keeps the dialog open with a calm inline error.
  - Untouched customer message is preserved.
  - Edited customer message is trimmed and stored.
  - Cleared customer message removes stored value.
  - Repairing → Ready for Pickup sets `readyAt`.
  - Ready for Pickup → Repairing clears `readyAt`.
  - Ready for Pickup → Delivered sets `deliveredAt`.
  - Successful status change refreshes Repair Details, Repairs List, and Dashboard.

Existing affected tests were also run:

- `test/features/repairs/repair_details_test.dart`
- `test/app_shell_test.dart`
- `test/features/repairs/data/repair_status_workflow_test.dart`

## Validation Commands

- `dart format .`
- `flutter analyze`
- `flutter test test/features/repairs/change_status_dialog_test.dart`
- `dart format test/features/repairs/change_status_dialog_test.dart`
- `flutter test test/features/repairs/change_status_dialog_test.dart`
- `flutter analyze`
- `flutter test test/features/repairs/repair_details_test.dart`
- `flutter test test/app_shell_test.dart`
- `flutter test test/features/repairs/data/repair_status_workflow_test.dart`
- `flutter pub get`
- `flutter test`
- `flutter build windows`
- `git status --short`

## Validation Results

Dependency resolution: succeeded. `flutter pub get` completed successfully. Flutter reported that 12 packages have newer versions incompatible with current constraints.

Code generation: not run because no Drift schema or generated-code inputs changed.

Formatting: succeeded. `dart format .` completed successfully.

Static analysis: initially failed because the first controller version used an unsupported Riverpod family notifier class and the new test had a few local helper issues. After switching to the supported constructor-argument family notifier pattern and fixing test helpers, `flutter analyze` reported no issues.

Focused Change Status tests: initially failed because lower status options were inside the dialog scroll area and direct test taps missed them. After adding a scroll-aware status tap helper and adjusting an over-specific assertion, `flutter test test/features/repairs/change_status_dialog_test.dart` passed.

Affected tests:

- `flutter test test/features/repairs/repair_details_test.dart` passed.
- `flutter test test/app_shell_test.dart` passed.
- `flutter test test/features/repairs/data/repair_status_workflow_test.dart` passed.

All tests: `flutter test` passed all tests.

Windows build: attempted but not executed successfully because the current host is not Windows. Flutter returned: `"build windows" only supported on Windows hosts.`

Repository status check: `git status --short` failed because the working directory did not appear to be a Git repository.

## Issues or Limitations

- Windows build validation remains blocked by the current non-Windows environment.
- The working directory did not appear to be a Git repository when `git status --short` was attempted.
- The dialog scrolls when all statuses plus the message field exceed available height.
- Edit Repair UI is deferred.
- Print Preview is deferred.
- Create Warranty Return UI is deferred.
- Customer price decision interaction remains deferred.
- No transition-policy extraction was required because `RepairStatusTransitionPolicy` already existed and is reused directly.

## Next Safe Step

The next safe step is Edit Repair UI implementation using the approved shared repair form structure and a real repair-update workflow.

If no safe repair-update workflow exists yet, that workflow should be added first instead of inventing unrestricted UI updates.
