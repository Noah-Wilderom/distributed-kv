defmodule Kvx.Cluster.Monitor do
  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, name: Keyword.get(opts, :name, __MODULE__))
  end

  @impl true
  def init(:ok) do
    {:ok, :no_state, {:continue, :connect}}
  end

  @impl true
  def handle_continue(:connect, state) do
    :kvx
    |> Application.get_env(:seed_nodes, [])
    |> Enum.each(&Node.connect/1)

    {:noreply, state}
  end
end
