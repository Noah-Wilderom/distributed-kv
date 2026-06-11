defmodule Kvx.Replication.Replicator do
  alias Kvx.Store.{Router, Shard}

  def replicate(shard_id, op, version) do
    case Router.backup_for(shard_id) do
      nil -> :ok
      backup -> :erpc.cast(backup, Shard, :apply_replica, [shard_id, op, version])
    end
  end
end
