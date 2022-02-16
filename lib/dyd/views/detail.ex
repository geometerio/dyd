defmodule Dyd.Views.Detail do
  import Ratatouille.View
  alias Dyd.Views.Detail
  alias Dyd.Views.Shared

  def render(model) do
    panel(
      title: name(model.current_repo),
      height: :fill,
      color: Shared.title_color(pane: :detail, selected: model.selected_panel),
      attributes: Shared.panel_attributes(:detail, model.selected_panel)
    ) do
      viewport do
        Detail.Repo.render(model.current_repo, model)
      end
    end
  end

  defp name(%{name: name, status: :finished}), do: name
  defp name(%{name: name, status: status}), do: name <> " — " <> Atom.to_string(status)
end
