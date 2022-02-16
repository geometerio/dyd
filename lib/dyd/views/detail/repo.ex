defmodule Dyd.Views.Detail.Repo do
  import Ratatouille.View

  def render(%{status: :failed} = repo) do
    label do
      text(content: repo.command_output <> "\n")
    end
  end

  def render(repo, model) do
    table do
      for {log, index} <- Enum.with_index(repo.log_lines) do
        table_row do
          cursor(index, model.cursor)
          table_cell(content: log.sha, color: :yellow)
          table_cell(content: log.age, color: :red)
          table_cell(content: log.author, color: :yellow)
          table_cell(content: log.message)
        end
      end
    end
  end

  def cursor(index, index), do: table_cell(content: "• ")
  def cursor(_index, _cursor), do: table_cell(content: " ")
end
