# RFD 0003: `ORDER BY` and `LIMIT`

**Status:** proposed. Interacts with RFD 0001 and 0002.

## Context

Data is stored in key order, and range reads are ordered and reversible.
`backward?/3` already reverses a scan when the requested order matches the
key descending. Missing: a general `order_by`, and a `limit` that stops
early. `zone-backend` has 11 `limit`s and 10 `offset`s (`scrivener_ecto`).

## Decision

Two cases:

- **Order matches the scanned key or index prefix.** Serve from the range
  directly, forward or reversed. A `limit` becomes an early stop, so cost
  is proportional to the limit, not the table.
- **Order does not match.** Sort client-side. A `limit` cannot stop
  early, so refuse it rather than silently scanning the whole table.

`offset` is a client-side drop in both cases.

## Lean model

`lean-fdb-query-ops`, module `Ordering`:

- `scanOrdered (asc : Bool) (rows : List V) : List V`
- reversing a sorted scan equals sorting descending
- `take n (scanOrdered asc rows)` equals the first `n` of the fully
  sorted result — the property that licenses early stop

## Consequence and open questions

Pagination works only along an index. Open: warn or refuse on a large
unindexed `order_by`?
