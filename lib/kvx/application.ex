defmodule Kvx.Application do
  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    children = [
      {Registry, keys: :unique, name: Kvx.ShardRegistry},
      Kvx.Cluster.Membership,
      Kvx.Cluster.Monitor,
      Kvx.Replication.Catchup,
      {Kvx.Store.Supervisor, Kvx.Store.Router.num_shards()}
    ]

    result = Supervisor.start_link(children, strategy: :one_for_one, name: Kvx.Supervisor)

    if match?({:ok, _pid}, result) do
      Logger.info("Kvx application started on node #{node()}")
    else
      Logger.error("Failed to start Kvx application: #{inspect(result)}")
    end

    result
  end
end
