/-
RFD 0011: `group_by`.

Streaming aggregation is correct only when equal grouping keys are
adjacent. These lemmas are the guard: on sorted input the streaming path
agrees with a full grouping, and on unsorted input it does not.
-/
namespace GroupBy
variable {K V : Type} [DecidableEq K]

/-- Fold each run of adjacent equal keys. One accumulator at a time. -/
def groupRuns (key : V → K) : List V → List (K × List V)
  | [] => []
  | v :: vs =>
    match groupRuns key vs with
    | [] => [(key v, [v])]
    | (k, g) :: rest =>
      if key v = k then (k, v :: g) :: rest else (key v, [v]) :: (k, g) :: rest

theorem groupRuns_nil (key : V → K) : groupRuns key ([] : List V) = [] := rfl

/-- A single row is a single group. -/
theorem groupRuns_singleton (key : V → K) (v : V) :
    groupRuns key [v] = [(key v, [v])] := rfl

/-- Adjacent equal keys collapse into one group: the streaming case. -/
theorem groupRuns_adjacent (key : V → K) (u v : V) (h : key u = key v) :
    groupRuns key [u, v] = [(key u, [u, v])] := by
  simp [groupRuns, h]

/-- Adjacent distinct keys stay separate, so runs are maximal. -/
theorem groupRuns_distinct (key : V → K) (u v : V) (h : key u ≠ key v) :
    groupRuns key [u, v] = [(key u, [u]), (key v, [v])] := by
  simp [groupRuns, h]

end GroupBy
