defmodule Kvx.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Registry, keys: :unique, name: Kvx.ShardRegistry},
      Kvx.Cluster.Membership,
      Kvx.Cluster.Monitor,
      {Kvx.Store.Supervisor, Kvx.Store.Router.num_shards()}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Kvx.Supervisor)
  end
end
