defmodule Kvx.Store.Shard do
  use GenServer

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

  @impl true
  def init(shard_id) do
    table =
      :ets.new(table_name(shard_id), [:named_table, :set, :protected, read_concurrency: true])

    {:ok, %{id: shard_id, table: table, version: 0}}
  end

  @impl true
  def handle_call({:put, key, value}, _from, state) do
    :ets.insert(state.table, {key, value})
    {:reply, :ok, %{state | version: state.version + 1}}
  end

  @impl true
  def handle_call({:delete, key}, _from, state) do
    :ets.delete(state.table, key)
    {:reply, :ok, %{state | version: state.version + 1}}
  end

  defp table_name(shard_id), do: :"kvx_shard_#{shard_id}"
end
