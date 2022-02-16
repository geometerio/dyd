defmodule Dyd.Repo do
  use GenServer
  use TypedStruct
  alias Dyd.Commands
  alias Dyd.Gitlog
  require Logger

  @registry Dyd.RepoRegistry

  @type status() :: :checking | :cloning | :pulling | :failed | :log | :finished

  @typedoc "Represents a git repository to diff"
  typedstruct do
    field(:name, String.t(), enforce: true)
    field(:desired_log_lines, integer(), default: 30)
    field(:since, DateTime.t(), enforce: true)
    field(:remote, String.t(), enforce: true)
    field(:status, status(), default: :checking)
    field(:log_lines, list(Gitlog.t()), default: [])
    field(:log_line_count, integer(), default: 0)
    field(:relative_dir, Path.t())
    field(:command_output, String.t(), default: "")
    field(:pid, pid())
  end

  def registry, do: @registry

  def new(attrs) do
    {:ok, pid} =
      GenServer.start_link(__MODULE__, __struct__(attrs),
        name: {:via, Registry, {@registry, Keyword.fetch!(attrs, :name)}}
      )

    GenServer.call(pid, :get_state)
  end

  def fresh?(repo) do
    repo.log_line_count > 0 and
      repo.log_lines
      |> Enum.any?(fn log_line ->
        DateTime.compare(log_line.commit_datetime, repo.since) == :gt
      end)
  end

  def reset(repo) do
    GenServer.call(repo.pid, :reset)
  end

  def stale?(repo) do
    repo.status == :finished && !fresh?(repo)
  end

  @spec init(t()) :: {:ok, t()}
  def init(initial_state) do
    Process.send_after(self(), :run, 100)
    {:ok, %{initial_state | pid: self(), relative_dir: directory(initial_state)}}
  end

  @spec get(t()) :: t()
  def get(repo), do: GenServer.call(repo.pid, :get_state)

  def handle_info(:run, %{status: :checking} = state) do
    present = state.relative_dir |> File.dir?()
    next = present |> if(do: :pulling, else: :cloning)

    Process.send_after(self(), :run, 100)

    Logger.info(
      "[#{__MODULE__}] CHECK directory: #{state.relative_dir}, present: #{inspect(present)}, next: #{next}"
    )

    {:noreply, %{state | status: next}}
  end

  def handle_info(:run, %{status: :cloning} = state) do
    Commands.run(Commands.Git.Clone, [state.relative_dir, state.remote])
    {:noreply, state}
  end

  def handle_info(:run, %{status: :pulling} = state) do
    Commands.run(Commands.Git.Pull, [state.relative_dir, state.remote])
    {:noreply, state}
  end

  def handle_info({:DOWN, _ref, :process, _pid, :normal}, state) do
    {:noreply, state}
  end

  def handle_info({:DOWN, _ref, :process, pid, reason}, state) do
    Logger.warn("[#{__MODULE__}] DOWN message: #{reason}, pid: #{pid}")
    {:noreply, %{state | status: :failed}}
  end

  def handle_info({_ref, {:ok, command, output}}, state)
      when command in [:git_pull, :git_clone] do
    output = String.trim(output)
    Logger.info("[#{__MODULE__}] :#{command} succeeded, output: #{output}")

    Commands.run(Commands.Git.Log, [
      state.relative_dir,
      state.remote,
      [count: state.desired_log_lines]
    ])

    {:noreply, %{state | status: :log, command_output: state.command_output <> output <> "\n\n"}}
  end

  def handle_info({_ref, {:ok, :git_log, {log_lines, count}}}, state) do
    Logger.info("[#{__MODULE__}] :git_log succeeded")

    {:noreply, %{state | status: :finished, log_lines: log_lines, log_line_count: count}}
  end

  def handle_info({_ref, {:error, command, output, status}}, state) do
    output = String.trim(output)
    Logger.error("[#{__MODULE__}] :#{command} failed, status: #{status}, output: #{output}")

    {:noreply,
     %{state | status: :failed, command_output: state.command_output <> output <> "\n\n"}}
  end

  def handle_call(:get_state, _from, state), do: {:reply, state, state}

  def handle_call(:reset, _from, state) do
    send(self(), :run)
    {:reply, :ok, %{state | status: :checking}}
  end

  defp directory(%{remote: remote}) do
    remote_repo = remote |> String.downcase()
    %{"name" => name} = Regex.named_captures(~r/.+\/(?<name>[^\/]+)(\.git)?/, remote_repo)
    Path.join(["repos", "dailydiff_#{name}"])
  end
end
