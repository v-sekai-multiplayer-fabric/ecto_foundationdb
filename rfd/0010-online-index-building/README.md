# RFD 0010: online index building

**Status:** proposed. Needed before this is production-usable.

## Context

Adding an index today runs a migration on tenant open. Fine when empty,
not when populated: the backfill cannot fit one transaction, given
FoundationDB's hard 10MB and 5 second limits. `ecto-bench-tpcc` hit the
same wall writing: 569,011 rows took ~649 s per-row against ~9 s
batched.

## Decision

An indexer, after Apple's `OnlineIndexer`, that:

- writes index entries in bounded batches under the transaction limits
- records a continuation, so a crash resumes rather than restarts
- marks the index unusable for reads until complete, so the planner never
  picks a half-built index and returns wrong rows

## Lean model

`lean-fdb-query-ops`, module `OnlineIndex`:

- `buildStep (state : Build) (batch : List Rec) : Build`
- every record is indexed exactly once across all steps

## Consequence and resolution

Ignore the index for planning, as PostgreSQL does: a failed
`CREATE INDEX CONCURRENTLY` leaves an invalid index the planner will not
use, though it still costs write overhead.

There is a twist. PostgreSQL falls back to a scan, but this adapter
refuses queries no index covers, so ignoring yields the generic "no index
covers these fields" error. Raise a specific error naming the build in
progress, so the cause is not mistaken for a missing migration.
