defmodule Dyd.Views.Repos do
  @moduledoc false
  import Ratatouille.View
  alias Dyd.Views.Repos
  alias Dyd.Views.Shared

  def render(model) do
    panel(
      title: "Repositories",
      color: Shared.title_color(pane: :repos, selected: model.selected_panel),
      attributes: Shared.panel_attributes(:detail, model.selected_panel)
    ) do
      table do
        for {repo, index} <- Enum.with_index(model.repos) do
          Repos.Repo.render(repo, selected: model.selected_index == index)
        end
      end
    end
  end
end
