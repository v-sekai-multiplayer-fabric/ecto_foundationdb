defmodule Ecto.Integration.InOperatorTest do
  @moduledoc """
  RFD 0001: `IN` as a fan-out operator.

  Cribbed from `fdb-record-layer`'s `RecordQueryInJoinPlan`, which "executes
  a child plan once for each of the elements of some `IN` list". The point
  of the operator is `preload`: Ecto's separate-query strategy issues
  `where id in ^ids`, which raised `Unsupported` before this.
  """
  use Ecto.Integration.Case, async: true

  import Ecto.Query

  alias Ecto.Integration.TestRepo
  alias EctoFoundationDB.Schemas.District
  alias EctoFoundationDB.Schemas.User

  @moduletag :integration

  defp put(tenant, w, d, name) do
    TestRepo.insert!(
      %District{d_w_id: w, d_id: d, d_name: name, d_next_o_id: 1},
      prefix: tenant
    )
  end

  describe "single primary key" do
    test "returns one record per element", context do
      tenant = context[:tenant]
      users = for n <- ~w/Alice Bob Charlie/, do: TestRepo.insert!(%User{name: n}, prefix: tenant)
      [a, b, _c] = users

      names =
        from(u in User, where: u.id in ^[a.id, b.id])
        |> TestRepo.all(prefix: tenant)
        |> Enum.map(& &1.name)
        |> Enum.sort()

      assert ["Alice", "Bob"] = names
    end

    test "an empty list selects nothing", context do
      tenant = context[:tenant]
      TestRepo.insert!(%User{name: "Alice"}, prefix: tenant)

      assert [] = from(u in User, where: u.id in ^[]) |> TestRepo.all(prefix: tenant)
    end

    test "a single element behaves like equality", context do
      tenant = context[:tenant]
      user = TestRepo.insert!(%User{name: "Alice"}, prefix: tenant)

      assert [%User{name: "Alice"}] =
               from(u in User, where: u.id in ^[user.id]) |> TestRepo.all(prefix: tenant)
    end

    test "a missing id contributes nothing rather than failing", context do
      tenant = context[:tenant]
      user = TestRepo.insert!(%User{name: "Alice"}, prefix: tenant)
      absent = Ecto.UUID.generate()

      assert [%User{name: "Alice"}] =
               from(u in User, where: u.id in ^[user.id, absent])
               |> TestRepo.all(prefix: tenant)
    end

    test "duplicate elements duplicate results, as the Record Layer does", context do
      tenant = context[:tenant]
      user = TestRepo.insert!(%User{name: "Alice"}, prefix: tenant)

      assert 2 =
               from(u in User, where: u.id in ^[user.id, user.id])
               |> TestRepo.all(prefix: tenant)
               |> length()
    end
  end

  describe "composite primary key" do
    test "IN on a trailing key field with the leading field fixed", context do
      tenant = context[:tenant]
      for d <- 1..5, do: put(tenant, 1, d, "w1d#{d}")
      put(tenant, 2, 1, "w2d1")

      ids =
        from(d in District, where: d.d_w_id == ^1 and d.d_id in ^[2, 4])
        |> TestRepo.all(prefix: tenant)
        |> Enum.map(& &1.d_id)
        |> Enum.sort()

      assert [2, 4] = ids
    end

    test "IN on the leading key field fans out over prefixes", context do
      tenant = context[:tenant]
      for w <- 1..3, d <- 1..2, do: put(tenant, w, d, "w#{w}d#{d}")

      rows =
        from(d in District, where: d.d_w_id in ^[1, 3])
        |> TestRepo.all(prefix: tenant)

      assert 4 = length(rows)
      assert [1, 1, 3, 3] = rows |> Enum.map(& &1.d_w_id) |> Enum.sort()
    end
  end

  describe "refusals" do
    test "two IN clauses are refused rather than multiplied", context do
      tenant = context[:tenant]
      put(tenant, 1, 1, "a")

      assert_raise EctoFoundationDB.Exception.Unsupported, ~r/one `in` per query/, fn ->
        from(d in District, where: d.d_w_id in ^[1, 2] and d.d_id in ^[1, 2])
        |> TestRepo.all(prefix: tenant)
      end
    end

    test "IN on a non-key, non-indexed field is still refused", context do
      tenant = context[:tenant]
      put(tenant, 1, 1, "a")

      assert_raise EctoFoundationDB.Exception.Unsupported, fn ->
        from(d in District, where: d.d_name in ^["a", "b"])
        |> TestRepo.all(prefix: tenant)
      end
    end
  end
end
