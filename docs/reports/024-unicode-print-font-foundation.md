# Prompt 024 — Unicode Print Font Foundation

## Summary

Implemented the Unicode print font foundation for real printable PDF documents. Customer ticket and device label PDFs now use bundled offline Noto fonts instead of the PDF package's built-in Helvetica fonts, with Latin/French text handled by Noto Sans and Arabic text handled through Noto Sans Arabic fallback fonts. The renderer now loads fonts from Flutter assets through a small cached print-font provider and applies those fonts to all printable text.

No new screen, Print Preview redesign, Settings UI, Backup UI, printer discovery change, PDF export, Save as PDF, QR semantic change, database change, or package dependency change was added.

## Previous State Reviewed

Reports `docs/reports/001-project-foundation.md` through `docs/reports/023-windows-printer-integration-foundation.md` were read.

Relevant starting state:

- Print Preview and Windows printer integration foundation existed.
- `RepairPdfDocumentRenderer` rendered customer tickets and device labels as in-memory PDF print documents.
- The renderer relied on default PDF fonts.
- Prompt 023 validation reported PDF-package Unicode support warnings from the built-in Helvetica path.
- QR payload was already the visible repair code only and remains unchanged.

## Existing Font Review

No existing app font assets were found. The repository did not contain an `assets/` directory before this prompt.

The local system font inventory was inspected. Noto fonts were available under `/usr/share/fonts/noto/`, and the local Noto package license was available under `/usr/share/licenses/noto-fonts/LICENSE`.

No existing application typography assets were reusable for offline PDF embedding.

## Font Decision

Selected font family:

- Noto Sans
- Noto Sans Arabic

Bundled files:

- `NotoSans-Regular.ttf`
- `NotoSans-Bold.ttf`
- `NotoSansArabic-Regular.ttf`
- `NotoSansArabic-Bold.ttf`

Reason:

- Noto Sans covers Latin, French accented characters, digits, and common punctuation.
- Noto Sans Arabic covers Arabic glyphs and Arabic presentation forms used by the `pdf` package's RTL path.
- The files are local bundled assets, so printing works offline with no runtime font download.
- This keeps the implementation to one coherent Noto family set rather than adding unrelated fonts or a font-management framework.

Licensing/attribution:

- The local Noto license file was copied into `assets/fonts/noto/LICENSE.txt`.
- No web font loader or runtime network font fetch is used.

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
- `docs/reports/019-change-status-dialog.md`
- `docs/reports/020-repair-update-workflow-foundation.md`
- `docs/reports/021-edit-repair-ui.md`
- `docs/reports/022-print-preview-ui.md`
- `docs/reports/023-windows-printer-integration-foundation.md`
- Attached Prompt 024 request text
- `design_reference/NOVA_REPAIR_UI_SPEC.md`
- `pubspec.yaml`
- Current asset configuration
- System Noto font files and license files
- `lib/app/theme/app_theme.dart`
- `lib/features/printing/infrastructure/pdf/repair_pdf_document_renderer.dart`
- `lib/features/printing/infrastructure/qr/qr_code_generator.dart`
- `test/features/printing/infrastructure/printer_integration_test.dart`
- `test/features/printing/presentation/print_preview_test.dart`
- `test/features/printing/infrastructure/qr/qr_code_generator_test.dart`
- `test/features/printing/application/build_repair_print_data_use_case_test.dart`
- Relevant local `pdf` package text/font source files for fallback, bidi, and RTL behavior

## Files Created

- `assets/fonts/noto/NotoSans-Regular.ttf`
- `assets/fonts/noto/NotoSans-Bold.ttf`
- `assets/fonts/noto/NotoSansArabic-Regular.ttf`
- `assets/fonts/noto/NotoSansArabic-Bold.ttf`
- `assets/fonts/noto/LICENSE.txt`
- `lib/features/printing/infrastructure/pdf/pdf_print_fonts.dart`
- `docs/reports/024-unicode-print-font-foundation.md`

## Files Modified

- `pubspec.yaml`
- `lib/features/printing/infrastructure/pdf/repair_pdf_document_renderer.dart`
- `test/features/printing/infrastructure/printer_integration_test.dart`

