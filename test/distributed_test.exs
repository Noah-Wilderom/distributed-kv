defmodule Kvx.DistributedTest do
  use ExUnit.Case, async: false

  alias Kvx.Cluster.Membership
  alias Kvx.Store.{Router, Shard}

  setup do
    {:ok, peer, peer_node} =
      :peer.start_link(%{
        name: :kvx_peer,
        connection: :standard_io,
        args: Enum.flat_map(:code.get_path(), &[~c"-pa", &1])
      })

    true = Node.connect(peer_node)
    {:ok, _} = :erpc.call(peer_node, Application, :ensure_all_started, [:kvx])

    on_exit(fn ->
      wait_until(fn -> Membership.nodes() == [node()] end)
    end)

    # peer is linked; it dies with
    %{peer: peer, peer_node: peer_node}
  end

  test "a peer node joins the cluster and serves cross-node reads", %{peer_node: peer_node} do
    assert wait_until(fn -> peer_node in Membership.nodes() end)

    assert wait_until(fn ->
             :erpc.call(peer_node, Membership, :nodes, []) == Membership.nodes()
           end)

    :ok = Kvx.put("dist-test-city", "amsterdam")
    assert {:ok, "amsterdam"} = :erpc.call(peer_node, Kvx, :get, ["dist-test-city"])
  end

  test "a write lands on the backup node's local table" do
    assert wait_until(fn ->
             length(Membership.nodes()) ==
               2
           end)

    key = "repl-copy-key"
    shard = Router.shard_for(key)

    :ok = Kvx.put(key, "copied")

    backup = Router.backup_for(shard)

    assert wait_until(fn ->
             :erpc.call(backup, Shard, :get, [shard, key]) ==
               {:ok, "copied"}
           end)
  end

  test "reads survive the primary node dying", %{peer: peer, peer_node: peer_node} do
    assert wait_until(fn -> length(Membership.nodes()) == 2 end)

    key =
      Enum.find(1..1000, fn i ->
        shard = Router.shard_for("failover-key-#{i}")
        Router.node_for(shard) == peer_node
      end)
      |> then(fn i -> "failover-key-#{i}" end)

    assert Router.node_for(Router.shard_for(key)) == peer_node

    :ok = Kvx.put(key, "survives")

    shard = Router.shard_for(key)
    assert wait_until(fn -> Shard.get(shard, key) == {:ok, "survives"} end)

    :peer.stop(peer)

    assert wait_until(fn -> Membership.nodes() == [node()] end)

    assert {:ok, "survives"} = Kvx.get(key)
  end

  test "a reconnecting backup catches up on writes it missed", %{peer_node: peer_node} do
    assert wait_until(fn -> length(Membership.nodes()) == 2 end)

    shard =
      Enum.find(0..(Router.num_shards() - 1), fn s ->
        Router.node_for(s) == node() and Router.backup_for(s) == peer_node
      end)

    refute is_nil(shard)

    :ok = Shard.put(shard, "before", "v1")

    assert wait_until(fn ->
             :erpc.call(peer_node, Shard, :get, [shard, "before"]) ==
               {:ok, "v1"}
           end)

    Node.disconnect(peer_node)
    assert wait_until(fn -> Membership.nodes() == [node()] end)

    :ok = Shard.put(shard, "during", "v2")

    Node.connect(peer_node)
    assert wait_until(fn -> length(Membership.nodes()) == 2 end)

    assert wait_until(fn ->
             length(:erpc.call(peer_node, Membership, :nodes, [])) ==
               2
           end)

    assert wait_until(fn ->
             :erpc.call(peer_node, Shard, :get, [shard, "during"]) ==
               {:ok, "v2"}
           end)
  end

  defp wait_until(fun) do
    Enum.find_value(1..100, fn _ ->
      fun.() || (Process.sleep(10) && nil)
    end)
  end
end
