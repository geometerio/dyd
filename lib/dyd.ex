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

      ["clean" | args] ->
        %{config | mode: "clean"}
        |> parse_args(args)

      ["diff" | args] ->
        %{config | mode: "diff"}
        |> parse_args(args)

      ["info" | args] ->
        %{config | mode: "info"}
        |> parse_args(args)

      [flag, manifest | args] when flag in ~w{--manifest -m} ->
        Application.put_env(:dyd, :manifest, manifest)

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
    with {:ok, manifest} <- Dyd.Manifest.load(),
         {:ok, since} <- manifest.since |> Dyd.Utils.to_datetime() do
      Application.put_env(:dyd, :remotes, manifest.remotes)
      Application.put_env(:dyd, :since, since)
      Dyd.App.start(config)
    else
      {:error, {:invalid_toml, error}} ->
        usage(error)
        System.halt(1)

      {:error, error} ->
        usage(inspect(error))
        System.halt(1)
    end
  end

  defp run(%{mode: "info"}) do
    info()
    |> System.halt()
  end

  defp run(%{mode: "help", error: error}) do
    usage(error)
    |> System.halt()
  end

  defp info do
    import IO.ANSI, only: [bright: 0, red: 0, reset: 0, underline: 0]

    with {:ok, manifest} <- Dyd.Manifest.load(),
         {:ok, _since} <- manifest.since |> Dyd.Utils.to_datetime() do
      IO.puts("#{bright()}#{underline()}Configuration:#{reset()}\n")
      IO.puts("Highlight repos changed since: #{manifest.since}")
      IO.puts("\n#{bright()}#{underline()}Repos:#{reset()}\n")

      Enum.each(manifest.remotes, fn remote ->
        IO.puts("#{bright()}#{remote.name}#{reset()}: #{remote.origin}")
      end)

      0
    else
      {:error, {:invalid_toml, error}} ->
        usage(error)

      {:error, error} ->
        usage(inspect(error))
    end
  end

  defp usage(error) do
    import IO.ANSI, only: [bright: 0, red: 0, reset: 0, underline: 0]

    if error, do: IO.puts("#{red()}#{bright()}*** Error: #{error}\n#{reset()}")

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

    if error, do: 1, else: 0
  end
end
