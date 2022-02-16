defmodule Dyd.Commands.Git.Pull do
  @moduledoc false
  require Logger

  @name :git_pull

  def run(directory, _remote, _opts \\ []) do
    Logger.info("[#{__MODULE__}] pulling #{directory}")

    System.cmd("git", ["pull", "--rebase"], cd: directory, stderr_to_stdout: true)
    |> case do
      {output, 0} -> {:ok, @name, output}
      {output, exit_status} -> {:error, @name, output, exit_status}
    end
  end
end
