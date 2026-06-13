defmodule Kvx.Store.Shard do
  use GenServer

  @log_capacity 1000

  alias Kvx.Replication.{Replicator, Log}

  def start_link(shard_id) do
    GenServer.start_link(__MODULE__, shard_id, name: via(shard_id))
  end

  defp via(id), do: {:via, Registry, {Kvx.ShardRegistry, id}}

  def get(shard_id, key) do
    case :ets.lookup(table_name(shard_id), key) do
      [{^key, value}] -> {:ok, value}
      [] -> {:error, :not_found}
    end
  end

  def put(shard_id, key, value) do
    GenServer.call(via(shard_id), {:put, key, value})
  end

  def delete(shard_id, key) do
    GenServer.call(via(shard_id), {:delete, key})
  end

  def apply_replica(shard_id, op, version) do
    GenServer.cast(via(shard_id), {:replica, op, version})
  end

  def since(shard_id, version) do
    GenServer.call(via(shard_id), {:since, version})
  end

  def version(shard_id) do
    GenServer.call(via(shard_id), :version)
  end

  @impl true
  def init(shard_id) do
    table =
      :ets.new(table_name(shard_id), [:named_table, :set, :protected, read_concurrency: true])

    {:ok, %{id: shard_id, table: table, version: 0, log: Log.new(@log_capacity)}}
  end

  @impl true
  def handle_call({:put, key, value}, _from, state) do
    new_version = state.version + 1
    op = {:put, key, value}

    :ets.insert(state.table, {key, value})
    Replicator.replicate(state.id, op, new_version)
    log = Log.append(state.log, new_version, op)

    {:reply, :ok, %{state | version: new_version, log: log}}
  end

  @impl true
  def handle_call({:delete, key}, _from, state) do
    new_version = state.version + 1
    op = {:delete, key}

    :ets.delete(state.table, key)
    Replicator.replicate(state.id, op, new_version)
    log = Log.append(state.log, new_version, op)

    {:reply, :ok, %{state | version: new_version, log: log}}
  end

  @impl true
  def handle_call({:since, version}, _from, state) do
    {:reply, Log.since(state.log, version), state}
  end

  @impl true
  def handle_call(:version, _from, state) do
    {:reply, state.version, state}
  end

  @impl true
  def handle_cast({:replica, op, version}, state) do
    case op do
      {:put, key, value} -> :ets.insert(state.table, {key, value})
      {:delete, key} -> :ets.delete(state.table, key)
    end

    {:noreply, %{state | version: version}}
  end

  defp table_name(shard_id), do: :"kvx_shard_#{shard_id}"
end
