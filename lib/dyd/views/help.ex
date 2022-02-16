defmodule Dyd.Views.Help do
  @moduledoc false
  import Ratatouille.View
  alias Dyd.Views.Shared

  def render(model) do
    panel(
      title: "Help",
      color: Shared.title_color(pane: :help, selected: model.selected_panel),
      attributes: Shared.panel_attributes(:detail, model.selected_panel)
    ) do
      table do
        table_row do
          table_cell(content: "q", attributes: [:bold])
          table_cell(content: "quit")
        end

        table_row do
          table_cell(content: "hjkl", attributes: [:bold])
          table_cell(content: "navigation")
        end

        table_row do
          table_cell(content: "→↑↓←", attributes: [:bold])
          table_cell(content: "navigation")
        end

        table_row do
          table_cell(content: "enter", attributes: [:bold])
          table_cell(content: "open vscode")
        end

        table_row do
          table_cell(content: "v", attributes: [:bold])
          table_cell(content: "open vscode")
        end

        table_row do
          table_cell(content: "d", attributes: [:bold])
          table_cell(content: "open git difftool")
        end

        table_row do
          table_cell(content: "r", attributes: [:bold])
          table_cell(content: "refresh repos")
        end
      end
    end
  end
end
