defmodule Kvx.Store.Router do
  @num_shards 8

  def num_shards, do: @num_shards

  def shard_for(key), do: :erlang.phash2(key, @num_shards)

  def node_for(_shard), do: node()
end
