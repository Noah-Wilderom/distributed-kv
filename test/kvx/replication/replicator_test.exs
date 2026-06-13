defmodule Kvx.Replication.ReplicatorTest do
  use ExUnit.Case, async: false

  alias Kvx.Replication.Replicator

  test "replicate is a no-op when there is no backup (single node)" do
    assert Replicator.replicate(0, {:put, "repl-unit-key", "v"}, 1) == :ok
  end
end
