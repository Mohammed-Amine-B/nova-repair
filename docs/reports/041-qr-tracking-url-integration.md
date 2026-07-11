# Prompt 041 — QR Tracking URL Integration

## Summary

Integrated public online tracking URLs into Customer Ticket QR payload generation.

Customer Ticket QR codes now use:

```text
<trackingWebBaseUrl>/track/<trackingToken>
```

when `NOVA_TRACKING_WEB_BASE_URL` is configured and the repair has a tracking token. If configuration or token data is missing, the QR falls back safely to the existing visible repair code payload.

No Supabase backend APIs, Next.js website source, repair workflows, local database schema, sync logic, normal-user Online Tracking settings, or QR package behavior were changed.

## Tracking Web Base URL Config

Added:

- `OnlineTrackingWebConfig`

It reads the public tracking website base URL from a build-time Dart environment variable:

```text
NOVA_TRACKING_WEB_BASE_URL
```

The value is not a secret. It must not contain the Installation Secret, Supabase service role key, Supabase secret key, or database credentials.

Provider integration:

- `onlineTrackingWebConfigProvider`

## Tracking URL Builder

Added:

- `BuildPublicTrackingUrl`

Behavior:

- trims the configured base URL
- removes trailing slashes
- validates that the base URL has a scheme and host
- trims the tracking token
- URL-encodes the token path segment with `Uri.encodeComponent`
- appends `/track/<encoded-token>`
- returns `null` when the base URL or token is blank/invalid

The repair code is not included in the tracking URL path.

## QR Payload Builder

Added:

- `BuildRepairQrPayload`

Input:

- `Repair`

Behavior:

- configured web base URL and repair tracking token present -> public tracking URL
- otherwise -> visible repair code fallback

This keeps the QR decision centralized instead of duplicating it in preview widgets, PDF rendering, or QR generation infrastructure.

## Customer Ticket Behavior

`BuildRepairPrintDataUseCase` now writes the computed QR payload into `CustomerTicketData.qrPayload`.

Customer Ticket preview and printed Customer Ticket documents generate their QR from:

```text
customerTicket.qrPayload ?? customerTicket.repairCode
```

The ticket still displays the visible repair code near the QR. It does not show the raw tracking token or technical URL as visible text.

The customer-facing helper text remains:

```text
Scan to track your repair
```

## Print Preview Behavior

Print Preview now generates separate QR SVGs for:

- Customer Ticket
- Device Label

Customer Ticket preview uses the same QR payload as printed Customer Tickets.

The Customer Ticket QR semantics label was changed to:

```text
QR code for repair tracking
```

so the raw tracking URL/token is not exposed through the on-screen accessibility label.

## Device Label Behavior

Device Label QR remains repair-code-only.

Reason:

- the current Device Label is a compact internal shop identification label
- it already displays the visible repair code prominently
- Prompt 041 recommended v1 Customer Ticket QR as public tracking URL while allowing Device Label to remain repair-code-only when intended for internal identification

Printed Device Labels and Device Label preview both continue using:

```text
deviceLabel.repairCode
```

## Fallback Behavior

Development/default behavior without:

```text
--dart-define=NOVA_TRACKING_WEB_BASE_URL=...
```

continues to produce QR payloads containing the visible repair code.

Fallback also applies when:

- tracking web base URL is blank
- tracking web base URL is invalid
- repair tracking token is missing or blank

No malformed tracking URL is generated in those cases.

## Sensitive Data Protection

QR payloads do not include:

- Installation Secret
- Supabase service role key
- Supabase secret key
- publicShopId
- internal repair database ID
- customer phone
- customer name
- device access information
- internal notes
- proposed price

The online QR payload uses only the public tracking URL with the opaque repair tracking token.

## Build Configuration

Production builds must include:

```text
--dart-define=NOVA_TRACKING_WEB_BASE_URL=https://<production-domain>
```

Local development can use:

```text
flutter run -d linux --dart-define=NOVA_TRACKING_WEB_BASE_URL=http://localhost:3000
```

Installer packaging was not implemented in this prompt.

## Database Schema

Local Drift schema remains version `7`.

No migrations, generated Drift files, tables, columns, indexes, or backup format changes were added.

## Validation Run

Commands run:

- `dart format lib/features/online_tracking/application/online_tracking_web_config.dart lib/features/online_tracking/application/build_public_tracking_url.dart lib/features/online_tracking/online_tracking_providers.dart lib/features/printing/application/build_repair_qr_payload.dart lib/features/printing/application/build_repair_print_data_use_case.dart lib/features/printing/application/print_repair_document_use_case.dart lib/features/printing/domain/entities/customer_ticket_data.dart lib/features/printing/printing_providers.dart lib/features/printing/presentation/print_preview_controller.dart lib/features/printing/presentation/print_preview_page.dart lib/features/printing/presentation/widgets/customer_ticket_preview.dart lib/features/printing/presentation/widgets/qr_svg_view.dart`
- `flutter analyze`

Per Prompt 041, no Flutter tests and no Windows build were run.

## Validation Results

Formatting succeeded.

Static analysis succeeded. `flutter analyze` reported:

```text
No issues found!
```

## Manual Verification

Development fallback:

1. Run the app without `--dart-define=NOVA_TRACKING_WEB_BASE_URL=...`.
2. Open Print Preview for a repair.
3. Confirm Customer Ticket QR payload remains the repair code fallback.

Online QR:

1. Run:

   ```text
   flutter run -d linux --dart-define=NOVA_TRACKING_WEB_BASE_URL=http://localhost:3000
   ```

2. Open Print Preview for a repair that has a tracking token.
3. Confirm Customer Ticket QR payload points to:

   ```text
   http://localhost:3000/track/<trackingToken>
   ```

4. Confirm Device Label QR remains the visible repair code.

Production:

1. Build/run with:

   ```text
   --dart-define=NOVA_TRACKING_WEB_BASE_URL=https://<production-domain>
   ```

2. Scan a printed Customer Ticket QR.
3. Confirm it opens the public tracking website.

## Limitations

- Runtime QR scanning was not manually executed in this environment.
- Flutter tests were not run, per prompt instruction.
- Windows build was not run, per prompt instruction.
- Production installer/build configuration still needs to pass the tracking web base URL.
- End-to-end validation requires deployed website, deployed backend, publisher success, and a physical or camera-based QR scan.

## Next Step

- deploy the customer tracking website
- configure production tracking web base URL
- perform end-to-end QR scan validation
