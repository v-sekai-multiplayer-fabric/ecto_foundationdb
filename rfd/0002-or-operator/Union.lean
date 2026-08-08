/-
RFD 0002: `OR` as an unordered union.

Model of `RecordQueryUnorderedUnionPlan`. The point of interest is dedup:
a row satisfying both branches must appear once.
-/
namespace Union
variable {K V : Type} [DecidableEq K]

/-- Concatenate two branches, dropping rows of `b` whose key already appears in `a`. -/
def unionBy (key : V → K) (a b : List V) : List V :=
  a ++ b.filter (fun v => !a.any (fun w => key w == key v))

/-- A branch unioned with nothing is itself. -/
theorem unionBy_nil (key : V → K) (a : List V) : unionBy key a [] = a := by
  simp [unionBy]

/-- Every row of the left branch survives. -/
theorem mem_of_mem_left {key : V → K} {a b : List V} {v : V}
    (h : v ∈ a) : v ∈ unionBy key a b := by
  simp [unionBy, h]

/-- A row of the right branch survives exactly when its key is new. -/
theorem mem_right {key : V → K} {a b : List V} {v : V}
    (hb : v ∈ b) (hnew : ∀ w ∈ a, key w ≠ key v) :
    v ∈ unionBy key a b := by
  simp [unionBy]
  exact Or.inr ⟨hb, hnew⟩

end Union
