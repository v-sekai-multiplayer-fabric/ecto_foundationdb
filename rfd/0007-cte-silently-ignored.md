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
following the convention already in `layer/query.ex`. Wrong answers are
worse than a refusal. RFD 0006 covers real support.

## Lean model

None. A guard clause, not semantics. Test only.

## Consequence and open questions

No caller can rely on today's behaviour correctly, because the CTE never
ran.

Open: does Ecto populate `with_ctes` implicitly anywhere, so the guard
could fire on a query the user did not write as a CTE?
