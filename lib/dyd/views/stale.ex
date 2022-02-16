defmodule Dyd.Views.Stale do
  @moduledoc false
  import Ratatouille.View
  alias Dyd.Views.Repos
  alias Dyd.Views.Shared

  def render(model) do
    panel(
      title: "Stale (since #{inspect(model.since)})",
      color: Shared.title_color(:stale),
      attributes: Shared.panel_attributes(:stale)
    ) do
      table do
        for {repo, _index} <- Enum.with_index(model.stale) do
          Repos.Repo.render(repo, :stale)
        end
      end
    end
  end
end
