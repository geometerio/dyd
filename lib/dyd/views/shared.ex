defmodule Dyd.Views.Shared do
  def panel_attributes(:stale), do: []
  def panel_attributes(_pane, _selected_pane), do: [:bold]

  def title_color(pane: pane, selected: pane), do: :red
  def title_color(_), do: :white
end
