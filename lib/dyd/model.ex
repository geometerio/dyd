defmodule Dyd.Model do
  @moduledoc false
  use TypedStruct
  import Ratatouille.Constants, only: [key: 1]
  alias Dyd.Repo
  require Logger

  @left key(:arrow_left)
  @down key(:arrow_down)
  @right key(:arrow_right)
  @up key(:arrow_up)
  @tab key(:tab)
  @enter key(:enter)

  @type panel() :: :detail | :repos

  @typedoc "The core Ratatouille model keeping state"
  typedstruct do
    field(:error, binary())
    field(:current_repo, Repo)
    field(:cursor, integer(), default: 0)
    field(:repos, list(Repo), enforce: true)
    field(:stale, list(Repo), enforce: true)
    field(:since, String.t(), enforce: true)
    field(:max_repo_index, integer(), enforce: true)
    field(:selected_index, integer(), default: 0)
    field(:selected_panel, panel(), default: :repos)
  end

  def new(repos: repos, since: since) do
    current_repo = repos |> List.first()

    __struct__(
      current_repo: current_repo,
      repos: repos,
      stale: [],
      since: since,
      max_repo_index: length(repos) - 1
    )
  end

  def error(error) do
    __struct__(error: error, repos: [], stale: [], since: "", max_repo_index: 0)
  end

  def refresh(model) do
    {stale, repos} =
      model.repos
      |> Enum.map(&Repo.get/1)
      |> Enum.split_with(fn repo -> Repo.stale?(repo) end)

    stale =
      (model.stale ++ stale)
      |> Enum.map(fn repo -> %{repo | status: :finished} end)
      |> Enum.sort()

    %{model | repos: repos, stale: stale, max_repo_index: length(repos) - 1}
    |> set_current_repo()
  end

  def reset(model) do
    Enum.each(model.repos, &Repo.reset/1)
    model
  end

  # credo:disable-for-lines:65 Credo.Check.Refactor.CyclomaticComplexity
  def update(model, msg) do
    case {model, msg} do
      {_, {:event, %{ch: ch, key: key}}} when key == @enter or ch == ?v ->
        Dyd.Difftool.open(model, :vscode)
        model

      {_, {:event, %{ch: ?d}}} ->
        Dyd.Difftool.open(model, :difftool)
        model

      {_, {:event, %{ch: ch, key: key}}} when ch == ?h or key == @left ->
        select_panel(model, :detail)

      {_, {:event, %{ch: ?h}}} ->
        select_panel(model, :detail)

      {_, {:event, %{key: @right}}} ->
        select_panel(model, :repos)

      {_, {:event, %{ch: ?l}}} ->
        select_panel(model, :repos)

      {%{selected_panel: :detail}, {:event, %{key: @tab}}} ->
        select_panel(model, :repos)

      {%{selected_panel: :detail}, {:event, %{key: @down}}} ->
        %{model | cursor: cursor(model, :increment)}

      {%{selected_panel: :detail}, {:event, %{ch: ?0}}} ->
        %{model | cursor: 0}

      {%{selected_panel: :detail}, {:event, %{ch: ?j}}} ->
        %{model | cursor: cursor(model, :increment)}

      {%{selected_panel: :detail}, {:event, %{key: @up}}} ->
        %{model | cursor: cursor(model, :decrement)}

      {%{selected_panel: :detail}, {:event, %{ch: ?k}}} ->
        %{model | cursor: cursor(model, :decrement)}

      {%{selected_panel: :repos}, {:event, %{key: @tab}}} ->
        select_panel(model, :detail)

      {%{selected_panel: :repos}, {:event, %{ch: ?0}}} ->
        %{model | selected_index: 0, cursor: 0}

      {%{selected_panel: :repos}, {:event, %{key: @down}}} ->
        select_repo(model, :increment)

      {%{selected_panel: :repos}, {:event, %{ch: ?j}}} ->
        select_repo(model, :increment)

      {%{selected_panel: :repos}, {:event, %{key: @up}}} ->
        select_repo(model, :decrement)

      {%{selected_panel: :repos}, {:event, %{ch: ?k}}} ->
        select_repo(model, :decrement)

      {_, {:event, %{ch: ?r}}} ->
        reset(model)

      {_, event} ->
        Logger.warn("[#{__MODULE__}] event #{inspect(event)}")
        model
    end
  end

  defp cursor(%{cursor: 0}, :decrement), do: 0
  defp cursor(%{cursor: cursor}, :decrement), do: cursor - 1

  defp cursor(%{cursor: cursor, current_repo: %{log_line_count: count}}, :increment)
       when count == cursor + 1,
       do: cursor

  defp cursor(%{cursor: cursor}, :increment), do: cursor + 1

  defp select_repo(%{selected_index: 0} = model, :decrement), do: %{model | cursor: 0}

  defp select_repo(%{selected_index: index} = model, :decrement),
    do:
      %{model | selected_index: index - 1, cursor: 0}
      |> set_current_repo()

  defp select_repo(%{max_repo_index: max, selected_index: max} = model, :increment),
    do: %{model | cursor: 0}

  defp select_repo(%{selected_index: index} = model, :increment),
    do:
      %{model | selected_index: index + 1, cursor: 0}
      |> set_current_repo()

  defp select_panel(model, panel), do: %{model | selected_panel: panel}

  defp set_current_repo(model) do
    %{model | current_repo: Enum.at(model.repos, model.selected_index)}
  end
end
