# Prompt 037 — Online Backend Foundation

## Summary

Implemented the initial Supabase backend foundation for public repair tracking. The backend now has PostgreSQL tables for authorized installations and latest public repair projections, RLS enabled, focused indexes, a protected publish Edge Function, a public opaque-token lookup Edge Function, a manual provisioning script, and practical backend documentation.

No Flutter integration, retry publisher, QR payload change, public website, deployment command, Flutter tests, Windows build, or local Drift schema change was added.

## Supabase Structure

Created:

- `supabase/migrations/`
- `supabase/functions/publish-repair-tracking/`
- `supabase/functions/get-public-repair-tracking/`
- `supabase/scripts/`

The existing linked `supabase/config.toml` was preserved.

## PostgreSQL Schema

Added migration:

- `supabase/migrations/20260707120000_online_tracking_backend_foundation.sql`

Tables:

- `tracking_installations`
  - `id`
  - `public_shop_id`
  - `installation_secret_hash`
  - `is_enabled`
  - `created_at`
  - `updated_at`

- `public_repair_tracking`
  - `tracking_token`
  - `contract_version`
  - `public_shop_id`
  - `shop_name`
  - `shop_subtitle`
  - `repair_code`
  - `device_display_name`
  - `status`
  - `customer_message`
  - `received_at`
  - `source_updated_at`
  - `published_at`

Allowed status values match the Prompt 035 wire contract. Contract version is constrained to `1`.

String limits:

- `public_shop_id`: 128
- `tracking_token`: 256
- `shop_name`: 160
- `shop_subtitle`: 240
- `repair_code`: 100
- `device_display_name`: 300
- `customer_message`: 2000

## Installation Authentication

The publish endpoint requires:

- `X-Nova-Shop-Id`
- `X-Nova-Installation-Secret`

The function loads an enabled installation by `public_shop_id`, hashes the supplied secret with SHA-256, compares it to `installation_secret_hash`, and verifies the payload shop ID matches the authenticated installation.

Raw installation secrets are never stored in PostgreSQL and are not logged.

## Publish Endpoint

Created:

- `supabase/functions/publish-repair-tracking/index.ts`

Behavior:

- accepts `POST`
- validates the Prompt 035 JSON contract shape
- rejects unsupported contract versions
- validates required public fields, allowed statuses, timestamp parsing, and length limits
- rejects mismatched installation ownership
- calls the database publish RPC
- returns `{ "ok": true, "result": "published" }`, `already_current`, or `ignored_stale`

It stores only safe public projection fields and never stores internal repair IDs, customer phone, reported problem, internal notes, device access, accessories, price, printer IDs, backup data, or local paths.

## Public Lookup Endpoint

Created:

- `supabase/functions/get-public-repair-tracking/index.ts`

Behavior:

- accepts `GET ?token=<opaque-token>`
- looks up by tracking token only
- returns public shop and repair display data
- does not return `publicShopId`, tracking token, backend row IDs, installation IDs, secret hashes, or `publishedAt`
- returns the same generic not-found response for invalid and unknown tokens

Delivered and cancelled repairs remain publicly trackable.

## Stale Update Protection

Added database function:

- `publish_public_repair_tracking(...)`

Rules:

- first publish inserts the row
- newer `repair.updatedAt` updates the same row and returns `published`
- equal `repair.updatedAt` leaves the row unchanged and returns `already_current`
- older `repair.updatedAt` leaves the row unchanged and returns `ignored_stale`
- an existing tracking token under another `public_shop_id` is rejected

The backend stores only the latest public projection.

## RLS and Security

RLS is enabled on:

- `tracking_installations`
- `public_repair_tracking`

No broad anonymous CRUD policies were added. Anonymous and authenticated table access is revoked. Edge Functions use server-side Supabase credentials through environment variables.

Required indexes:

- unique index on `tracking_installations.public_shop_id`
- unique index on `public_repair_tracking.tracking_token`
- index on `public_repair_tracking.public_shop_id`

CORS is environment-based:

- `NOVA_PUBLISH_ALLOWED_ORIGINS`
- `NOVA_PUBLIC_TRACKING_ALLOWED_ORIGINS`

No production localhost origin is hard-coded.

## Installation Provisioning

Created:

- `supabase/scripts/provision-installation.ts`
- `supabase/scripts/.env.example`

The script accepts `PUBLIC_SHOP_ID`, generates a 32-byte random installation secret, hashes it with SHA-256, inserts only the hash, and prints the raw secret once.

It uses environment variables for administrative access:

- `SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY`

No real credentials were committed.

## Validation Run

Commands run:

- `deno --version`
- `supabase --version`
- `rg -n "create table|enable row level security|create unique index|publish_public_repair_tracking|grant execute|tracking_installations|public_repair_tracking" supabase/migrations/20260707120000_online_tracking_backend_foundation.sql`
- `rg -n "customer_name|customer_phone|reported_problem|internal_notes|device_access|price_amount|customer_price|common_problem|printer_id|backup|filesystem|database_path|repair_id" supabase/migrations supabase/functions`
- `find supabase -maxdepth 4 -type f | sort`
- `rg -n "NOVA_PUBLIC_TRACKING_ALLOWED_ORIGINS|NOVA_PUBLISH_ALLOWED_ORIGINS|SUPABASE_SERVICE_ROLE_KEY|X-Nova-Shop-Id|X-Nova-Installation-Secret|ignored_stale|already_current|published" supabase docs/online-tracking-backend.md`

## Validation Results

Deno validation: not available. `deno --version` failed with `deno: command not found`.

Supabase CLI validation: not available. `supabase --version` failed with `supabase: command not found`.

Static migration inspection: passed. Expected table, index, RLS, grant, and publish RPC declarations were found.

Forbidden-field scan: passed. No forbidden local repair fields were found in `supabase/migrations` or `supabase/functions`.

Supabase deployment: not attempted. `supabase db push` and `supabase functions deploy` were intentionally not run.

Flutter tests and Windows build: not run, per mandatory prompt rule.

## Local Database Schema

Local Drift schema remains version `7`.

No Flutter database files, generated Drift files, repair workflows, QR payloads, printer logic, Settings UI, or local outbox behavior were changed.

## Limitations

- Deno is not installed in this environment, so Edge Functions were not type-checked locally.
- Supabase CLI is not installed in this environment, so migrations and functions were not validated by Supabase tooling.
- The backend was not deployed.
- No physical or hosted Supabase runtime test was performed.
- No Desktop publisher, retry worker, installation secret storage in Flutter, QR tracking URL, or customer website was implemented.
- Public lookup CORS depends on future environment configuration.
- Installation provisioning currently creates a new installation and does not implement rotation UI or admin management.

## Next Step

Prompt 038 — Desktop Publisher and Retry Integration
