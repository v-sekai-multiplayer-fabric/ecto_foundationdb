# RFD 0007: `with_cte` is silently ignored

**Status:** proposed. Do this first — it returns wrong answers today.

## Context

`Ecto.Query.with_cte/3` sets `query.with_ctes`. This adapter never reads
it: `grep -rniE "with_cte|ctes" lib/` returns nothing.

Measured on `vsk` (`2ffe739`), a CTE matching nothing, attached to a query
returning 3 rows:

```
PROOF plain=3  with_empty_cte=3  -> CTE SILENTLY IGNORED
PROOF query carries ctes: true
PROOF select FROM cte: returned 0 (treated as a source named "empty")
```

The CTE is dropped and the unrestricted result comes back. Selecting
`FROM` it by name returns 0: the name resolves as a schemaless source that
does not exist.

## Decision

Raise `Unsupported` when `with_ctes` is non-empty, naming the field,
following the convention already in `layer/query.ex`. RFD 0006 covers real support.

## Lean model

None. A guard clause, not semantics. Test only.

## Consequence and resolution

No caller can rely on today's behaviour, because the CTE never ran.

The guard cannot fire spuriously. In Ecto only
`Ecto.Query.Builder.CTE.apply/5`, reached through `with_cte/3`, ever sets
`with_ctes`. The field defaults to `nil`, and `recursive_ctes/2` only
flips a flag on an expression that already exists. A non-empty
`with_ctes` therefore always means the user wrote a CTE.
