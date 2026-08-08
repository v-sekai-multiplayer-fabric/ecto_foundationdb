# RFD 0005: lateral join

**Status:** proposed. The largest operator here.

## Context

Joins are unsupported. `zone-backend` has 22 `join(` sites. RFD 0001
covers `preload`, the larger number, but not real joins.

Apple's `RecordQueryFlatMapPlan`: "`FLATMAP` implements correlated lateral
joins by executing an inner plan for each row produced by a driving outer
plan." FoundationDB gains no join capability — the layer above iterates.

## Decision

Add `%FlatMap{outer, inner, correlation}`. Run the outer plan, and for each
row run the inner with the correlated value bound. Concatenate.

The hard part is choosing the driving side. Without a cost model, use a
rule: the side resolving to a point Get drives, and the other must be
index-answerable. Refuse when neither qualifies, rather than falling back
to a cross product.

## Lean model

`lean-fdb-query-ops`, module `FlatMap`:

- `flatMapJoin (outer : List A) (inner : A -> List B) : List (A x B)`
- equals `outer.flatMap (fun a => (inner a).map (Prod.mk a))`
- empty outer gives empty; empty inner drops that outer row

## Consequence and resolution

One inner plan per outer row. An unindexed inner side is a scan per row,
so refusing matters.

Yes, left joins are needed: Ecto uses `left_join` heavily, and every
tier-S engine supports the full set. It is cheap here. A left join is the
same flat map, except an empty inner yields one row of nulls rather than
dropping the outer row. Inner and left share one operator.
