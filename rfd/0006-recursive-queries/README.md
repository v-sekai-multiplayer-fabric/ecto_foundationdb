# RFD 0006: recursive queries and real CTEs

**Status:** proposed. Last. Depends on RFD 0005.

## Context

RFD 0007 makes `with_cte` raise instead of silently returning wrong
answers. This RFD makes it work.

A CTE is a named subquery, not a physical operator. Recursion is where the
operators live: `RecordQueryRecursiveDfsJoinPlan` "recursively applies a
plan to earlier results, starting with a root plan".

## Decision

Two parts, in order:

- **Non-recursive CTEs.** Bind the name to a planned subquery, substitute
  at reference sites. No new operator: reduces to RFD 0005's flat map, or
  a plain scan when uncorrelated.
- **Recursive CTEs.** Add `%RecursiveDfs{root, step}`. Run the root, then
  apply the step to each frontier until it yields nothing.

## Lean model

`lean-fdb-query-ops`, module `Recursive`:

- `recurse (step : A -> List A) (fuel : Nat) (root : List A) : List A`
- terminates for all `fuel`, by structural recursion on `fuel`

## Consequence and resolution

Default depth 100, configurable, erroring on exhaustion — SQL Server's
`MAXRECURSION` default, which raises error 530 and accepts 0 to 32767, 0
meaning unlimited. A depth bound is the one place a tier-S engine does
refuse: runaway recursion is a logic bug, not a cost.

Dedup follows SQL: the `UNION` form dedups and so terminates on cycles,
`UNION ALL` does not. Expose both; dedup by primary key.
