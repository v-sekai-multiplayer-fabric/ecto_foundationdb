# RFD 0009: text indexing

**Status:** proposed. Independent of the operator RFDs.

## Context

The adapter indexes exact values only. No tokenising, stemming, or
ranking. A `LIKE '%term%'` equivalent would be a full scan.

Apple ships `fdb-record-layer-lucene` separately, storing a Lucene index
inside FoundationDB with the directory backed by keys.

## Decision

Do not port Lucene. Port the shape that fits key ordering: an inverted
index maintained by the existing indexer.

- tokenise a text field on write, one index key per token, keyed
  `{token, primary_key}`
- a term query is a prefix GetRange on `{token}`, which the adapter
  already does well
- multi-term AND is an intersection of postings; OR is RFD 0002's union
- ranking is out of scope for a first cut

## Lean model

`lean-fdb-query-ops`, module `Inverted`:

- `postings (tok : Token) (docs : List Doc) : List Id`
- a term query equals filtering documents containing the token

## Consequence and resolution

Index size grows with tokens per document. Stemming and stop
words: pluggable, off by default. Exact tokens first,
with a dictionary hook after. PostgreSQL takes the same shape — `tsvector`
runs text through configurable dictionaries chosen per language rather
than baked in. Hard-coding one stemmer picks a language for every user of
the adapter, which is not ours to pick.
