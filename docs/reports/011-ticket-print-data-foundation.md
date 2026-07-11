# Prompt 011 — Ticket and Print Data Foundation

## Summary

Implemented the ticket and print data foundation as a focused `printing` feature. The app now has immutable print-ready data models for customer tickets and device labels, a small repair print-data wrapper, deterministic device display-name formatting, a builder/use case that maps current `Repair` and `ShopSettings` domain data, warranty display handling, and meaningful tests.

No UI, Print Preview, PDF generation, printer integration, printer discovery, QR generation, tracking URL generation, online tracking, schema changes, print tables, or sample data were added.

## Previous State Reviewed

Reports `docs/reports/001-project-foundation.md` through `docs/reports/010-ready-delayed-repair-logic.md` were read.

Relevant starting state:

- Flutter desktop foundation, Riverpod root, and desktop app shell existed.
- Drift schema version was `4`.
- Repair creation, global repair code sequence, shop settings, repair queries, status workflow, price workflow, warranty return workflow, search/filter logic, ready-for-pickup logic, delayed repair logic, and attention counts existed.
- There were no ticket data models, print models, print-data builder, PDF generation, printer integration, Print Preview UI, QR generation, backup/restore, or online functionality.

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
- Attached Prompt 011 request text
- `lib/database/app_database.dart`
- `lib/features/repairs/domain/entities/repair.dart`
- `lib/features/repairs/domain/entities/create_repair_input.dart`
- `lib/features/repairs/domain/customer_price_decision.dart`
- `lib/features/repairs/domain/errors/repair_status_workflow_exception.dart`
- `lib/features/repairs/domain/repositories/repair_repository.dart`
- `lib/features/repairs/repair_providers.dart`
- `lib/features/settings/domain/entities/shop_settings.dart`
- `lib/features/settings/domain/repositories/shop_settings_repository.dart`
- `lib/features/settings/data/repositories/drift_shop_settings_repository.dart`
- `lib/features/settings/settings_providers.dart`
- `test/features/settings/data/shop_settings_persistence_test.dart`
- `test/features/repairs/data/repair_price_workflow_test.dart`
- Existing file list under `lib/features/` and `test/features/`

## Files Created

- `lib/features/printing/domain/entities/customer_ticket_data.dart`
- `lib/features/printing/domain/entities/device_label_data.dart`
- `lib/features/printing/domain/entities/repair_print_data.dart`
- `lib/features/printing/application/device_display_name_formatter.dart`
- `lib/features/printing/application/build_repair_print_data_use_case.dart`
- `lib/features/printing/printing_providers.dart`
- `test/features/printing/application/build_repair_print_data_use_case_test.dart`
- `docs/reports/011-ticket-print-data-foundation.md`

## Files Modified

None.

Existing files were not modified during this task.

## Printing Feature Structure

The chosen feature name is `printing` because the foundation supports both customer tickets and device labels, and can later grow to contain PDF or printer-specific behavior without being tied only to tickets.

Created structure:

- `lib/features/printing/domain/entities/`
  - immutable print data models
- `lib/features/printing/application/`
  - print-data builder/use case and device display-name formatter
- `lib/features/printing/printing_providers.dart`
  - Riverpod provider for the builder/use case

No UI, presentation state, PDF services, printer services, layout widgets, or platform channels were created.

## Customer Ticket Data

`CustomerTicketData` exposes:

- `shopName`
- `shopPhone`
- `shopAddress`
- `logoPath`
- `ticketFooter`
- `warrantyTerms`
- `repairCode`
- `receivedAt`
- `status`
- `customerName`
- `customerPhone`
- `deviceDisplayName`
- `reportedProblem`
- `receivedAccessories`
- `priceAmount`
- `customerPriceDecision`
- `isWarrantyReturn`
- `originalRepairCode`

Sensitive fields intentionally excluded:

- `deviceAccessInfo`
- `internalNotes`

Other fields intentionally excluded:

- `customerMessage`, because status/customer messaging will be handled separately from ticket foundation.
- QR/tracking fields, because no QR payload or online tracking behavior exists yet.

## Device Label Data

`DeviceLabelData` exposes:

- `repairCode`
- `receivedAt`
- `deviceDisplayName`
- `customerName`
- `customerPhone`
- `reportedProblem`

Fields intentionally excluded:

- `priceAmount`
- `customerPriceDecision`
- `internalNotes`
- `customerMessage`
- `warrantyTerms`
- `ticketFooter`
- `deviceAccessInfo`
- `shopAddress`
- `receivedAccessories`
- warranty relationship fields

The label keeps `reportedProblem` as raw text. No visual truncation is performed in the builder; future rendering can decide how compact the printed label should be.

## Device Display Name Rules

`DeviceDisplayNameFormatter` applies this deterministic priority:

1. `brand + model` when both exist.
2. `brand + deviceType` when brand and device type exist but model is missing.
3. `model` when only model exists.
4. `deviceType` when only device type exists.
5. fallback: `Device`.