## Asset Configuration

Added Flutter assets:

- `assets/fonts/noto/NotoSans-Regular.ttf`
- `assets/fonts/noto/NotoSans-Bold.ttf`
- `assets/fonts/noto/NotoSansArabic-Regular.ttf`
- `assets/fonts/noto/NotoSansArabic-Bold.ttf`

The license file is stored alongside the font files:

- `assets/fonts/noto/LICENSE.txt`

The license file is not declared as a Flutter runtime asset because it is attribution/documentation, not needed by the renderer.

## Font Loading Architecture

Added:

- `PdfPrintFonts`
- `PdfPrintFontProvider`
- `AssetPdfPrintFontProvider`

Behavior:

- Font bytes are loaded from Flutter bundled assets through `rootBundle`.
- The provider exposes regular and bold Latin fonts plus regular and bold Arabic fallback fonts.
- Loaded font objects are cached in memory through a static future so repeated PDF renders do not reload the same asset bytes.
- The abstraction stays inside the printing infrastructure and does not expose PDF font types to the rest of the app.

No database storage or persisted generated font data was added.

## PDF Renderer Integration

`RepairPdfDocumentRenderer` now depends on `PdfPrintFontProvider`.

All printable text in both document types is rendered through helper methods that apply:

- Noto Sans regular or bold as the primary font.
- Noto Sans Arabic regular or bold as font fallback.
- Explicit text direction based on whether the rendered value contains Arabic-range code points.

Covered text includes:

- shop name
- shop phone
- shop address
- repair code
- labels
- dates
- customer name
- phone
- device text
- device type
- reported problem
- accessories
- QR helper text
- ticket footer
- warranty terms

The renderer no longer relies on the PDF package's built-in Helvetica font path for printable business text.

## Arabic / RTL Behavior

Automated tests cover:

- Arabic-only text
- Arabic customer name
- Arabic shop name
- Arabic reported problem
- Arabic mixed with numbers
- Arabic mixed with Latin device text

The `pdf` package version in use supports `TextDirection.rtl` and bidi handling. The rendered PDF's ToUnicode maps show Arabic presentation-form code points when Arabic is rendered through the package's RTL path.

Important limitation:

- The tests verify that Arabic text renders without the previous missing-font/Helvetica warning path and that Arabic presentation-form mappings exist in the generated PDF.
- They do not constitute a full visual typography audit for every Arabic shaping case or every printer driver.
- Physical printer output still needs validation on Windows hardware.

## French / Latin Behavior

Automated tests cover French accented text such as:

- `Réparation`
- `Téléphone`
- `Écran cassé`

The generated PDF contains ToUnicode mappings for the accented Latin characters, uses Noto Sans, and renders without the previous built-in-font warnings.

## Customer Ticket

Existing content rules remain unchanged.

Included:

- shop name
- optional phone
- optional address
- repair code
- `Received Date`
- customer
- phone
- device
- device type
- reported problem
- accessories
- QR
- footer
- warranty terms

Still excluded:

- price
- customer price decision
- device access
- internal notes
- customer message
- internal database ID
- tracking URL
- tracking token

## Device Label

Existing compact content rules remain unchanged.

Included:

- shop name
- repair code
- device
- customer name when present
- customer phone when present
- QR

Still excluded:

- reported problem
- accessories
- price
- decision
- PIN/password/access information
- internal notes
- customer message
- warranty information
- internal ID

## QR

QR behavior is unchanged.

Payload remains:

- visible repair code only

No tracking URL, token, online endpoint, customer account reference, or QR file persistence was added.

## Database Schema

Schema version remains `4`.

No tables, columns, indexes, migrations, generated Drift files, font tables, print tables, or settings tables were added.

## Dependencies

None.

No Dart or Flutter package dependency was added, removed, or changed.

Asset changes:

- Added bundled Noto font files and license attribution.

## Tests Added

Updated `test/features/printing/infrastructure/printer_integration_test.dart`:

