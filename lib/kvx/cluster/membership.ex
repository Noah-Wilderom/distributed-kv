defmodule Kvx.Cluster.Membership do
  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, name: Keyword.get(opts, :name, __MODULE__))
  end

  def nodes(server \\ __MODULE__) do
    GenServer.call(server, :nodes)
  end

  @impl true
  def init(:ok) do
    :net_kernel.monitor_nodes(true)
    {:ok, Enum.sort([node() | Node.list()])}
  end

  @impl true
  def handle_call(:nodes, _from, nodes) do
    {:reply, nodes, nodes}
  end

  @impl true
  def handle_info({:nodeup, node}, nodes) do
    nodes = Enum.uniq(Enum.sort([node | nodes]))
    {:noreply, nodes}
  end

  @impl true
  def handle_info({:nodedown, node}, nodes) do
    {:noreply, List.delete(nodes, node)}
  end
end
