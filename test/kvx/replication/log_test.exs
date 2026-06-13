defmodule Kvx.Replication.LogTest do
  use ExUnit.Case, async: true

  alias Kvx.Replication.Log

  test "a new log hands out nothing" do
    assert Log.since(Log.new(10), 0) == {:ok, []}
  end

  test "since returns newer entries in ascending order" do
    log =
      Log.new(10)
      |> Log.append(1, {:put, "k1", 1})
      |> Log.append(2, {:put, "k2", 2})
      |> Log.append(3, {:put, "k3", 3})

    assert Log.since(log, 1) == {:ok, [{2, {:put, "k2", 2}}, {3, {:put, "k3", 3}}]}
  end

  test "since from the latest version is empty" do
    log =
      Log.new(10)
      |> Log.append(1, {:put, "k1", 1})
      |> Log.append(2, {:put, "k2", 2})

    assert Log.since(log, 2) == {:ok, []}
  end
end
