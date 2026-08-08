# Query operator RFDs

Request-for-Discussion documents ([Oxide
format](https://rfd.shared.oxide.computer/)) for extending this adapter
past its single Get / single GetRange contract.

## Method: Lean first

Every operator gets a Lean 4 + Plausible model **before** any Elixir,
matching this org's cores (`lean-http3-queue`, `lean-rebac-core`). The
model is the source of truth; the Elixir change implements it. Target
repo `lean-fdb-query-ops`.

## The gap (measured on `vsk`, `2ffe739`)

Prefix scans on the primary key work. `in`, `or` and `subquery` raise
`Unsupported`; `order_by`, `limit`, aggregates and joins are unsupported;
`with_cte` is **silently ignored** (RFD 0007). `zone-backend` has 12
schemas, 40 `preload`s, 22 `join(`s, 11 `limit`s, 10 `offset`s, 5 `union`s.

## Why operators, not SQL

This adapter implements `Ecto.Adapter.Queryable` and already receives a
parsed AST; emitting SQL only creates the need to parse it back. Apple's
`fdb-record-layer` solves this above the KV store, with operators that
iterate. We port that taxonomy.
## Index
| RFD | Topic | Record Layer analogue | Size |
|---|---|---|---|
| [0007](0007-cte-silently-ignored.md) | CTE bug | — | ~1 hour |
| [0001](0001-in-operator.md) | `IN` | `RecordQueryInJoinPlan` | ~1 day |
| [0002](0002-or-operator.md) | `OR` | `RecordQueryUnorderedUnionPlan` | ~2 days |
| [0003](0003-order-by-limit.md) | `ORDER BY`/`LIMIT` | index-order scan | ~3 days |
| [0004](0004-aggregates.md) | aggregates | streaming aggregation | ~3 days |
| [0011](0011-group-by.md) | `group_by` | grouped streaming aggregation | ~3 days |
| [0005](0005-lateral-join.md) | lateral join | `RecordQueryFlatMapPlan` | ~2 weeks |
| [0006](0006-recursive-queries.md) | recursive, CTEs | `RecordQueryRecursiveDfsJoinPlan` | later |
| [0008](0008-cascades-cost-optimizer.md) | cost optimizer | `CascadesPlanner` | later |
| [0009](0009-lucene-like-indexing.md) | text indexing | `fdb-record-layer-lucene` | later |
| [0010](0010-online-index-building.md) | online index build | `OnlineIndexer` | before prod |
