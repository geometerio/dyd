defmodule Dyd do
  @moduledoc false

  use Application

  @doc """
  The `Ratatouille.Runtime.Supervisor` passes the `:runtime` option to `Ratatouille.Runtime.start_link/1`.

  ## Quit events:

  * `{:ch, ?q}`, `{:ch, ?Q}` - q / Q
  * `{:key, 3}` - ctrl-c
  * `{:key, 4}` - ctrl-d

  ## References:

  * https://hexdocs.pm/ratatouille/Ratatouille.Runtime.html#start_link/1
  """
  def start(_type, _args) do
    setup_log_dir()

    runtime = [
      app: Dyd.App,
      interval: 250,
      quit_events: [{:ch, ?q}, {:ch, ?Q}, {:key, 3}, {:key, 4}],
      shutdown: :system
    ]

    children = [
      {Registry, keys: :unique, name: Dyd.Repo.registry()},
      Dyd.Commands,
      {Ratatouille.Runtime.Supervisor, runtime: runtime}
    ]

    opts = [strategy: :one_for_one, name: Dyd.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp setup_log_dir do
    Application.get_env(:logger, :file)
    |> Keyword.fetch!(:path)
    |> Path.dirname()
    |> File.mkdir_p()
  end
end
