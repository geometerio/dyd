defmodule Dyd.MixProject do
  use Mix.Project

  def project do
    [
      aliases: aliases(),
      app: :dyd,
      deps: deps(),
      elixir: "~> 1.13",
      preferred_cli_env: [credo: :test, dialyzer: :test],
      releases: releases(),
      start_permanent: Mix.env() == :prod,
      version: "0.1.0"
    ]
  end

  def aliases do
    [
      test: "test --no-start"
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Dyd, []}
    ]
  end

  defp deps do
    [
      {:burrito, github: "burrito-elixir/burrito"},
      {:credo, "~> 1.4", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev, :test], runtime: false},
      {:logger_file_backend, "~> 0.0.11"},
      {:mix_audit, "~> 0.1", only: [:dev, :test], runtime: false},
      {:ratatouille, "> 0.0.0"},
      {:toml, "~> 0.6.2"},
      {:typed_struct, "> 0.0.0"},
      {:zigler, github: "ityonemo/zigler"}
    ]
  end

  defp releases do
    [
      dyd: [
        steps: [:assemble, &Burrito.wrap/1],
        burrito: [
          targets: [
            macos_m1: [os: :darwin, cpu: :aarch64]
          ]
        ]
      ]
    ]
  end
end
