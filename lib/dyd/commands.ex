defmodule Dyd.Commands do
  @moduledoc false
  use GenServer

  @supervisor Dyd.Commands.Supervisor

  def supervisor, do: @supervisor
  def start_link(args), do: GenServer.start_link(__MODULE__, args, name: __MODULE__)

  def init(_args) do
    Task.Supervisor.start_link(name: @supervisor)
    {:ok, []}
  end

  def run(module, args) do
    Task.Supervisor.async_nolink(@supervisor, module, :run, args)
  end
end