Duplicate-prefix avoidance:

- If the second value already equals the brand or starts with the brand followed by a space, the formatter returns the second value alone.
- Example: `brand = Samsung`, `model = Samsung Galaxy S23` becomes `Samsung Galaxy S23`, not `Samsung Samsung Galaxy S23`.
- The same rule applies to `brand + deviceType`.

Inputs are trimmed and blank values are treated as missing.

## Warranty Display Behavior

Normal repair:

- `isWarrantyReturn = false`
- `originalRepairCode = null`

Warranty return with existing parent:

- `isWarrantyReturn = true`
- `originalRepairCode = parent.repairCode`

Warranty return with missing parent due to inconsistent legacy data:

- `isWarrantyReturn = true`
- `originalRepairCode = null`
- The builder does not crash the entire print-data build.

## Ticket Data Builder

`BuildRepairPrintDataUseCase` workflow:

1. Load the repair by ID through `RepairRepository`.
2. Throw `RepairNotFoundException` if the repair does not exist.
3. Load real persisted shop settings through `ShopSettingsRepository`.
4. If `repair.parentRepairId` exists, attempt to load the original repair through `RepairRepository`.
5. Build a deterministic `deviceDisplayName`.
6. Build `CustomerTicketData`.
7. Build `DeviceLabelData`.
8. Return both in `RepairPrintData`.

The builder does not read Drift rows directly and does not depend on widgets or UI state.

## Data Freshness

Print data is built on demand from the current repair repository and current shop settings repository.

No ticket data is cached or stored in SQLite. A test confirms that changing a repair status and then building print data returns the updated status.

## QR Placeholder Decision

No QR or tracking field was added.

Prompt 012 can extend the print data model when a real QR payload or tracking integration exists. This avoids carrying a permanently-null placeholder before there is a concrete tracking contract.

## Architecture Changes

Models:

- `CustomerTicketData`
- `DeviceLabelData`
- `RepairPrintData`

Builder/use case:

- `BuildRepairPrintDataUseCase`

Formatter:

- `DeviceDisplayNameFormatter`

Repository dependencies:

- `RepairRepository`
- `ShopSettingsRepository`

Riverpod provider:

- `buildRepairPrintDataUseCaseProvider`

Intentionally deferred rendering and printer layers:

- No Print Preview UI.
- No PDF generation service.
- No printer discovery.
- No printer provider.
- No selected printer state.
- No layout widgets.
- No platform channels.
- No QR generation.

## Database Schema

Schema version remains `4`.

No schema change was required because print data is derived from current repairs and shop settings. No print tables were added, and generated ticket data is not stored in SQLite.

## Dependencies

None.

No dependencies were added, removed, or changed.

## Tests Added

- `test/features/printing/application/build_repair_print_data_use_case_test.dart`
  - Customer ticket uses shop name, phone, address, logo path, footer, and warranty terms from settings.
  - Customer ticket includes repair code, received time, status, customer information, device display name, reported problem, accessories, price, and customer price decision.
  - Customer ticket excludes internal notes, device access information, and customer message.
  - Device label includes repair code, received time, device display name, customer information, and reported problem.
  - Device label excludes sensitive fields, price, and customer message.
  - Device display-name rules cover brand plus model, brand plus device type, model only, device type only, fallback, and duplicate-prefix avoidance.
  - Normal repair is not marked as warranty.
  - Warranty return is marked and includes original repair code.
  - Missing warranty parent still builds print data with `originalRepairCode = null`.
  - Missing repair throws `RepairNotFoundException`.
  - Default settings are used when shop settings have not been customized.
  - Print data reflects current repair status after a status update.

## Validation Commands

- `dart format .`
- `flutter analyze`
- `flutter test`
- `flutter pub get`
- `flutter build windows`

## Validation Results

Dependency resolution: succeeded. `flutter pub get` completed successfully. Flutter reported that 12 packages have newer versions incompatible with current constraints.

Code generation: not run because no Drift schema or generated-code inputs changed.

Formatting: succeeded. `dart format .` completed successfully.

Static analysis: initially failed due to a Drift/test `isNull` import ambiguity and collection null-handling lints in the new test file. After fixing the import and string-collector helpers, `flutter analyze` reported no issues.

Tests: succeeded. `flutter test` passed all tests.

Windows build: attempted but not executed successfully because the current host is not Windows. Flutter returned: `"build windows" only supported on Windows hosts.`

## Issues or Limitations

- Windows build validation remains blocked by the current non-Windows environment.
- No PDF generation was implemented.
- No Print Preview UI was implemented.
- No printer integration or printer discovery was implemented.
- No QR generation, QR payload, tracking URL, online tracking, backup/restore, deletion, reports, analytics, or sample data were implemented.
- Date values remain raw UTC `DateTime` values for future renderers to format.
- Price remains raw integer DZD data for future renderers to format.
- Status and customer price decision remain domain enum values; no localization or print wording layer was added.

## Next Safe Step

The next safe development step is QR generation foundation.
