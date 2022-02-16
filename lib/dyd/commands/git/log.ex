defmodule Dyd.Commands.Git.Log do
  alias Dyd.Gitlog
  require Logger

  @name :git_log
  @git_format "%h\v%cI\v%ch\v%an\v%s"

  def run(directory, _remote, opts \\ []) do
    # git_format="%Cred%ar%Creset|%C(yellow)%an%Creset|%s%Creset"
    # date_filter=""
    # timezone="UTC+7" # (Pacific Time) - list all commits one timezone so that the "--after" filter applies in that timezone.
    # TZ="$timezone" git log --date=local ${date_filter:+"$date_filter"} -n 3 --graph \
    #   --abbrev-commit --color=always --pretty=tformat:"${git_format}" | column -t -s '|'

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
