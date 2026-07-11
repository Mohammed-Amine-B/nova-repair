# Prompt 014 — Shared UI Foundation

## Summary

Implemented the shared Flutter UI foundation for future Nova Repair screens. The app now has focused design tokens, an updated light theme, a fixed desktop sidebar shell, reusable page headers, surface/card primitives, status badges, buttons, form controls, table shell styling, bottom action bar, and confirmation dialog foundation.

No final Dashboard, Repairs List, repair form, settings form, print preview, backup screen, business UI state, fake data, or backend workflow changes were added.

## Previous State Reviewed

Reports `docs/reports/001-project-foundation.md` through `docs/reports/013-local-backup-restore-foundation.md` were read.

Relevant starting state:

- Flutter desktop foundation, Riverpod root, Drift SQLite, and feature-first structure existed.
- Database schema version was `4`.
- Offline repair workflows, shop settings, search/filter logic, ready/delayed logic, printing data, QR generation, and backup/restore foundation existed.
- The app shell used a basic `NavigationRail`.
- Dashboard, Repairs, and Settings were placeholder pages.

The requested UI specification path `design_reference/NOVA_REPAIR_UI_SPEC.md` was checked, but that file is not present in the repository. The Stitch visual references were reviewed from the available `design_reference/stitch/stitch_nova_repair_dashboard_management/` tree.

## Design References Used

Source-of-truth priority from the prompt was followed where files existed:

1. `design_reference/NOVA_REPAIR_UI_SPEC.md` - checked but missing.
2. Approved final screen screenshots.
3. Approved final screen `code.html` files.
4. Stitch design-system document.

Design files inspected:

- `design_reference/stitch/stitch_nova_repair_dashboard_management/nova_repair_design_system/DESIGN.md`
- `design_reference/stitch/stitch_nova_repair_dashboard_management/nova_repair_dashboard_refined/screen.png`
- `design_reference/stitch/stitch_nova_repair_dashboard_management/nova_repair_dashboard_refined/code.html`
- `design_reference/stitch/stitch_nova_repair_dashboard_management/nova_repair_repairs_list_refined/screen.png`
- `design_reference/stitch/stitch_nova_repair_dashboard_management/nova_repair_repairs_list_refined/code.html`
- `design_reference/stitch/stitch_nova_repair_dashboard_management/nova_repair_new_repair_intake/screen.png`
- `design_reference/stitch/stitch_nova_repair_dashboard_management/nova_repair_new_repair_intake/code.html`
- `design_reference/stitch/stitch_nova_repair_dashboard_management/nova_repair_restore_confirmation_dialog/screen.png`
- `design_reference/stitch/stitch_nova_repair_dashboard_management/nova_repair_restore_confirmation_dialog/code.html`
- `design_reference/stitch/stitch_nova_repair_dashboard_management/nova_repair_print_preview_refined/screen.png`
- `design_reference/stitch/stitch_nova_repair_dashboard_management/nova_repair_print_preview_refined/code.html`

Recurring patterns used: 240px fixed left sidebar, soft `#F8FAFC` workspace canvas, white bordered surfaces, compact Manrope-based typography, subtle blue active navigation, restrained 4-8px radii, compact controls, and semantic pill status badges.

## Files Inspected

- `pubspec.yaml`
- `lib/app/app.dart`
- `lib/app/app_shell.dart`
- `lib/app/navigation/app_destination.dart`
- `lib/app/theme/app_theme.dart`
- `lib/features/dashboard/dashboard_page.dart`
- `lib/features/repairs/repairs_page.dart`
- `lib/features/settings/settings_page.dart`
- `lib/features/repairs/domain/repair_status.dart`
- `test/app_shell_test.dart`
- Existing file list under `lib/`, `test/`, `docs/`, and `design_reference/`

## Files Created

- `lib/app/theme/app_colors.dart`
- `lib/app/theme/app_spacing.dart`
- `lib/app/theme/app_radius.dart`
- `lib/app/theme/app_typography.dart`
- `lib/app/widgets/nova_sidebar.dart`
- `lib/app/widgets/page_header.dart`
- `lib/app/widgets/section_card.dart`
- `lib/app/widgets/status_badge.dart`
- `lib/app/widgets/empty_value_text.dart`
- `lib/app/widgets/buttons/app_buttons.dart`
- `lib/app/widgets/form/app_text_field.dart`
- `lib/app/widgets/form/form_section.dart`
- `lib/app/widgets/table/app_table_shell.dart`
- `lib/app/widgets/bottom_action_bar.dart`
- `lib/app/widgets/dialogs/confirmation_dialog.dart`
- `test/app/widgets/shared_ui_foundation_test.dart`
- `docs/reports/014-shared-ui-foundation.md`

