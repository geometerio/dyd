defmodule Dyd.Manifest do
  require Logger

  defmodule Remote do
    @type t() :: %__MODULE__{
            name: String.t(),
            origin: String.t()
          }
    defstruct [:name, :origin]
  end

  defmodule RemotesToList do
    use Toml.Transform

    def transform(:remotes, remotes) when is_map(remotes) do
      for {_identifier, remote} <- remotes do
        struct(Remote, remote)
      end
    end

    def transform(_k, v), do: v
  end

  defmodule Since do
    use Toml.Transform

    def transform(:since, since), do: since

    def transform(k, v) do
      Logger.error("other: #{k}, #{inspect(v)}")
      v
    end
  end

  @spec load() :: {:ok, %{remotes: [Remote.t()]}} | {:error, any()}
  def load do
    with {:ok, path} <- manifest_path(),
         {:ok, manifest} <- File.read(path),
         {:ok, %{remotes: _remotes} = config} <-
           Toml.decode(manifest, keys: :atoms, transforms: [RemotesToList, Since]) do
      {:ok, config}
    end
  end

  defp manifest_path do
    filename = System.get_env("MANIFEST") |> default_manifest_name() |> ensure_toml_extension()
    path = Path.join(["manifest", filename])

    if File.exists?(path),
      do: {:ok, path},
      else: {:error, "Manifest not found at: #{path}"}
  end

  defp blank?(s),
    do: s == nil || String.trim(s) == ""

  defp default_manifest_name(filename) do
    if blank?(filename),
      do: "default.toml",
      else: filename
  end

  defp ensure_toml_extension(filename) do
    if String.ends_with?(filename, ".toml"),
      do: filename,
      else: filename <> ".toml"
  end
end