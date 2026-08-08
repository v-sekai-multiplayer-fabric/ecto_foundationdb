# RFD 0011: `group_by`

**Status:** proposed. Split out of RFD 0004, which covers ungrouped
aggregates only.

## Context

RFD 0004 folds a scan into one value. `group_by` needs the stream
partitioned, then one fold per partition.
Apple keeps the same split: `RecordQueryStreamingAggregationPlan` carries a
grouping key and relies on grouped input. Streaming aggregation is correct
only when equal grouping keys are adjacent.

## Decision

Two cases, by whether the grouping key is a prefix of the scan order:

- **Grouped by a key or index prefix.** Equal keys are already adjacent,
  because keys are stored sorted. Fold each run as it passes. Memory is
  one accumulator.
- **Anything else.** A hash aggregate, one accumulator per distinct group
  in memory. Refuse on an unbounded range.

## Lean model

`lean-fdb-query-ops`, module `GroupBy`:

- `groupRuns (key : V -> K) (rows : List V) : List (K x List V)`
- on input sorted by `key`, equals a full `groupBy` — the property that
  licenses the streaming case

## Consequence and resolution

Cap and error, naming the cap. PostgreSQL 13 and later spill hash
aggregation to disk rather than refusing, sized by `work_mem` x
`hash_mem_multiplier`. We have no spill, so an unbounded hash aggregate
exhausts BEAM memory. A named error beats an OOM.

A post-filter is correct for `having`: SQL applies it after aggregation.
Pushing parts of it below the fold is an RFD 0008 optimisation.
