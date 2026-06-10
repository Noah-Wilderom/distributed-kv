defmodule Kvx.Cluster.MembershipTest do
  use ExUnit.Case, async: true

  alias Kvx.Cluster.Membership

  test "fresh membership contains exactly this node" do
    pid = start_supervised!({Membership, name: :mem_test_fresh})
    assert Membership.nodes(pid) == [node()]
  end

  test "nodeup adds the node and keeps the list sorted" do
    pid = start_supervised!({Membership, name: :mem_test_nodeup})
    send(pid, {:nodeup, :a@fake})
    send(pid, {:nodeup, :z@fake})

    assert Membership.nodes(pid) == [:a@fake, node(), :z@fake]
  end

  test "nodedown removes the node" do
    pid = start_supervised!({Membership, name: :mem_test_nodedown})
    send(pid, {:nodeup, :a@fake})
    send(pid, {:nodedown, :a@fake})
    assert Membership.nodes(pid) == [node()]
  end

  test "duplicate nodeup adds only one entry" do
    pid = start_supervised!({Membership, name: :mem_test_dup})
    send(pid, {:nodeup, :a@fake})
    send(pid, {:nodeup, :a@fake})
    assert Membership.nodes(pid) == [:a@fake, node()]
  end
end
