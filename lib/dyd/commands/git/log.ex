defmodule Dyd.Commands.Git.Log do
  @moduledoc false
  alias Dyd.Gitlog
  require Logger

  @name :git_log
  @git_format "%h\v%cI\v%ch\v%an\v%s"

  def run(directory, _remote, opts \\ []) do
    count = Keyword.get(opts, :count, 100)

    System.cmd(
      "git",
      [
        "log",
        "--date=local",
        "-n",
        "#{count}",
        "--abbrev-commit",
        "--color=always",
        "--pretty=tformat:\"#{@git_format}\""
      ],
      env: %{"TZ" => "UTC+7"},
      cd: directory,
      stderr_to_stdout: true
    )
    |> case do
      {output, 0} ->
        log_lines = parse(output)
        count = length(log_lines)
        {:ok, @name, {log_lines, count}}

      {output, exit_status} ->
        {:error, @name, output, exit_status}
    end
  end

  defp parse("") do
    []
  end

  defp parse(output) do
    output
    |> String.trim()
    |> String.split("\n")
    |> Enum.map(&String.trim_leading(&1, "\""))
    |> Enum.map(&String.trim_trailing(&1, "\""))
    |> Enum.map(&String.split(&1, "\v"))
    |> Enum.map(fn [sha, commit_datetime, age, author, message] ->
      {:ok, datetime, _utc_offset} = DateTime.from_iso8601(commit_datetime)
      Gitlog.new(sha, datetime, age, author, message)
    end)
  end
end
