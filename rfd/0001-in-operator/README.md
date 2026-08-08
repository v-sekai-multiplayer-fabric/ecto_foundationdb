# RFD 0001: `IN` as a fan-out operator

**Status:** proposed. Highest value per unit of work.

## Context

`where x in ^list` raises `Unsupported` on `vsk` (`2ffe739`), blocking
every `preload`: Ecto's separate-query strategy issues `where id in ^ids`,
and `zone-backend` has 40. Apple's `RecordQueryInJoinPlan` "executes a
child plan once for each of the elements of some `IN` list" — the whole
semantics, no cost model.

## Decision

Add `%In{field, pk?, params}` and a `get_op/3` clause for `:in` in
`query_plan.ex`. In `Query.all/4`, expand to one sub-plan per element,
each reusing the existing `Equal` path, then concatenate.

`LazyRangeIterator` already has a list-backed variant, so results satisfy
the iterator contract with no new machinery.

## Lean model

`lean-fdb-query-ops`, module `InJoin`:

- `inJoin (keys : List K) (get : K -> List V) : List V`
- `inJoin keys get = keys.flatMap get`, and `inJoin [] get = []`

## Consequence and resolution

No hard cap on length. PostgreSQL sets none either, and PG14 added hash
lookup for large `IN` lists. But our fan-out is N round trips, not one
scan plus a hash probe, so cap by cost rather than count: past the
crossover a range scan plus client filter is cheaper. Default 1000,
configurable.

`IN` on a trailing composite key field works when every leading field is
constrained by `=` — still a prefix plus fan-out. Unconstrained leading
fields refuse, by the same rule as any non-prefix query.
