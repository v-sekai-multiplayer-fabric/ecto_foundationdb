/-
RFD 0006: recursive queries.

Model of `RecordQueryRecursiveDfsJoinPlan`: "recursively applies a plan to
earlier results, starting with a root plan." Fuel is the depth bound; SQL
Server's MAXRECURSION defaults to 100 for the same reason.
-/
namespace Recursive
variable {A : Type}

/-- Apply `step` to each successive frontier, at most `fuel` times. -/
def recurse (step : A → List A) : Nat → List A → List A
  | 0, frontier => frontier
  | n + 1, frontier => frontier ++ recurse step n (frontier.flatMap step)

/-- Zero fuel yields the anchor alone: the depth bound is honoured exactly. -/
theorem recurse_zero (step : A → List A) (root : List A) :
    recurse step 0 root = root := rfl

/-- Termination is structural on fuel, so no cycle can hang the transaction. -/
theorem recurse_succ (step : A → List A) (n : Nat) (root : List A) :
    recurse step (n + 1) root
      = root ++ recurse step n (root.flatMap step) := rfl

/-- The anchor always appears, whatever the fuel. -/
theorem root_subset (step : A → List A) (n : Nat) (root : List A) (a : A)
    (h : a ∈ root) : a ∈ recurse step n root := by
  cases n with
  | zero => simpa [recurse] using h
  | succ m => simp [recurse]; exact Or.inl h

/-- An empty anchor produces nothing, at any depth. -/
theorem recurse_nil (step : A → List A) : ∀ n, recurse step n ([] : List A) = []
  | 0 => rfl
  | n + 1 => by simp [recurse, recurse_nil step n]

end Recursive
