# RFD 0002: `OR` as an unordered union

**Status:** proposed. Depends on RFD 0001's fan-out machinery.

## Context

`or` raises `Unsupported` on `vsk` (`2ffe739`). `zone-backend` has 62
sites matching `or`, though not all are query-level disjunctions.

Apple's analogue is `RecordQueryUnorderedUnionPlan`, with the ordered
`RecordQueryUnionPlan` when both sides arrive in index order.

## Decision

Add `%Or{branches}`. Plan each branch independently, run them, concatenate.
Start unordered, which needs no merge logic.

Deduplicate by primary key: a row satisfying both branches must appear
once. That is why `OR` costs more than fan-out alone. Refuse when any
branch is itself unsupported.

## Lean model

`lean-fdb-query-ops`, module `Union`:

- `unionBy (key : V -> K) (a b : List V) : List V`
- every element of `a` and of `b` appears in the result
- no key appears twice
- `unionBy k a [] = a`, up to duplicate removal
- Plausible: agrees with a filter of `p or q` over the full table

## Consequence and open questions

Output is unordered, so any `order_by` applies after the union. That
interacts with RFD 0003 and forbids early stop under a `limit`. Cost is
the sum of the branches.

Open: ordered merge when branches share an index order, matching
`RecordQueryUnionPlan`? Defer until 0003 lands.
