defmodule Kvx.Store.SupervisorTest do
  use ExUnit.Case, async: false

  alias Kvx.Store.Shard

  test "a killed shard restarts and is usable again" do
    :ok = Shard.put(3, "test-crash", "value")

    [{pid, _}] = Registry.lookup(Kvx.ShardRegistry, 3)

    ref = Process.monitor(pid)
    Process.exit(pid, :kill)
    assert_receive {:DOWN, ^ref, :process, ^pid, :killed}

    new_pid =
      Enum.find_value(1..100, fn _ ->
        case Registry.lookup(Kvx.ShardRegistry, 3) do
          [{new, _}] when new != pid -> new
          _ -> Process.sleep(10) && nil
        end
      end)

    assert is_pid(new_pid)

    assert {:error, :not_found} = Shard.get(3, "test-crash")

    assert :ok = Shard.put(3, "test-after-crash", "value")
    assert {:ok, "value"} = Shard.get(3, "test-after-crash")
  end
end
