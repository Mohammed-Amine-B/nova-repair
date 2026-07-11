# Prompt 035 — Online Tracking Contract Foundation

## Summary

Added a backend-neutral online tracking contract foundation for future public customer repair tracking. The app now has a pure public tracking identity model, immutable public repair tracking snapshot, explicit contract version, stable status wire serialization, JSON DTO shape, and a pure snapshot builder from local `Repair` and `ShopSettings` data.

No backend server, public website, network calls, QR payload changes, sync/outbox tables, database schema changes, providers, repositories, or offline workflow changes were added.

## Public Data Contract

`PublicRepairTrackingSnapshot` contains only public-safe fields:

- `contractVersion`
- `trackingToken`
- `publicShopId`
- `shopName`
- optional `shopSubtitle`
- public visible `repairCode`
- `deviceDisplayName`
- current `RepairStatus`
- optional customer-visible `customerMessage`
- `receivedAt`
- `updatedAt`

The JSON shape is backend-neutral and groups shop and repair fields:

- `trackingToken`
- `shop.publicId`
- `shop.name`
- `shop.subtitle`
- `repair.code`
- `repair.device`
- `repair.status`
- `repair.customerMessage`
- `repair.receivedAt`
- `repair.updatedAt`

Timestamps serialize as UTC ISO-8601 strings.

## Sensitive Data Exclusions

The public contract does not include:

- internal repair database ID
- customer name
- customer phone number
- device access information, PINs, passwords, or access notes
- internal notes
- reported problem text
- received accessories
- proposed price
- customer price decision
- Common Problems data
- printer IDs
- backup information
- local filesystem paths
- local database path
- local machine identity

Tests assert sensitive fixture values and sensitive JSON field names are absent from the serialized public snapshot.

## Tracking Token Rules

Added `PublicTrackingIdentity` with:

- `trackingToken`
- `publicShopId`

The tracking token concept is opaque, URL-safe-friendly, non-sequential, and not derived from the repair code, internal ID, phone number, or repair data.

Generation and persistence are intentionally not implemented in this prompt. Future lifecycle rules:

- create once when tracking identity is initialized for a repair
- keep stable across status changes, edits, app restarts, and backup/restore
- do not automatically regenerate
- future manual regeneration may invalidate an old public link

## Public Shop Identity

`publicShopId` represents the future public installation/shop identifier.

It is separate from:

- shop display name
- local database path
- machine hostname
- installation authentication secret
- public repair tracking token

Generation, persistence, and authentication are deferred.

## Status Contract

The public contract reuses the existing `RepairStatus` enum and serializes statuses through explicit stable string values:

- `received`
- `diagnosing`
- `waiting_for_customer_approval`
- `waiting_for_part`
- `repairing`
- `ready_for_pickup`
- `delivered`
- `cancelled`

No second status enum was created, and no enum indexes are used.

The contract supports the flexible workflow from Prompt 034 by representing only the current real repair status. It does not assume a forward-only timeline.

## Customer Message

The snapshot uses only the existing customer-visible `customerMessage`.

Behavior:

- `null` message remains `null`
- blank message is treated as absent
- nonblank message is preserved as the current customer-visible text

Internal notes are not included.

## Snapshot Builder

Added `BuildPublicRepairTrackingSnapshot`, a pure mapper that accepts:

- `Repair`
- `ShopSettings`
- `PublicTrackingIdentity`

It returns `PublicRepairTrackingSnapshot` by copying only approved public fields and deriving device display text through the existing `DeviceDisplayNameFormatter`.

The builder performs no network request, database write, QR generation, or repository lookup.

## Contract Version

Added `PublicTrackingContract.currentVersion = 1`.

The version is included in each snapshot for future backend/client compatibility.

## Future Outbox Boundary

No outbox table was created.

Future publishing should keep local SQLite as the source of truth. Local repair operations must not fail because online publishing fails.

Future outbox work should support:

- pending tracking publish
- retry attempts
- last error
- next retry timing

## QR Future Contract

Current QR behavior is unchanged.

The printed and preview QR payload remains the visible repair code only.

Future QR behavior should target a public tracking URL containing the opaque tracking token, without hard-coding a provider, production domain, localhost URL, or backend stack in this contract.

## Database Schema

Schema version remains `6`.

No tables, columns, indexes, migrations, generated Drift files, tracking identity storage, sync queue, outbox, or online projection tables were added.

## Tests Run

- `dart format lib/features/online_tracking test/features/online_tracking`
- `flutter analyze`
- `flutter test test/features/online_tracking/`

## Validation Results

Formatting: passed.

Static analysis: passed with no issues.

Focused online tracking contract tests: passed.

Per Prompt 035, full `flutter test` and `flutter build windows` were not run.

## Limitations

- Tracking token generation is not implemented.
- Tracking identity persistence is not implemented.
- Public shop ID generation and persistence are not implemented.
- Installation authentication/secret handling is only conceptual.
- No backend provider, server, public website, network client, sync outbox, retry behavior, QR URL payload, or customer tracking page was implemented.
- Public snapshot data is not yet connected to printing, QR, or any publish workflow.

## Next Step

Prompt 036 — Local Tracking Identity and Sync Outbox Foundation.
