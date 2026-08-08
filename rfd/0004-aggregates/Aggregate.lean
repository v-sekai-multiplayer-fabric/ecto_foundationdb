/-
RFD 0004: aggregates.

Model of `RecordQueryStreamingAggregationPlan`: fold the stream rather
than materialise it. The append lemma is what licenses chunking the scan
across FoundationDB transactions.
-/
namespace Aggregate
variable {A V : Type}

/-- Fold a scan without materialising it. -/
def foldStream (f : A → V → A) (init : A) (rows : List V) : A :=
  rows.foldl f init

theorem foldStream_nil (f : A → V → A) (init : A) :
    foldStream f init [] = init := rfl

/--
Chunking is sound: folding a batch then continuing equals folding the
whole range. This is the continuation the 5 second transaction limit needs.
-/
theorem foldStream_append (f : A → V → A) (init : A) (a b : List V) :
    foldStream f init (a ++ b) = foldStream f (foldStream f init a) b := by
  simp [foldStream, List.foldl_append]

/-- Counting is a fold, so it chunks by the same lemma. -/
def count (rows : List V) : Nat := foldStream (fun n _ => n + 1) 0 rows

theorem count_eq_length (rows : List V) : count rows = rows.length := by
  simp [count, foldStream]

end Aggregate
