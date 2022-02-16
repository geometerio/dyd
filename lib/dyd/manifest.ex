defmodule Dyd.Manifest do
  @moduledoc false
  require Logger

  defmodule Remote do
    @moduledoc false
    @type t() :: %__MODULE__{
            name: String.t(),
            origin: String.t()
          }
    defstruct [:name, :origin]
  end

  defmodule RemotesToList do
    @moduledoc false
    use Toml.Transform

    def transform(:remotes, remotes) when is_map(remotes) do
      for {_identifier, remote} <- remotes do
        struct(Remote, remote)
      end
    end

    def transform(_k, v), do: v
  end

  defmodule Since do
    @moduledoc false
    use Toml.Transform

    def transform(:since, since), do: since

    def transform(k, v) do
      Logger.error("other: #{k}, #{inspect(v)}")
      v
    end
  end

  @type manifest_t() :: %{remotes: [Remote.t()], since: String.t()}

  @spec load() :: {:ok, manifest_t()} | {:error, any()}
  def load do
    with {:ok, path} <- manifest_path(),
         {:ok, manifest} <- File.read(path),
         {:ok, %{remotes: _remotes} = config} <-
           Toml.decode(manifest, keys: :atoms, transforms: [RemotesToList, Since]) do
      config =
        config
        |> Map.put_new(:since, "1 week ago")
        |> Map.put(:remotes, Enum.sort_by(config.remotes, & &1.name))

      {:ok, config}
    end
  end

  defp manifest_path do
    path = Application.fetch_env!(:dyd, :manifest)

    if !blank?(path) && File.exists?(path),
      do: {:ok, path},
      else: {:error, "Manifest not found at: #{path}"}
  end

  defp blank?(s),
    do: s == nil || String.trim(s) == ""
end
