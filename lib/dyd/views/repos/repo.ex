defmodule Dyd.Views.Repos.Repo do
  import Ratatouille.View

  def render(repo, selected: selected) when is_boolean(selected) do
    table_row(attributes(selected: selected)) do
      indicator(selected: selected)
      table_cell(content: repo.name, color: color(selected: selected))
      table_cell(content: status(repo.status))
    end
  end

  def render(repo, :stale) do
    table_row(attributes(selected: false)) do
      table_cell(content: "")
      table_cell(content: repo.name, color: :white)
      table_cell(content: "")
    end
  end

  defp attributes(selected: true), do: [attributes: [:bold]]
  defp attributes(selected: false), do: []

  defp color(selected: true), do: :red
  defp color(_), do: :default

  defp indicator(selected: true), do: table_cell(content: "•")
  defp indicator(_), do: table_cell(content: "")

  defp status(:checking), do: "⁇"
  defp status(:cloning), do: "🐝"
  defp status(:failed), do: "𝗫"
  defp status(:finished), do: "✔"
  defp status(:log), do: "🪵"
  defp status(:pulling), do: "⤵"
end
