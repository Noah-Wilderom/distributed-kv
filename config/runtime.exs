import Config

config :kvx,
  seed_nodes: "KVX_SEEDS"
  |> System.get_env("")
  |> String.split(",", trim: true)
  |> Enum.map(&String.to_atom/1)
