defmodule KvxTest do
  use ExUnit.Case, async: false

  test "put, get, delete round trip" do
    assert :ok = Kvx.put("hello", "world")
    assert {:ok, "world"} = Kvx.get("hello")
    assert :ok = Kvx.delete("hello")
    assert {:error, :not_found} = Kvx.get("hello")
  end

  test "values can be any term" do
    assert :ok = Kvx.put("number", 42)
    assert {:ok, 42} = Kvx.get("number")

    assert :ok = Kvx.put("list", [1, 2, 3])
    assert {:ok, [1, 2, 3]} = Kvx.get("list")

    assert :ok = Kvx.put("map", %{a: 1, b: 2})
    assert {:ok, %{a: 1, b: 2}} = Kvx.get("map")

    assert :ok = Kvx.put("tuple", {:ok, "value"})
    assert {:ok, {:ok, "value"}} = Kvx.get("tuple")
  end

  test "100 keys round trip across all shards" do
    for i <- 1..100 do
      assert :ok = Kvx.put("key-#{i}", "value-#{i}")
    end

    for i <- 1..100 do
      expected = "value-#{i}"
      assert {:ok, ^expected} = Kvx.get("key-#{i}")
    end
  end
end
