import Config

config :logger,
  backends: [
    {LoggerFileBackend, :file}
  ]

config :logger, :file,
  path: "tmp/dyd.log",
  level: :info

config :dyd, :manifest, "dyd.toml"
