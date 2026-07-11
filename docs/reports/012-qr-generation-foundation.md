# Prompt 012 — QR Generation Foundation

## Summary

Implemented a reusable QR generation foundation for the printing feature. The app can now convert arbitrary non-empty text payloads into deterministic SVG QR output in memory through a focused `QrCodeGenerator` service.

No online tracking, tracking URL generation, tracking tokens, network calls, UI, Print Preview, PDF generation, printer integration, QR file persistence, database schema changes, QR tables, or sample business data were added.

## Previous State Reviewed

Reports `docs/reports/001-project-foundation.md` through `docs/reports/011-ticket-print-data-foundation.md` were read.

Relevant starting state:

- Flutter desktop foundation, Riverpod root, and desktop app shell existed.
- Drift schema version was `4`.
- Repair workflows, shop settings, search/filter logic, ready/delayed logic, attention counts, and warranty behavior existed.
- The `printing` feature already contained `CustomerTicketData`, `DeviceLabelData`, `RepairPrintData`, and `BuildRepairPrintDataUseCase`.
- Print data models intentionally had no QR or tracking fields.
- There was no QR generation, tracking payload contract, tracking URL generation, online tracking, PDF generation, printer integration, or Print Preview UI.

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
- Attached Prompt 012 request text
- `pubspec.yaml`
- `lib/features/printing/application/build_repair_print_data_use_case.dart`
- `lib/features/printing/application/device_display_name_formatter.dart`
- `lib/features/printing/domain/entities/customer_ticket_data.dart`
- `lib/features/printing/domain/entities/device_label_data.dart`
- `lib/features/printing/domain/entities/repair_print_data.dart`
- `lib/features/printing/printing_providers.dart`
- Existing files under `lib/features/printing/` and `test/features/printing/`
- Local `qr` package API files after dependency installation

## Files Created

- `lib/features/printing/infrastructure/qr/qr_code_request.dart`
- `lib/features/printing/infrastructure/qr/qr_code_svg.dart`
- `lib/features/printing/infrastructure/qr/qr_code_generator.dart`
- `test/features/printing/infrastructure/qr/qr_code_generator_test.dart`
- `docs/reports/012-qr-generation-foundation.md`

## Files Modified

- `lib/features/printing/printing_providers.dart`
- `pubspec.yaml`
- `pubspec.lock`

## QR Dependency Decision

Package selected:

- `qr`

Why:

- It is a focused pure-Dart QR package.
- It supports non-widget QR matrix generation through `QrCode` and `QrImage`.
- It works without Flutter rendering, file I/O, network access, or platform channels.
- It lets this prompt add one small dependency instead of combining widget, image, or barcode packages.

Output format:

- SVG string.

Why SVG:

- Deterministic and easy to test.
- Does not require widget rendering.
- Does not require adding an image/raster dependency.
- Suitable as a future input for Print Preview, PDF rendering, or temporary display once those layers exist.

## Payload Behavior

Validation:

- Payload must not be blank after trimming.
- Blank and whitespace-only payloads throw `ArgumentError`.

Whitespace normalization:

- Surrounding whitespace is trimmed before encoding.
- Internal whitespace is preserved exactly.

Unicode support:

- Payloads are passed to `QrPayload.fromString`.
- Tests cover Arabic text, French accented text, numbers, and symbols.

The generator does not interpret payload meaning. It accepts arbitrary text such as a repair code or a URL-like string.

## QR Output

Output format:

- `QrCodeSvg` containing:
  - normalized `payload`
  - requested `size`
  - generated SVG string

Size behavior:

- `QrCodeRequest.size` must be positive.
- The generated SVG uses the requested value for `width` and `height`.
- The QR module path remains the same for the same payload when only rendered size changes.

Error-correction choice:

- `QrErrorCorrectLevel.quartile`
- This is QR level Q, approximately 25% recovery, chosen as a practical default for printed tickets without exposing low-level tuning.

Quiet-zone behavior:

- The SVG viewBox includes a 4-module quiet zone around the QR matrix.
- The quiet zone is implemented by offsetting all dark modules by 4 and increasing the viewBox by 8 modules total.

