defmodule Kvx.Store.Supervisor do
  use Supervisor

  def start_link(num_shards) do
    Supervisor.start_link(__MODULE__, num_shards, name: __MODULE__)
  end

  @impl true
  def init(num_shards) do
    children =
      for shard_id <- 0..(num_shards - 1) do
        Supervisor.child_spec({Kvx.Store.Shard, shard_id}, id: {:shard, shard_id})
      end

    Supervisor.init(children, strategy: :one_for_one)
  end
end
