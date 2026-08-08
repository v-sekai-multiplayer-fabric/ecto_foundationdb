/-
RFD 0005: lateral join.

Model of `RecordQueryFlatMapPlan`: "executing an inner plan for each row
produced by a driving outer plan and combining the results."
-/
namespace FlatMap
variable {A B : Type}

/-- Inner join: one inner plan per outer row, correlated. -/
def flatMapJoin (outer : List A) (inner : A → List B) : List (A × B) :=
  outer.flatMap (fun a => (inner a).map (fun b => (a, b)))

theorem flatMapJoin_nil_outer (inner : A → List B) :
    flatMapJoin ([] : List A) inner = [] := rfl

/-- An empty inner result drops that outer row. That is the inner-join rule. -/
theorem flatMapJoin_drops_empty (a : A) (inner : A → List B)
    (h : inner a = []) : flatMapJoin [a] inner = [] := by
  simp [flatMapJoin, h]

/--
Left join: identical driving loop, except an empty inner yields one row of
nulls instead of dropping the outer row. Inner and left share one operator.
-/
def leftJoin (outer : List A) (inner : A → List B) : List (A × Option B) :=
  outer.flatMap fun a =>
    match inner a with
    | [] => [(a, none)]
    | bs => bs.map (fun b => (a, some b))

/-- The defining difference from `flatMapJoin`. -/
theorem leftJoin_keeps_empty (a : A) (inner : A → List B)
    (h : inner a = []) : leftJoin [a] inner = [(a, none)] := by
  simp [leftJoin, h]

/-- Outer rows are processed independently, so the loop can be chunked. -/
theorem flatMapJoin_append (a b : List A) (inner : A → List B) :
    flatMapJoin (a ++ b) inner = flatMapJoin a inner ++ flatMapJoin b inner := by
  simp [flatMapJoin, List.flatMap_append]

end FlatMap