Determinism:

- The same payload and size produce the same SVG.
- Different payloads produce different SVG.
- No timestamps, random data, or environment values are included.

## QR Generation Service

Service:

- `QrCodeGenerator`

API:

- `generateSvg(QrCodeRequest request) -> QrCodeSvg`

Responsibility:

- Validate request through `QrCodeRequest`.
- Generate a QR matrix from the normalized text payload.
- Render that matrix as an in-memory SVG string.

The service does not depend on repair repositories, shop settings, printing layout, PDF generation, widgets, files, or network access.

## Print Integration Decision

Existing print data models were left unchanged.

Future rendering can combine:

- `RepairPrintData`
- a future real tracking payload
- `QrCodeGenerator`

This keeps the offline print data foundation independent from unfinished online tracking behavior.

## Online Tracking Boundary

No tracking URL was invented.

No tracking token was created.

No shop slug, public tracking domain, Supabase integration, Cloudflare integration, network call, or online tracking behavior was added.

The URL-like payload in tests uses `https://example.test/track/demo-token` only as generic QR input test data.

## Architecture Changes

Service location:

- `lib/features/printing/infrastructure/qr/`

This location was chosen because QR generation primarily supports future printed customer tickets while remaining separate from print data models and layout.

Provider:

- `qrCodeGeneratorProvider`

Dependencies:

- Added `qr`.

Intentionally deferred layers:

- No QR widget state.
- No selected QR size state.
- No tracking URL provider.
- No online tracking provider.
- No Print Preview UI.
- No PDF renderer.
- No printer service.
- No printer discovery.
- No file persistence.

## Database Schema

Schema version remains `4`.

QR generation requires no database schema change. No QR table was added, and generated QR SVG output is not stored in SQLite.

## Dependencies

Added:

- `qr`: pure-Dart QR matrix generation used by `QrCodeGenerator` to produce deterministic SVG output without widget rendering or platform integration.

Removed: none.

Changed:

- `pubspec.lock` was updated by dependency resolution.

## Tests Added

- `test/features/printing/infrastructure/qr/qr_code_generator_test.dart`
  - Normal payload succeeds.
  - Surrounding whitespace is trimmed.
  - Internal whitespace is preserved.
  - Blank payload is rejected.
  - Whitespace-only payload is rejected.
  - Normal size succeeds.
  - Zero and negative sizes are rejected.
  - SVG output is non-empty and structurally valid for the chosen format.
  - Same payload and configuration produce deterministic output.
  - Different payloads produce different output.
  - Different sizes change SVG dimensions while preserving QR module path.
  - Unicode payloads work.
  - URL-like payloads work without creating a tracking contract.
  - A reasonably long payload works.
  - Quiet-zone and error-correction defaults are stable.

Optional decode validation was not added because that would require adding a second QR package only for testing.

## Validation Commands

- `flutter pub add qr`
- `dart format .`
- `flutter analyze`
- `flutter test`
- `flutter pub get`
- `flutter build windows`

## Validation Results

Dependency resolution: succeeded. `flutter pub add qr` added `qr 4.0.0`. `flutter pub get` completed successfully. Flutter reported that 12 packages have newer versions incompatible with current constraints.

Formatting: succeeded. `dart format .` completed successfully.

Static analysis: succeeded. `flutter analyze` reported no issues.

Tests: succeeded. `flutter test` passed all tests.

Windows build: attempted but not executed successfully because the current host is not Windows. Flutter returned: `"build windows" only supported on Windows hosts.`

## Issues or Limitations

- Windows build validation remains blocked by the current non-Windows environment.
- QR decoding is not tested because adding a second QR package only for decoding was not justified.
- Payload capacity is limited by the QR standard and the selected error-correction level; the `qr` package throws when payloads exceed QR version 40 capacity.
- No QR PNG output was added; SVG was chosen for deterministic non-widget generation.
- No tracking URL, tracking token, online tracking, PDF generation, printer integration, Print Preview UI, file persistence, or QR embedding into tickets was implemented.

## Next Safe Step

The next safe development step is local backup and restore foundation.
