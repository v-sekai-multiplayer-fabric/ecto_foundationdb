/-
RFD 0001: `IN` as a fan-out operator.

Model of `RecordQueryInJoinPlan`: "executes a child plan once for each of
the elements of some IN list."
-/
namespace InJoin

/-- Run `get` once per key and concatenate, in key order. -/
def inJoin (keys : List K) (get : K → List V) : List V :=
  keys.flatMap get

/-- The defining equation, stated so the Elixir side has something to match. -/
theorem inJoin_eq_flatMap (keys : List K) (get : K → List V) :
    inJoin keys get = keys.flatMap get := rfl

/-- An empty `IN` list selects nothing. Guards the `x in ^[]` edge case. -/
theorem inJoin_nil (get : K → List V) : inJoin ([] : List K) get = [] := rfl

/-- Fan-out distributes over list append, so batching the list is sound. -/
theorem inJoin_append (a b : List K) (get : K → List V) :
    inJoin (a ++ b) get = inJoin a get ++ inJoin b get := by
  simp [inJoin, List.flatMap_append]

/-- One key is one lookup. -/
theorem inJoin_singleton (k : K) (get : K → List V) :
    inJoin [k] get = get k := by simp [inJoin]

/--
Duplicate keys yield duplicate results: `inJoin` does not deduplicate.
Dedup is therefore the caller's decision, matching the Record Layer.
-/
theorem inJoin_dup (k : K) (get : K → List V) :
    inJoin [k, k] get = get k ++ get k := by simp [inJoin]

end InJoin
