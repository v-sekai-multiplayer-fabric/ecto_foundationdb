# RFD 0008: Cascades cost optimizer

**Status:** proposed. Only worth doing after RFD 0005.

## Context

RFD 0001 to 0006 each pick a plan by fixed rule. That holds while one
constraint shape maps to one operator. It stops at RFD 0005, where a join
must choose a driving side, and again once several indexes could serve one
query.

Apple's answer is `CascadesPlanner` plus `PlannerRule`, in
`fdb-record-layer-core`'s `query/plan/cascades` package: 591 files.

## Decision

Port the shape, not the file count:

- a memo keyed by logical expression, so equivalent subplans are explored
  once
- rules as data (`PlannerRule`), each rewriting one expression into
  another, rather than a hand-written `cond`
- a cost model over cardinality estimates, scoring index choice

Keep the rule-based path as fallback when the search budget runs out.

## Lean model

`lean-fdb-query-ops`, module `Cascades`:

- `explore (rules : List Rule) (fuel : Nat) (e : Expr) : List Expr`
- every explored expression is semantically equal to the input — the
  property that makes optimisation safe

## Consequence and open questions

Cardinality estimates need statistics not collected today. Open: sample at
query time, or maintain per-index counters?
