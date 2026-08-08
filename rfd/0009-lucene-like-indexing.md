# RFD 0009: text indexing

**Status:** proposed. Independent of the operator RFDs.

## Context

The adapter indexes exact values only. No tokenising, stemming, or
ranking. A `LIKE '%term%'` equivalent would be a full scan.

Apple ships this as a separate module, `fdb-record-layer-lucene`, storing a
Lucene index inside FoundationDB with the directory backed by keys.

## Decision

Do not port Lucene. Port the shape that fits key ordering: an inverted
index maintained by the existing indexer.

- tokenise a text field on write, one index key per token, keyed
  `{token, primary_key}`
- a term query is a prefix GetRange on `{token}`, which the adapter
  already does well
- multi-term AND is an intersection of postings; OR is RFD 0002's union
- ranking is out of scope for a first cut

This makes text search a special case of planned operators.

## Lean model

`lean-fdb-query-ops`, module `Inverted`:

- `postings (tok : Token) (docs : List Doc) : List Id`
- a term query equals filtering documents containing the token
- `intersect` of postings equals filtering on all tokens

## Consequence and open questions

Index size grows with tokens per document. Open: stemming and stop words,
or exact tokens only?
