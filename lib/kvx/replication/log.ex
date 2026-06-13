defmodule Kvx.Replication.Log do
  defstruct [:cap, entries: []]

  def new(cap) do
    %__MODULE__{cap: cap}
  end

  def append(%__MODULE__{} = log, version, op) do
    entries = Enum.take([{version, op} | log.entries], log.cap)
    %{log | entries: entries}
  end

  def since(%__MODULE__{entries: []}, _from), do: {:ok, []}

  def since(%__MODULE__{} = log, from) do
    {oldest_version, _op} = List.last(log.entries)

    if from < oldest_version - 1 do
      {:error, :too_old}
    else
      entries =
        log.entries
        |> Enum.filter(fn {v, _op} -> v > from end)
        |> Enum.reverse()

      {:ok, entries}
    end
  end
end
