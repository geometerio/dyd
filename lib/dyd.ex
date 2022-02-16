defmodule Dyd do
  @moduledoc false

  use Application
  @default_config %{mode: "diff", manifest: "dyd.toml"}

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
    Burrito.Util.Args.get_arguments()
    |> parse_args()
    |> run()
  end

  defp parse_args(args) do
    @default_config
    |> parse_args(args)
  end

  defp parse_args(config, args) do
    case args do
      [] ->
        config

      ["--no-halt", "--", "start", _executable | args] ->
        parse_args(config, args)

      ["diff" | args] ->
        %{config | mode: "diff"}
        |> parse_args(args)

      [flag, manifest | args] when flag in ~w{--manifest -m} ->
        %{config | manifest: manifest}
        |> parse_args(args)

      [flag | _args] when flag in ~w{--help -h help} ->
        usage()
        System.halt(0)
    end
  end

  defp run(%{mode: "diff"} = config) do
    Dyd.App.start(config)
  end

  defp usage do
    IO.puts("""
    dyd <options> [command]

    Options:

      -h, --help     -- Prints this message
      -m, --manifest -- Specifies a manifest.toml to diff

    Commands:

      <empty>, diff  -- Opens the diff tool
      info           -- Analyzes the manifest and prints info
    """)
  end
end
