# RFD 0001: `IN` as a fan-out operator

**Status:** proposed. Highest value per unit of work.

## Context

`where x in ^list` raises `Unsupported` on `vsk` (`2ffe739`). That blocks
every `preload`, because Ecto's separate-query strategy issues
`where id in ^ids`. `zone-backend` has 40 of them.

Apple's `RecordQueryInJoinPlan`: "executes a child plan once for each of
the elements of some `IN` list." That is the whole semantics — no cost
model needed.

## Decision

Add `%In{field, pk?, params}` and a `get_op/3` clause for `:in` in
`query_plan.ex`. In `Query.all/4`, expand to one sub-plan per element,
each reusing the existing `Equal` path, then concatenate.

`LazyRangeIterator` already has a list-backed variant (`start(list)`,
`handle_next([h | t])`), so results satisfy the iterator contract with no
new machinery.

## Lean model

`lean-fdb-query-ops`, module `InJoin`:

- `inJoin (keys : List K) (get : K -> List V) : List V`
- `inJoin keys get = keys.flatMap get`, and `inJoin [] get = []`
- duplicate keys yield duplicates, so dedup is the caller's choice
- Plausible: agrees with a filter over the full table

## Consequence and open questions

`IN` on a non-key, non-indexed field stays unsupported. N elements is N
round trips, so cap the list or document the cost.

Open: cap before refusing? Behaviour when `IN` names a trailing composite
key field?