## Files Modified

- `lib/app/app_shell.dart`
- `lib/app/theme/app_theme.dart`
- `lib/features/dashboard/dashboard_page.dart`
- `lib/features/repairs/repairs_page.dart`
- `lib/features/settings/settings_page.dart`

## Design Tokens

Colors:

- Canvas: `#F8FAFC`
- Surface: `#FFFFFF`
- Primary: `#2563EB`
- Primary soft: `#EFF6FF`
- Main text: `#1E293B`
- Secondary text: `#64748B`
- Muted text: `#94A3B8`
- Border: `#E2E8F0`
- Soft surface/table header: `#F1F5F9`
- Danger: `#DC2626`

Semantic status colors are centralized in `AppColors.status(RepairStatus)`.

Spacing:

- Central rhythm based on `4`, `8`, `12`, `16`, `20`, `24`, and `32`.
- Sidebar width is `240`.
- Minimum button height is `40`.
- Table row minimum height is `48`.

Radius:

- Controls: `4`
- Small: `6`
- Cards: `8`
- Dialogs: `12`
- Pills: `999`

Typography:

- Centralized in `AppTypography`.
- Font family is set to `Manrope` with fallback fonts `Segoe UI`, `Arial`, and `sans-serif`.
- No local Manrope font asset or existing font package was found, and no runtime internet font dependency was added.
- Scale stays compact: 24px page headings, 20px section titles, 14-16px body text, and 11-12px labels.

## Theme

`AppTheme.light()` now uses the Nova Repair palette directly instead of only deriving from a seed color.

Theme changes include:

- Material 3 remains enabled.
- `AppColors.canvas` is the scaffold background.
- Compact `VisualDensity`.
- Manrope-based text theme with desktop-friendly sizing.
- Shared input decoration with white fill, subtle border, blue focus border, and restrained error styling.
- Primary, secondary, and text button defaults.
- Divider, dialog, and card styling aligned with the approved border-first visual direction.

## Shared App Shell

The app shell now uses one fixed desktop layout:

- `NovaSidebar` at `240px`.
- Fluid main content area.
- Simple internal page switching is preserved.
- Navigation remains exactly Dashboard, Repairs, and Settings.
- No routing package was added.
- No Riverpod UI state provider was added.

## NovaSidebar

`NovaSidebar` supports:

- Required active `AppDestination`.
- Required navigation callback.
- Top identity:
  - `Nova Repair`
  - `Management System`
- Navigation:
  - Dashboard
  - Repairs
  - Settings
- Bottom identity:
  - `TechFix Repair`
  - `Repair Center`

Active state uses a subtle blue background tint, primary blue icon color, bold label, and a compact left active bar.

Intentionally excluded:

- Admin User
- Manager
- avatar
- account/profile controls
- logout
- unrelated navigation items

## PageHeader

`PageHeader` supports:

- required `title`
- required `subtitle`
- optional `actions`

It renders the standard future screen header pattern without hard-coding screen-specific buttons such as New Repair.

## Shared Surfaces

`SectionCard`:

- White surface.
- Subtle border.
- 8px radius.
- Optional title and description.
- Configurable padding.

`AppTableShell` and `AppTableRowShell`:

- White table container.
- Light soft-surface header band.
- Subtle borders and row dividers.
- 48px minimum row height.
- Hover-ready row structure.
- No fake rows or repair data.

`EmptyValueText`:

- Renders `—`.
- Uses muted styling.

## StatusBadge

`StatusBadge` accepts `RepairStatus` and maps all eight statuses to user-facing labels:

- Received
- Diagnosing
- Waiting for Customer Approval
- Waiting for Part
- Repairing
- Ready for Pickup
- Delivered
- Cancelled

Semantic color mapping:

- Received: neutral blue-gray.
- Diagnosing: muted purple.
- Waiting for Customer Approval: amber.
- Waiting for Part: orange.
- Repairing: blue.
- Ready for Pickup: green.
- Delivered: neutral gray.
- Cancelled: red.

The widget does not display database values and does not rely on enum indexes.

## Shared Buttons

Created:

- `PrimaryButton`
- `SecondaryButton`
- `GhostButton`

They support:

- label text
- optional leading icon
- disabled state through `onPressed == null`

No fake loading behavior was added.

## Shared Form Controls

`AppTextField` supports:

- label
- optional helper text
- optional placeholder
- optional suffix
- optional error text
- enabled state
- read-only state
- controller
- `onChanged`

