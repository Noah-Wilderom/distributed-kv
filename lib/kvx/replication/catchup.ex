defmodule Kvx.Replication.Catchup do
  alias Kvx.Cluster.Membership
  alias Kvx.Store.{Router, Shard}
  require Logger

  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, name: Keyword.get(opts, :name, __MODULE__))
  end

  @impl true
  def init(:ok) do
    :net_kernel.monitor_nodes(true)
    {:ok, :no_state}
  end

  @impl true
  def handle_info({:nodeup, joined}, state) do
    spawn(fn ->
      wait_until(fn -> joined in Membership.nodes() end)
      Enum.each(0..(Router.num_shards() - 1), &sync/1)
    end)

    {:noreply, state}
  end

  @impl true
  def handle_info({:nodedown, _left}, state), do: {:noreply, state}

  def sync(shard_id) do
    nodes = Membership.nodes()
    primary = Router.node_for(shard_id, nodes)
    backup = Router.backup_for(shard_id, nodes)

    if backup == node() && primary != node() do
      catch_up_from(shard_id, primary)
    else
      :noop
    end
  end

  defp catch_up_from(shard_id, primary) do
    my_version = Shard.version(shard_id)

    try do
      :erpc.call(primary, Shard, :since, [shard_id, my_version])
    catch
      kind, reason ->
        Logger.debug(
          "shard #{shard_id} catch-up from #{primary} skipped (#{inspect(kind)}: #{inspect(reason)})"
        )

        {:error, :unavailable}
    else
      {:ok, entries} ->
        Enum.each(entries, fn {version, op} -> Shard.apply_replica(shard_id, op, version) end)
        :ok

      {:error, :too_old} ->
        Logger.warning("shard #{shard_id} is too far behind #{primary}; full resync needed")
        {:error, :too_old}
    end
  end

  defp wait_until(fun) do
    Enum.find_value(1..200, fn _ -> fun.() || (Process.sleep(10) && nil) end)
  end
end
