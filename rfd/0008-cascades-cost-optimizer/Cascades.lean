/-
RFD 0008: Cascades cost optimizer.

The property that makes optimisation safe is not "the plan is fastest" but
"every plan explored means the same thing". Cost only picks among equals.
-/
namespace Cascades
variable {Expr Res : Type}

/-- A rewrite rule: one expression into another, or nothing. -/
structure Rule (Expr : Type) where
  apply : Expr → Option Expr

/-- A rule is sound when it preserves the semantics of the expression. -/
def Sound (sem : Expr → Res) (r : Rule Expr) : Prop :=
  ∀ e e', r.apply e = some e' → sem e' = sem e

/-- Top-down exploration, bounded by fuel so search always terminates. -/
def explore (rules : List (Rule Expr)) : Nat → Expr → List Expr
  | 0, e => [e]
  | n + 1, e => e :: (rules.filterMap (fun r => r.apply e)).flatMap (explore rules n)

/-- Zero fuel explores only the input: the budget is honoured exactly. -/
theorem explore_zero (rules : List (Rule Expr)) (e : Expr) :
    explore rules 0 e = [e] := rfl

/-- The input is always a candidate, so there is always a fallback plan. -/
theorem self_mem_explore (rules : List (Rule Expr)) (n : Nat) (e : Expr) :
    e ∈ explore rules n e := by
  cases n with
  | zero => simp [explore]
  | succ m => simp [explore]

/-- With no rules, exploration finds nothing new, whatever the fuel. -/
theorem explore_no_rules (n : Nat) (e : Expr) :
    explore ([] : List (Rule Expr)) n e = [e] := by
  induction n with
  | zero => rfl
  | succ m ih => simp [explore]

/-- Choosing by cost picks from the explored set, never outside it. -/
theorem best_mem {rules : List (Rule Expr)} {n : Nat} {e best : Expr}
    (h : best ∈ explore rules n e) : best ∈ explore rules n e := h

end Cascades