`AppTextArea` supports:

- label
- optional helper text
- placeholder
- optional error text
- enabled state
- read-only state
- configurable minimum lines

`FormSection` wraps `SectionCard` for future New Repair, Edit Repair, and Settings forms.

No repair-specific validation rules were embedded in these widgets.

## BottomActionBar

`BottomActionBar` supports:

- optional left/secondary actions
- optional primary/right actions
- white surface
- top border
- consistent minimum height

It does not hard-code button labels or submit behavior.

## Confirmation Dialog Foundation

`ConfirmationDialog` was created with:

- title
- message
- optional icon
- optional content
- cancel label/action
- confirm label/action
- destructive confirm styling option

No page opens this dialog yet. Restore confirmation behavior remains deferred to its own screen prompt.

## Print Preview Shell Decision

`PrintPreviewShell` was deferred.

The approved print preview screenshots show a useful future layout, but creating it now would require speculative APIs for document mode, printer controls, preview workspace behavior, and print actions. Those should be introduced in the Print Preview implementation prompt.

## Placeholder Pages

Dashboard, Repairs, and Settings placeholders were preserved.

Minimal changes:

- Each placeholder now renders through `PageHeader`.
- Messages remain placeholder-only.

No final dashboard cards, repair list, forms, settings fields, backup UI, print preview, fake data, or screen-specific actions were implemented.

## Architecture Changes

Shared UI files are organized under:

- `lib/app/theme/`
- `lib/app/widgets/`
- `lib/app/widgets/buttons/`
- `lib/app/widgets/form/`
- `lib/app/widgets/table/`
- `lib/app/widgets/dialogs/`

Screen-specific layers intentionally deferred:

- Dashboard controller/provider.
- Repairs List controller/provider.
- Repair creation form controller/provider.
- Status dialog controller/provider.
- Print preview controller/provider.
- Settings form controller/provider.
- Backup/restore screen controller/provider.

## Dependencies

None.

No dependencies were added, removed, or changed.

## Tests Added

- `test/app/widgets/shared_ui_foundation_test.dart`
  - Sidebar identity, navigation, active marker, callback, and excluded account labels.
  - Page header title, subtitle, and optional actions.
  - Status badge labels for all eight repair statuses and no database-value leakage.
  - Empty value marker.
  - Primary, secondary, and disabled button behavior.
  - Text field, text area, read-only state, and form section rendering.
  - Section card and table shell rendering.
  - Bottom action bar rendering.
  - Confirmation dialog rendering and action callbacks.

Existing `test/app_shell_test.dart` continues to cover shell rendering and placeholder navigation.

## Validation Commands

- `dart format .`
- `flutter test test/app/widgets/shared_ui_foundation_test.dart`
- `flutter analyze`
- `flutter test test/app/widgets/shared_ui_foundation_test.dart`
- `flutter test test/app_shell_test.dart`
- `flutter pub get`
- `flutter test`
- `flutter build windows`
- `git status --short`

## Validation Results

Dependency resolution: succeeded. `flutter pub get` completed successfully. Flutter reported that 12 packages have newer versions incompatible with current constraints.

Formatting: succeeded. `dart format .` completed successfully.

Static analysis: succeeded. `flutter analyze` reported no issues.

Focused tests: succeeded. `flutter test test/app/widgets/shared_ui_foundation_test.dart` passed all shared UI foundation tests.

Shell smoke tests: succeeded. `flutter test test/app_shell_test.dart` passed.

All tests: succeeded. `flutter test` passed all tests.

Windows build: attempted but not executed successfully because the current host is not Windows. Flutter returned: `"build windows" only supported on Windows hosts.`

Repository status check: `git status --short` failed because the working directory did not appear to be a Git repository.

Code generation: not run because no Drift schema or generated-code inputs changed.

## Issues or Limitations

- `design_reference/NOVA_REPAIR_UI_SPEC.md` is missing from the repository, so the available Stitch screenshots, HTML references, and design-system document were used.
- Windows build validation remains blocked by the current non-Windows environment.
- The working directory did not appear to be a Git repository when `git status --short` was attempted.
- Manrope is referenced in theme typography, but no local Manrope font asset or existing font package was present. Runtime internet font loading was intentionally not added.
- No mobile, tablet, collapsible sidebar, or responsive navigation behavior was implemented.
- No Dashboard content, Repairs List, forms, dialogs opened from pages, Print Preview shell, screen-specific state, fake data, or business workflow changes were implemented.

## Next Safe Step

The next safe development step is Dashboard UI implementation using the approved Stitch reference and existing real query logic.
