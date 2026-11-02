# Performance analysis

## Setup

- MySQL 8.0.46 (Docker), queried with HeidiSQL.
- `user_activity_logs`: 2,000,000 rows of generated test data (see `README.md`, section 3). 50,000 users, 50 organizations.
- Query tested (Q1): the 10 most active users in the last 30 days.
- Before: only the primary key and the automatic foreign-key index `fk_logs_user (user_id)`.
- After: one added index, `idx_logs_created_user (created_at, user_id)`.

## Results

| Metric | Before indexing | After indexing | Improvement |
| --- | --- | --- | --- |
| Execution time (HeidiSQL log) | 24.922 s | 0.500 s | about 50x faster (98% less time) |
| Access type (`EXPLAIN`) | `index`: full scan of `fk_logs_user` | `range` on `idx_logs_created_user` | Full scan replaced by a range scan |
| Rows examined (estimate) | 1,989,368 | 319,670 | about 84% fewer rows |
| Extra | `Using where; Using temporary; Using filesort` | `Using where; Using index` | Row lookups removed (covering index) |
| Result | 10 rows, top user 809 actions | identical | Same answer |

Evidence: `screenshots/01` to `05`.

## Why the query was slow

The query keeps only rows from the last 30 days, which is a small slice of a table that holds a year of activity. With no index on `created_at`, MySQL had no way to find that slice. `EXPLAIN` shows it scanning about 2,000,000 entries of the foreign-key index and then fetching the table row for each, to read `created_at`. It also needed `Using temporary` and `Using filesort` to group and sort the counts. This is the bottleneck: the work grows with the size of the whole table instead of the size of the answer.

## What the index does

`(created_at, user_id)` is a composite index in which the column used in the range filter comes first.

1. **Range scan:** the index is sorted by `created_at`, so MySQL jumps to the first entry of the 30-day window and reads only to the end. `EXPLAIN` changes from `index` to `range` and the rows estimate falls from about 2,000,000 to 319,670.
2. **Covering index:** `user_id` is also in the index, so the query never reads the table rows. `Using index` in the Extra column confirms this.

Column order matters. An index on `(user_id, created_at)` could not support this query's date filter, because the leading column must be the one used for the range.

## Cost of the optimisation

- Building the index took 24.4 s on 2,000,000 rows.
- It uses extra disk space and makes every insert into `user_activity_logs` slightly slower, because the index must be updated too.
- For an audit log that reporting screens read much more often than it is written, this is a good trade. For a table with very heavy write traffic and rare reads, I would reconsider.

## Limitations

- The before time covers three statements (`USE`, `SET @ref` and the `SELECT`), and `SET @ref` also scans the table to find the newest timestamp, so the before figure slightly overstates the query alone.
- One query and one machine were tested, so exact times will differ elsewhere. The plan change (full scan to range scan) is the reliable result.
- The data is synthetic, but its shape (a year of activity, a few very busy users) is realistic.

## Conclusion

A single composite index on `(created_at, user_id)` reduced the query from about 24.9 s to 0.5 s because it replaced a full scan of 2,000,000 entries with a range scan of about 320,000, answered entirely from the index. The trade-off is slower writes and extra storage. As a next step I would measure the other reporting queries (failed logins per user, activity per organization) and add indexes only where `EXPLAIN` shows a full scan.
