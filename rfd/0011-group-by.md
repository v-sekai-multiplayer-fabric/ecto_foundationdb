# RFD 0011: `group_by`

**Status:** proposed. Split out of RFD 0004, which covers ungrouped
aggregates only.

## Context

RFD 0004 folds a scan into one value. `group_by` needs the stream
partitioned, then one fold per partition.

Apple keeps the same split: `RecordQueryStreamingAggregationPlan` carries a
grouping key and relies on its input arriving grouped. Streaming
aggregation is correct only when equal grouping keys are adjacent.

## Decision

Two cases, by whether the grouping key is a prefix of the scan order:

- **Grouped by a key or index prefix.** Equal keys are already adjacent,
  because keys are stored sorted. Fold each run as it passes. Memory is
  one accumulator.
- **Anything else.** A hash aggregate, one accumulator per distinct group
  in memory. Refuse on an unbounded range.

`having` filters the emitted groups, after the fold.

## Lean model

`lean-fdb-query-ops`, module `GroupBy`:

- `groupRuns (key : V -> K) (rows : List V) : List (K x List V)`
- on input sorted by `key`, equals a full `groupBy` — the property that
  licenses the streaming case
- on unsorted input the two differ, so the guard is necessary

## Consequence and open questions

Open: memory cap for the hash path before refusing? Is a post-filter enough
for `having`?
