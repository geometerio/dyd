defmodule Dyd.App do
  @moduledoc false
  @behaviour Ratatouille.App

  import Ratatouille.View
  alias Dyd.Manifest
  alias Dyd.Model
  alias Dyd.Repo
  alias Dyd.Utils
  alias Dyd.Views
  alias Ratatouille.Runtime.Subscription
  require Logger

  @impl true
  def init(%{window: %{height: view_height}}) do
    with {:ok, manifest} <- Manifest.load(),
         {:ok, since} <- Map.get(manifest, :since, "1 week ago") |> Utils.to_datetime() do
      desired_log_lines = view_height - 4

      repos =
        manifest.remotes
        |> Enum.map(fn remote ->
          Repo.new(
            name: remote.name,
            remote: remote.origin,
            desired_log_lines: desired_log_lines,
            since: since
          )
        end)
        |> shuffle()

      Model.new(repos: repos, since: since)
    else
      {:error, error} ->
        Model.error("""
        Unable to load manifest:
        error: #{inspect(error)}
        """)
    end
  end

  @impl true
  def update(model, :tick),
    do: Model.refresh(model)

  def update(model, message),
    do: Model.update(model, message)

  @impl true
  def subscribe(_model) do
    Subscription.interval(250, :tick)
  end

  @impl true
  def render(%{error: error} = model) when not is_nil(error) do
    view do
      row do
        column size: 9 do
          label(content: error)
        end

        column size: 3 do
          Views.Help.render(model)
        end
      end
    end
  end

  def render(model) do
    view do
      row do
        column size: 9 do
          Views.Detail.render(model)
        end

        column size: 3 do
          Views.Repos.render(model)
          Views.Stale.render(model)
          Views.Help.render(model)
        end
      end
    end
  end

  # # #

  defp shuffle(enumerable) do
    seed = todays_seed()
    :rand.seed(:exsplus, {seed, seed, seed})
    Enum.shuffle(enumerable)
  end

  defp todays_seed do
    Date.utc_today()
    |> DateTime.new!(Time.from_seconds_after_midnight(0))
    |> DateTime.to_unix()
  end
end
