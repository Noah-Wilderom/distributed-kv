{_, 0} = System.cmd("epmd", ["-daemon"])

Application.stop(:kvx)
{:ok, _} = :net_kernel.start([:kvx_primary, :shortnames])
{:ok, _} = Application.ensure_all_started(:kvx)

ExUnit.start()
