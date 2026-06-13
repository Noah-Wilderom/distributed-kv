defmodule Kvx.Store.ShardReplicaTest do
  use ExUnit.Case, async: false

  alias Kvx.Store.Shard

  test "an applied replica put is readable and adopts the primary's version" do
    Shard.apply_replica(4, {:put, "replica-key", "from-primary"}, 7)

    [{pid, _}] = Registry.lookup(Kvx.ShardRegistry, 4)

    assert %{version: 7} = :sys.get_state(pid)

    assert {:ok, "from-primary"} = Shard.get(4, "replica-key")
  end

  test "an applied replica delete removes the key and adopts the version" do
    :ok = Shard.put(5, "replica-delete", "v")

    Shard.apply_replica(5, {:delete, "replica-delete"}, 9)

    [{pid, _}] = Registry.lookup(Kvx.ShardRegistry, 5)
    assert %{version: 9} = :sys.get_state(pid)

    assert {:error, :not_found} = Shard.get(5, "replica-delete")
  end

  test "the shard logs its writes and serves them via since" do
    [{pid, _}] = Registry.lookup(Kvx.ShardRegistry, 6)
    %{version: baseline} = :sys.get_state(pid)

    Shard.put(6, "log-a", 1)
    Shard.put(6, "log-b", 2)
    Shard.delete(6, "log-a")

    assert {:ok, entries} = Shard.since(6, baseline)

    ops =
      entries
      |> Enum.map(fn {_version, op} -> op end)
      |> Enum.filter(fn op -> elem(op, 1) in ["log-a", "log-b"] end)

    assert ops == [{:put, "log-a", 1}, {:put, "log-b", 2}, {:delete, "log-a"}]
  end
end
