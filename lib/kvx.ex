defmodule Kvx do
  alias Kvx.Store.{Router, Shard}

  def put(key, value), do: dispatch(key, :put, [key, value])
  def get(key), do: dispatch(key, :get, [key])
  def delete(key), do: dispatch(key, :delete, [key])

  defp dispatch(key, fun, args) do
    shard = Router.shard_for(key)

    case Router.node_for(shard) do
      n when n == node() -> apply(Shard, fun, [shard | args])
      remote -> :erpc.call(remote, Shard, fun, [shard | args])
    end
  end
end
