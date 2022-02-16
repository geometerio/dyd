defmodule Dyd.Difftool do
  @moduledoc false
  require Logger

  def open(model, :vscode) do
    repo = current_repo(model)
    Logger.info("[#{__MODULE__}] opening #{repo.name} in VSCode")
    System.cmd("code", [repo.relative_dir])
  end

  def open(model, :difftool) do
    repo = current_repo(model)
    selected_sha = repo |> sha(model.cursor)
    diff = "#{selected_sha}..head"
    Logger.info("[#{__MODULE__}] opening #{repo.name} in git difftool")
    # System.cmd("git", ["difftool", "-g", diff], cd: repo.relative_dir, parallelism: true)
    "cd #{repo.relative_dir} && git difftool -g #{diff}"
    |> String.to_charlist()
    |> :os.cmd()
  end

  defp current_repo(%{repos: repos, selected_index: index}) do
    repos |> Enum.at(index)
  end

  defp sha(repo, cursor) do
    gitlog = repo.log_lines |> Enum.at(cursor)
    gitlog.sha
  end
end
