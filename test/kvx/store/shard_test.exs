defmodule Kvx.Store.ShardTest do
  use ExUnit.Case, async: false

  alias Kvx.Store.Shard

  setup do
    %{key: "key-#{System.unique_integer([:positive])}"}
  end

  test "put then get returns the value", %{key: key} do
    assert :ok = Shard.put(0, key, "John Doe")
    assert {:ok, "John Doe"} = Shard.get(0, key)
  end

  test "get non-existent key returns not found", %{key: key} do
    assert {:error, :not_found} = Shard.get(0, key)
  end

  test "put overwrites existing value", %{key: key} do
    assert :ok = Shard.put(0, key, "Doe John")
    assert :ok = Shard.put(0, key, "John Doe")
    assert {:ok, "John Doe"} = Shard.get(0, key)
  end

  test "delete removes the key value", %{key: key} do
    assert :ok = Shard.put(0, key, "John Doe")
    assert :ok = Shard.delete(0, key)
    assert {:error, :not_found} = Shard.get(0, key)
  end

  test "delete of non-existing key is no-op", %{key: key} do
    assert :ok = Shard.delete(0, key)
  end
end
