# RFD 0004: aggregates

**Status:** proposed. Independent of RFD 0001 to 0003.

## Context

`count`, `sum`, `avg`, `min`, `max` are unsupported. Callers currently
fetch rows and fold in Elixir. `ecto-bench-tpcc`'s `stock_level/1` does
exactly this, and says so in its moduledoc.

Apple's analogue is `RecordQueryStreamingAggregationPlan`, which folds over
an ordered stream rather than materialising it.

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
- Plausible: streaming count agrees with `List.length` of a filter

## Consequence and open questions

Aggregates cost a scan of the constrained range. That is honest, but it is
not a SQL engine's index-only count.

Open: refuse or warn on an unbounded aggregate? Is `group_by` wanted?
