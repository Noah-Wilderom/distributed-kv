defmodule Kvx.Store.RouterTest do
  use ExUnit.Case, async: true

  alias Kvx.Store.Router

  test "shard_for is deterministic" do
    assert Router.shard_for("hello") == Router.shard_for("hello")
  end

  test "shard_for always lands in 0..num_shards-1" do
    for i <- 1..1000 do
      assert Router.shard_for("key_#{i}") in 0..(Router.num_shards() - 1)
    end
  end

  test "distributes keys accross shards" do
    used =
      for i <- 1..1000, into: MapSet.new() do
        Router.shard_for("key_#{i}")
      end

    assert MapSet.size(used) == Router.num_shards()
  end

  test "node_for returns the local node" do
    assert Router.node_for(0) == node()
  end

  test "node_for maps shards across an explicit node" do
    nodes = [:a@x, :b@x, :c@x]
    assert Router.node_for(0, nodes) == :a@x
    assert Router.node_for(1, nodes) == :b@x
    assert Router.node_for(2, nodes) == :c@x
    # wraps: rem(3, 3) == 0
    assert Router.node_for(3, nodes) == :a@x
  end

  test "backup_for is the next node after the primary wrapping" do
    nodes = [:a@x, :b@x, :c@x]
    assert Router.backup_for(0, nodes) == :b@x
    assert Router.backup_for(1, nodes) == :c@x
    # wraps: rem(2 + 1, 3) == 0
    assert Router.backup_for(2, nodes) == :a@x
  end

  test "backup_for is nil on a single-node cluster" do
    assert Router.backup_for(0, [:only@xl]) == nil
  end
end
