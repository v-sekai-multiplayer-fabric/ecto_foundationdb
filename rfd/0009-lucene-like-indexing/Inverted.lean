/-
RFD 0009: text indexing.

An inverted index keyed {token, primary_key}. A term query is then a
prefix range scan, and multi-term AND is an intersection of postings.
-/
namespace Inverted
variable {Id Token : Type} [DecidableEq Token] [DecidableEq Id]

/-- A document is an id plus its tokens. -/
abbrev Doc (Id Token : Type) := Id × List Token

/-- The posting list for one token. -/
def postings (tok : Token) (docs : List (Doc Id Token)) : List Id :=
  (docs.filter (fun d => d.2.contains tok)).map Prod.fst

/-- No documents, no postings. -/
theorem postings_nil (tok : Token) :
    postings tok ([] : List (Doc Id Token)) = [] := rfl

/-- A term query equals filtering documents that contain the token. -/
theorem postings_eq_filter (tok : Token) (docs : List (Doc Id Token)) :
    postings tok docs = (docs.filter (fun d => d.2.contains tok)).map Prod.fst := rfl

/-- The index is built per document, so it can be maintained incrementally. -/
theorem postings_append (tok : Token) (a b : List (Doc Id Token)) :
    postings tok (a ++ b) = postings tok a ++ postings tok b := by
  simp [postings, List.filter_append]

/-- Multi-term AND: intersect the posting lists. -/
def andQuery (toks : List Token) (docs : List (Doc Id Token)) : List Id :=
  match toks with
  | [] => docs.map Prod.fst
  | t :: ts => ts.foldl (fun acc u => acc.filter (fun i => (postings u docs).contains i))
      (postings t docs)

/-- A single-term AND is just its posting list. -/
theorem andQuery_single (t : Token) (docs : List (Doc Id Token)) :
    andQuery [t] docs = postings t docs := rfl

end Inverted
