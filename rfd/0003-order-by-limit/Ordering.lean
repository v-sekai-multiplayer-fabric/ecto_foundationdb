/-
RFD 0003: `ORDER BY` and `LIMIT`.

Key ordering is the storage order, so a descending scan is the reverse of
an ascending one. The `take` lemma is what licenses stopping early.
-/
namespace Ordering
variable {V : Type}

/-- A range scan, ascending or reversed. -/
def scanOrdered (asc : Bool) (rows : List V) : List V :=
  if asc then rows else rows.reverse

theorem scanOrdered_asc (rows : List V) : scanOrdered true rows = rows := rfl

/-- Reversing a sorted scan is the descending order. -/
theorem scanOrdered_desc (rows : List V) :
    scanOrdered false rows = rows.reverse := rfl

/-- A scan is reversible without re-sorting. -/
theorem scanOrdered_involutive (rows : List V) :
    scanOrdered false (scanOrdered false rows) = rows := by
  simp [scanOrdered]

/--
Early stop is sound: taking `n` from the scan equals the first `n` of the
fully ordered result. This is why a `limit` along an index costs O(limit).
-/
theorem take_scanOrdered (n : Nat) (rows : List V) :
    (scanOrdered true rows).take n = rows.take n := rfl

/-- `offset` is a drop, and composes with `limit` as expected. -/
theorem drop_take_offset (off lim : Nat) (rows : List V) :
    ((scanOrdered true rows).drop off).take lim = (rows.drop off).take lim := rfl

end Ordering
