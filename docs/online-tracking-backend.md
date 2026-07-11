# Online Tracking Backend

Nova Repair remains offline-first. Local SQLite is the source of truth for
repairs, shop settings, tracking identities, and the local publish outbox.

The Supabase backend stores only the latest public-safe tracking projection for
customer lookup. It is not a cloud replica of the local database.

## Architecture

```text
Nova Repair Desktop
  -> local SQLite
  -> local tracking outbox
  -> protected publish Edge Function
  -> Supabase PostgreSQL public projection
  -> public lookup Edge Function
```

Future QR and web work can point customers at the public lookup function using
the opaque tracking token. The current printed QR payload is unchanged.

## Access Boundaries

There are two separate backend access paths.

Installation verification:

- Edge Function: `verify-tracking-installation`
- Method: `POST`
- Authentication headers:
  - `X-Nova-Shop-Id`
  - `X-Nova-Installation-Secret`
- Used by Desktop setup to verify the local secure credential before saving it.
- Does not publish or modify repair tracking data.

Protected installation publish:

- Edge Function: `publish-repair-tracking`
- Method: `POST`
- Authentication headers:
  - `X-Nova-Shop-Id`
  - `X-Nova-Installation-Secret`
- Used by the future desktop publisher only.

Public customer lookup:

- Edge Function: `get-public-repair-tracking`
- Method: `GET`
- Query: `?token=<opaque-token>`
- Used by a future customer tracking page.

Browser and desktop clients must not query tracking tables directly. Row level
security is enabled and no broad anonymous CRUD policies are created.

## Public Contract

The publish endpoint accepts the Prompt 035 contract:

```json
{
  "contractVersion": 1,
  "trackingToken": "...",
  "shop": {
    "publicId": "...",
    "name": "...",
    "subtitle": "..."
  },
  "repair": {
    "code": "...",
    "device": "...",
    "status": "repairing",
    "customerMessage": "...",
    "receivedAt": "...",
    "updatedAt": "..."
  }
}
```

The public lookup endpoint returns the public display projection only:

```json
{
  "ok": true,
  "data": {
    "contractVersion": 1,
    "shop": {
      "name": "...",
      "subtitle": "..."
    },
    "repair": {
      "code": "...",
      "device": "...",
      "status": "repairing",
      "customerMessage": "...",
      "receivedAt": "...",
      "updatedAt": "..."
    }
  }
}
```

## Forbidden Fields

The Supabase public projection must not store:

- local repair database ID
- customer name
- customer phone
- reported problem
- internal notes
- device access information, PINs, passwords, or access notes
- accessories
- proposed price
- customer price decision
- Common Problems data
- printer IDs
- backup information
- filesystem paths
- local database path

## Tables

`tracking_installations` represents authorized desktop installations.

- `id`: backend UUID primary key
- `public_shop_id`: local `ShopSettings.publicShopId`
- `installation_secret_hash`: SHA-256 hash of the raw installation secret
- `is_enabled`: disables an installation without deleting it
- `created_at`
- `updated_at`

`public_repair_tracking` stores the latest public projection by tracking token.

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

The backend supports contract version `1` and these status wire values:

- `received`
- `diagnosing`
- `waiting_for_customer_approval`
- `waiting_for_part`
- `repairing`
- `ready_for_pickup`
- `delivered`
- `cancelled`

## Length Limits

- `public_shop_id`: 128
- `tracking_token`: 256
- `shop_name`: 160
- `shop_subtitle`: 240
- `repair_code`: 100
- `device_display_name`: 300
- `customer_message`: 2000

## Stale Update Protection

The publish function stores incoming `repair.updatedAt` as `source_updated_at`.

- newer source timestamp: update the current projection and return `published`
- equal source timestamp: leave the row unchanged and return `already_current`
- older source timestamp: leave the row unchanged and return `ignored_stale`

If a tracking token already belongs to another `public_shop_id`, publishing is
rejected. This prevents installation ownership takeover.

## Installation Provisioning

Use the Deno provisioning script after the Supabase migration has been applied:

```text
SUPABASE_URL=...
SUPABASE_SERVICE_ROLE_KEY=...
PUBLIC_SHOP_ID=...
deno run --allow-env --allow-net supabase/scripts/provision-installation.ts
```

The script:

1. accepts the local `publicShopId`
2. generates a high-entropy installation secret
3. hashes the secret with SHA-256
4. stores only the hash in `tracking_installations`
5. prints the raw secret once

Do not commit real `.env` files or raw installation secrets.

## CORS

The verification function reads allowed origins from:

```text
NOVA_VERIFY_ALLOWED_ORIGINS
```

The public lookup function reads allowed browser origins from:

```text
NOVA_PUBLIC_TRACKING_ALLOWED_ORIGINS
```

The protected publish function reads allowed origins from:

```text
NOVA_PUBLISH_ALLOWED_ORIGINS
```

Both values are comma-separated. No localhost production origin is hard-coded.

## Deployment

This repository contains the migration, Edge Functions, and provisioning script.
Deployment is a separate reviewed step.

Do not assume deployment has succeeded until commands such as `supabase db push`
and `supabase functions deploy` are run in an environment with the Supabase CLI,
project credentials, and deployment approval.
