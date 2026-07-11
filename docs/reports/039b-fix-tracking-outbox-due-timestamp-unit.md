# Prompt 039B — Fix Tracking Outbox Due Timestamp Unit

## Summary

Fixed the tracking sync outbox due-entry timestamp unit bug.

The outbox datasource now reads, writes, and compares `next_attempt_at`, `created_at`, and `updated_at` as UTC `millisecondsSinceEpoch` integers. Due pending rows whose `next_attempt_at` is less than or equal to the current UTC millisecond timestamp are now returned by the SQL-side due query.

No publisher redesign, retry-policy change, backend API change, outbox schema change, QR behavior change, tests, or Windows build were added.

## Confirmed Runtime Symptom

After Prompt 039A, the coordinator started correctly and logs showed:

```text
Tracking sync coordinator started
Tracking sync cycle triggered
Tracking sync skipped: no due entries
```

However, SQLite showed pending rows such as:

```text
repair_id | attempt_count | last_error | next_attempt_at
1         | 0             | NULL       | 1783454509864
2         | 0             | NULL       | 1783454509864
```

The current machine time was:

```text
1783505130565
```

Because `next_attempt_at < current_time`, those rows were due, but the app still reported no due entries.

## Root Cause

`tracking_sync_outbox` timestamp values were already being seeded by schema-version-7 migration logic as UTC epoch milliseconds:

```dart
final nowValue = now.millisecondsSinceEpoch;
```

The outbox table columns were defined as Drift `DateTimeColumn`s. The datasource then used Drift DateTime binding and comparison APIs:

- `TrackingSyncOutboxTableCompanion.insert(... nextAttemptAt: utcNow ...)`
- `row.nextAttemptAt.isSmallerOrEqualValue(now.toUtc())`
- `Variable.withDateTime(nextAttemptAt.toUtc())`

That mixed the intended millisecond integer storage with Drift's DateTime conversion/comparison behavior. Existing rows contained 13-digit millisecond values, while the due query compared using a different DateTime-bound unit, so due rows were filtered out.

## Timestamp Unit Rule

Tracking sync outbox timestamps now use one explicit rule:

```text
UTC millisecondsSinceEpoch
```

Fields covered:

- `next_attempt_at`
- `created_at`
- `updated_at`

The datasource converts domain `DateTime` values with:

```dart
value.toUtc().millisecondsSinceEpoch
```

Rows are mapped back to domain `DateTime` values with:

```dart
DateTime.fromMillisecondsSinceEpoch(value, isUtc: true)
```

## Fix Applied

Updated `TrackingSyncOutboxLocalDataSource` to avoid Drift's DateTime binding for this table's timestamp fields.

Changes:

- `enqueueRepair` now uses a raw SQL upsert and writes millisecond integers.
- `getEntryForRepair` now reads raw integer timestamp values and constructs `TrackingSyncOutboxRow` with UTC `DateTime`s.
- `listDue` now compares `next_attempt_at <= currentUtcMilliseconds` in SQL.
- `markFailure` now stores retry and update timestamps as millisecond integers.

The repository and domain interfaces continue using `DateTime`; the unit normalization is kept inside the local datasource.

## Due Query Behavior

Due rows are selected with:

```sql
WHERE next_attempt_at <= ?
```

The bound value is:

```dart
now.toUtc().millisecondsSinceEpoch
```

Ordering is preserved:

1. `next_attempt_at ASC`
2. `created_at ASC`
3. `id ASC`

The requested `LIMIT` is still applied in SQLite. Rows are not loaded and filtered in Dart.

## Enqueue / Retry Timestamp Behavior

Enqueue and refresh behavior is preserved:

- missing row inserts a pending row
- existing row keeps the same `repair_id` identity
- `attempt_count` resets to `0`
- `last_error` clears to `NULL`
- `next_attempt_at` becomes the current UTC millisecond timestamp
- `updated_at` becomes the current UTC millisecond timestamp

Failure behavior is preserved:

- `attempt_count` increments SQL-side
- `last_error` stores the safe normalized error
- `next_attempt_at` stores the retry UTC millisecond timestamp
- `updated_at` stores the current UTC millisecond timestamp

## Database Schema

Local Drift schema remains version `7`.

No migrations, generated Drift files, tables, columns, indexes, backend API changes, or QR changes were added.

## Validation Run

Commands run:

- `dart format lib/features/online_tracking/data/datasources/tracking_sync_outbox_local_data_source.dart`
- `flutter analyze`

Per Prompt 039B, no Flutter tests and no Windows build were run.

## Validation Results

Formatting succeeded.

Static analysis succeeded. `flutter analyze` reported:

```text
No issues found!
```

## Manual Verification

Recommended manual verification:

1. Ensure `tracking_sync_outbox` contains due rows where `next_attempt_at <= current UTC milliseconds`.
2. Start the app with `flutter run -d linux`.
3. Confirm logs include:
   - `Tracking sync coordinator started`
   - `Tracking sync cycle triggered`
   - `Tracking sync processing 2 entries`
4. Check the outbox after processing:
   - rows disappear on successful publish, or
   - `attempt_count` increments with a safe `last_error` on failure
5. Confirm the false `Tracking sync skipped: no due entries` result no longer appears when due rows exist.

## Limitations

- Manual runtime publishing was not executed in this environment.
- Flutter tests were not run, per prompt instruction.
- Windows build was not run, per prompt instruction.
- The table still appears as Drift `DateTimeColumn`s in generated code, but the outbox datasource intentionally owns millisecond conversion for this table to match the existing schema-version-7 data.
