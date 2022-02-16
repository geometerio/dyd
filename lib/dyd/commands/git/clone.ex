defmodule Dyd.Commands.Git.Clone do
  @moduledoc false
  require Logger

  @name :git_clone

  def run(directory, remote, _opts \\ []) do
    Logger.info("[#{__MODULE__}] cloning #{remote} into #{directory}")

    System.cmd("git", ["clone", remote, directory], stderr_to_stdout: true)
    |> case do
      {output, 0} -> {:ok, @name, output}
      {output, exit_status} -> {:error, @name, output, exit_status}
    end
  end
end
