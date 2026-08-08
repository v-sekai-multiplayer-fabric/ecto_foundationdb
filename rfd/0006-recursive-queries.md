# RFD 0006: recursive queries and real CTEs

**Status:** proposed. Last. Depends on RFD 0005.

## Context

RFD 0007 makes `with_cte` raise instead of silently returning wrong
answers. This RFD makes it work.

A CTE is a named subquery, not a physical operator. Apple handles naming in
its SQL front end and compiles to plans. Recursion is where the operators
live: `RecordQueryRecursiveDfsJoinPlan` ("recursively applies a plan to
earlier results, starting with a root plan") and
`RecordQueryRecursiveLevelUnionPlan`.

## Decision

Two parts, in order:

- **Non-recursive CTEs.** Bind the name to a planned subquery, substitute
  at reference sites. No new operator: reduces to RFD 0005's flat map, or
  a plain scan when uncorrelated.
- **Recursive CTEs.** Add `%RecursiveDfs{root, step}`. Run the root, then
  apply the step to each frontier until it yields nothing.

Require an explicit depth bound: FoundationDB's hard 5 second transaction
limit must not be discovered by unbounded recursion.

## Lean model

`lean-fdb-query-ops`, module `Recursive`:

- `recurse (step : A -> List A) (fuel : Nat) (root : List A) : List A`
- terminates for all `fuel`, by structural recursion on `fuel`
- monotone: the result grows with fuel until a fixed point

## Consequence and open questions

Open: default depth? Dedup by primary key during recursion, or let a cycle
run to the fuel bound?
