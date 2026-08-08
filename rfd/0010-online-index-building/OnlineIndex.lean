/-
RFD 0010: online index building.

The backfill runs in bounded batches, and must be resumable. The two
lemmas are: every record is indexed exactly once, and a resumed build
equals an uninterrupted one.
-/
namespace OnlineIndex
variable {Rec : Type}

/-- Index one bounded batch, appending to what is already built. -/
def buildStep (state : List Rec) (batch : List Rec) : List Rec :=
  state ++ batch

/-- Run a whole build from a list of batches. -/
def build (batches : List (List Rec)) : List Rec :=
  batches.foldl buildStep []

theorem build_nil : build ([] : List (List Rec)) = [] := rfl

/--
A resumed build equals an uninterrupted one. This is what lets a crashed
backfill restart from its continuation instead of from scratch.
-/
theorem build_resume (a b : List (List Rec)) :
    (b.foldl buildStep (build a)) = build (a ++ b) := by
  simp [build, List.foldl_append]

/-- Every record of a batch reaches the index. -/
theorem mem_buildStep_right {state batch : List Rec} {r : Rec}
    (h : r ∈ batch) : r ∈ buildStep state batch := by
  simp [buildStep]; exact Or.inr h

/-- Nothing already indexed is lost by a later batch. -/
theorem mem_buildStep_left {state batch : List Rec} {r : Rec}
    (h : r ∈ state) : r ∈ buildStep state batch := by
  simp [buildStep]; exact Or.inl h

/-- Folding from any accumulator appends, never reorders or drops. -/
theorem foldl_buildStep (batches : List (List Rec)) (acc : List Rec) :
    batches.foldl buildStep acc = acc ++ batches.flatten := by
  induction batches generalizing acc with
  | nil => simp
  | cons h t ih => simp [buildStep, ih, List.append_assoc]

/-- Indexing exactly once: the built list is the concatenation of batches. -/
theorem build_eq_flatten (batches : List (List Rec)) :
    build batches = batches.flatten := by
  simp [build, foldl_buildStep]

end OnlineIndex
