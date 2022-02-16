defmodule Dyd do
  @moduledoc false

  use Application
  @default_config %{mode: "diff", manifest: "dyd.toml", error: nil}

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

      ["clean" | args] ->
        %{config | mode: "clean"}
        |> parse_args(args)

      [flag, manifest | args] when flag in ~w{--manifest -m} ->
        %{config | manifest: manifest}
        |> parse_args(args)

      [flag | args] when flag in ~w{--help -h help} ->
        %{config | mode: "help"}
        |> parse_args(args)

      [_flag | args] ->
        %{config | mode: "help", error: "Unknown argument"}
        |> parse_args(args)
    end
  end

  defp run(%{mode: "clean"}) do
    case File.ls("repos") do
      {:error, _posix} ->
        :ok

      {:ok, repos} ->
        IO.puts("Cleaning repos:")

        repos =
          Enum.filter(repos, fn
            "." <> _name -> false
            _ -> true
          end)

        if Enum.empty?(repos),
          do: IO.puts("  already clean"),
          else:
            Enum.each(repos, fn
              repo ->
                IO.puts("  repos/#{repo}")
                File.rm_rf("repos/#{repo}")
            end)
    end

    System.halt(0)
  end

  defp run(%{mode: "diff"} = config) do
    Dyd.App.start(config)
  end

  defp run(%{mode: "help", error: nil}) do
    usage()
    System.halt(0)
  end

  defp run(%{mode: "help", error: error}) do
    import IO.ANSI, only: [bright: 0, red: 0, reset: 0]
    IO.puts("#{red()}#{bright()}*** Error: #{error}\n#{reset()}")
    usage()
    System.halt(1)
  end

  defp usage do
    import IO.ANSI, only: [bright: 0, reset: 0, underline: 0]

    IO.puts("""
    #{bright()}#{underline()}Usage:#{reset()} dyd #{underline()}<options>#{reset()} [command]

    #{bright()}#{underline()}Options:#{reset()}

      -h, --help     -- Prints this message
      -m, --manifest -- Specifies a manifest.toml to diff

    #{bright()}#{underline()}Commands:#{reset()}

      clean          -- Cleans out the repos directory
      <empty>, diff  -- Opens the diff tool
      info           -- Analyzes the manifest and prints info
    """)
  end
end