- Initializes the Flutter test binding for asset-backed font loading.
- Captures PDF package print warnings and asserts the old unsupported-font path is not used.
- Verifies customer ticket rendering uses embedded Noto fonts and ToUnicode maps.
- Verifies device label rendering uses embedded Noto fonts and ToUnicode maps.
- Verifies Arabic/French/mixed customer ticket rendering succeeds without font warnings.
- Verifies Arabic/French/mixed device label rendering succeeds without font warnings.
- Verifies French accented characters are mapped in the generated PDF.
- Verifies Arabic presentation-form mappings are present in generated PDFs.
- Preserves existing QR, content, and exclusion coverage.

## Validation Commands

- `flutter pub get`
- `dart format test/features/printing/infrastructure/printer_integration_test.dart lib/features/printing/infrastructure/pdf/pdf_print_fonts.dart lib/features/printing/infrastructure/pdf/repair_pdf_document_renderer.dart`
- `flutter test test/features/printing/infrastructure/printer_integration_test.dart`
- `flutter analyze`
- `flutter test test/features/printing/presentation/print_preview_test.dart`
- `flutter test test/features/printing/infrastructure/qr/qr_code_generator_test.dart`
- `flutter test test/features/printing/application/build_repair_print_data_use_case_test.dart`
- `dart format .`
- `flutter analyze`
- `flutter test`
- `flutter build windows`
- `git status --short`

Intermediate failed commands:

- `dart format lib/features/printing/infrastructure/pdf/pdf_print_fonts.dart lib/features/printing/infrastructure/pdf/repair_pdf_document_renderer.dart pubspec.yaml`
- `flutter test test/features/printing/infrastructure/printer_integration_test.dart`

## Validation Results

Dependency resolution:

- `flutter pub get` succeeded.
- Flutter reported 17 packages with newer versions incompatible with current constraints.
- No package dependency changed.

Formatting:

- One intermediate `dart format ... pubspec.yaml` command failed because `dart format` cannot format YAML files.
- Final `dart format .` succeeded.

Static analysis:

- `flutter analyze` reported no issues.

Focused PDF/font tests:

- Initial focused test run failed because renderer tests now load Flutter assets and needed `TestWidgetsFlutterBinding.ensureInitialized()`.
- A later focused run failed because embedded-font PDFs no longer expose normal text as raw strings and Arabic is mapped through presentation forms.
- Tests were corrected to assert ToUnicode mappings and absence of font warnings.
- Final `flutter test test/features/printing/infrastructure/printer_integration_test.dart` passed.

Adjacent printing tests:

- `flutter test test/features/printing/presentation/print_preview_test.dart` passed.
- `flutter test test/features/printing/infrastructure/qr/qr_code_generator_test.dart` passed.
- `flutter test test/features/printing/application/build_repair_print_data_use_case_test.dart` passed.

All tests:

- `flutter test` passed all tests.

Automated rendering validation:

- Customer ticket and device label PDFs render with bundled Noto fonts.
- Arabic/French/mixed test fixtures render without the previous Helvetica Unicode warning path.
- The generated PDFs contain embedded Noto font names and ToUnicode mappings.

Windows build validation:

- `flutter build windows` was attempted but could not run because the current host is not Windows. Flutter returned: `"build windows" only supported on Windows hosts.`

Physical printer validation:

- Not performed in this environment.

Repository status check:

- `git status --short` failed because the working directory did not appear to be a Git repository.

## Issues or Limitations

- Windows build validation remains blocked by the current non-Windows environment.
- Physical printer output was not tested.
- Printer-driver font rendering and exact paper output remain hardware/driver-dependent.
- The PDF package maps Arabic through presentation-form code points in the generated PDF; this is documented and tested, but it is not a comprehensive visual RTL typography certification.
- The implementation does not add full application localization.
- The implementation does not add a font-management framework.
- No PDF export or Save as PDF was added.
- No Settings UI or printer preference persistence was added.
- No QR behavior changed.

## Next Safe Step

The next safe step is Settings data-model review and Settings UI implementation.

Before implementing Settings UI, inspect whether focused persistence changes are required for:

- shop subtitle
- default customer-ticket printer ID
- default device-label printer ID

Do not implement Settings UI in this prompt.
