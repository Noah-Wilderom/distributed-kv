defmodule Kvx.Store.Router do
  @num_shards 8

  def num_shards, do: @num_shards

  def shard_for(key), do: :erlang.phash2(key, @num_shards)

  def node_for(shard, nodes \\ Kvx.Cluster.Membership.nodes()) do
    Enum.at(nodes, rem(shard, length(nodes)))
  end

  def backup_for(shard, nodes \\ Kvx.Cluster.Membership.nodes())
  def backup_for(_shard, nodes) when length(nodes) < 2, do: nil

  def backup_for(shard, nodes) do
    primary_index = rem(shard, length(nodes))
    backup_index = rem(primary_index + 1, length(nodes))

    Enum.at(nodes, backup_index)
  end
end
