# RFD 0004: aggregates

**Status:** proposed. Independent of RFD 0001 to 0003.

## Context

`count`, `sum`, `avg`, `min`, `max` are unsupported; callers fetch rows and
fold in Elixir, as `ecto-bench-tpcc`'s `stock_level/1` does. Apple's
analogue is `RecordQueryStreamingAggregationPlan`, folding an ordered
stream rather than materialising it.

## Decision

Fold over the existing range iterator, without materialising. `count`
needs no field, and `min`/`max` on the leading key or index field is the
first and last element of a range, so both are O(1) reads.

`group_by` is RFD 0011: it needs the stream partitioned, which is a
different operator.

Refuse aggregates over an unbounded range, so `Repo.aggregate(Schema,
:count)` on a whole table does not silently scan everything.

## Lean model

`lean-fdb-query-ops`, module `Aggregate`:

- `foldStream (f : A -> V -> A) (init : A) (rows : List V) : A`
- `foldStream` over a scan equals the same fold over the sorted table
- `minOf (scanOrdered true rows) = rows.minimum?`, and dually for max

## Consequence and resolution

Aggregates cost a scan of the constrained range, not an index-only count.

Do not refuse for being unbounded. PostgreSQL answers `count(*)` with a
sequential scan and charges for it. The real constraint differs here:
FoundationDB's 5 second transaction limit makes a long scan fail, not
merely run slow. So chunk across transactions with a continuation, the
mechanism RFD 0010 needs anyway, and refuse only what cannot be chunked.
