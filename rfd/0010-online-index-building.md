# RFD 0010: online index building

**Status:** proposed. Needed before this is production-usable.

## Context

Adding an index today runs a migration on tenant open. Fine when empty, not
when populated: the index must be backfilled, and FoundationDB's hard 10MB
and 5 second transaction limits mean one transaction cannot do it.

`ecto-bench-tpcc` measured the same wall from the write side: 569,011 rows
took roughly 649 s per-row against 9 s batched.

## Decision

An indexer, after Apple's `OnlineIndexer`, that:

- writes index entries in bounded batches under the transaction limits
- records a continuation, so a crash resumes rather than restarts
- marks the index unusable for reads until complete, so the planner never
  picks a half-built index and returns wrong rows
- lets concurrent writes maintain the index as they go

That last point is the correctness crux, and why this cannot be a batch
script outside the adapter.

## Lean model

`lean-fdb-query-ops`, module `OnlineIndex`:

- `buildStep (state : Build) (batch : List Rec) : Build`
- every record is indexed exactly once across all steps
- a record written during the build is indexed by exactly one of the
  backfill or the live path — never both, never neither

## Consequence and open questions

Open: how is "unusable" surfaced — refuse, or fall back to a scan?
