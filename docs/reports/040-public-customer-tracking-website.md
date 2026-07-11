# Prompt 040 — Public Customer Tracking Website

## Summary

Implemented the first public customer tracking website under `web/`.

The site provides a simple home page and a mobile-first `/track/[token]` route that calls the existing public Supabase Edge Function by opaque tracking token and renders only the public-safe repair tracking projection.

No Flutter Desktop files, local SQLite schema, Supabase PostgreSQL schema, Edge Functions, QR payloads, or print tickets were changed.

## Web Stack

Created a Next.js app under `web/` using:

- Next.js
- TypeScript
- Tailwind CSS
- ESLint

Added web package/config files:

- `web/package.json`
- `web/package-lock.json`
- `web/tsconfig.json`
- `web/next.config.ts`
- `web/postcss.config.mjs`
- `web/tailwind.config.ts`
- `web/eslint.config.mjs`
- `web/.env.example`
- `web/.gitignore`

The existing Flutter web shell assets already present in `web/` were left untouched.

## Routes

Implemented:

- `/`
- `/track/[token]`

Home page behavior:

- Shows the app name.
- Shows: `Scan your repair ticket QR code to track your repair.`
- Does not include a repair-code, phone, or manual search form.

Tracking route behavior:

1. Reads the opaque token from route params.
2. Treats a missing or blank token as not found.
3. Calls the public lookup Edge Function.
4. Renders the current repair tracking data when found.
5. Renders a safe not-found state for invalid or unknown tokens.
6. Renders a safe error state for network, configuration, or server failures.

## Tracking Fetch

Added:

- `web/lib/tracking/client.ts`

The tracking page calls:

```text
get-public-repair-tracking?token=<trackingToken>
```

through the configured function URL:

```text
NOVA_PUBLIC_TRACKING_FUNCTION_URL
```

The site uses `fetch` only. It does not use the Supabase SDK and does not query Supabase tables directly.

Fetch behavior:

- uses `GET`
- sends `Accept: application/json`
- uses `cache: "no-store"`
- maps HTTP `404` and backend `not_found` to the not-found state
- maps other failures to the generic unavailable state
- does not print raw backend errors in the UI

## Public Data Displayed

The tracking card displays only fields returned by the public lookup contract:

- shop name
- optional shop subtitle
- repair code
- device display name
- current status
- optional customer-visible message
- received date
- last updated date

The tracking token is used only for lookup and is not displayed.

## Forbidden Data

The web source does not render:

- tracking token
- public shop ID
- customer name
- customer phone
- reported problem
- internal notes
- device access information
- proposed price
- backend IDs
- installation secrets
- authentication headers

No analytics, customer login, or manual repair lookup was added.

## Status Display

Added customer-friendly status mapping for all public wire values:

- `received` -> `Received`
- `diagnosing` -> `Diagnosing`
- `waiting_for_customer_approval` -> `Waiting for customer approval`
- `waiting_for_part` -> `Waiting for part`
- `repairing` -> `Repairing`
- `ready_for_pickup` -> `Ready for pickup`
- `delivered` -> `Delivered`
- `cancelled` -> `Cancelled`

The UI displays a simple `Current Status` card, not a fake forward-only timeline.

## Not Found and Error States

Not found state:

- title: `Repair not found`
- message: `Please check the tracking link on your repair ticket.`

Error state:

- title: `Tracking temporarily unavailable`
- message: `Please try again later.`

Neither state reveals whether a shop exists or exposes raw backend details.

## Environment Variables

Created:

- `web/.env.example`

Included:

```text
NEXT_PUBLIC_APP_NAME=Nova Repair
NOVA_PUBLIC_TRACKING_FUNCTION_URL=
```

Local setup should copy this to:

```text
web/.env.local
```

and set `NOVA_PUBLIC_TRACKING_FUNCTION_URL` to the deployed `get-public-repair-tracking` function URL.

No service role key, installation secret, database password, or Supabase secret key was added.

## Validation Run

Commands run:

- `npm install`
- `npm run lint`
- `npm run build`

Flutter tests, Flutter build, and Supabase deployment commands were not run.

## Validation Results

Dependency installation succeeded after registry access was approved.

`npm install` added 324 packages and created `web/package-lock.json`.

npm reported:

- 2 moderate severity audit findings
- install-script approval warnings for `unrs-resolver` and `sharp`

No audit fix or install-script approval was run because that was outside this prompt.

Initial lint after a successful build failed because ESLint was scanning generated `.next` output. `web/eslint.config.mjs` was updated to ignore generated/build directories and `next-env.d.ts`.

Final validation:

- `npm run lint` passed.
- `npm run build` passed.

Next.js build output confirmed:

- `/` is static.
- `/track/[token]` is server-rendered on demand.

## Limitations

- The web app was not connected to a real deployed function URL in this environment.
- No hosted deployment was performed.
- No browser/device manual QA was performed.
- Existing Flutter web shell files remain in `web/`; they were not used by the Next app and were left untouched.
- QR payloads still point to the existing repair-code behavior; tracking URL QR integration is deferred.
- No localization was added; v1 UI is English only.
- No customer search, login, analytics, or admin UI was added.

## Next Step

Prompt 041 — QR Tracking URL Integration
