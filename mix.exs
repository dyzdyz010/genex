defmodule Genex.MixProject do
  use Mix.Project

  def project do
    [
      app: :genex,
      version: "0.1.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: releases(),
      config: "config/config.exs",
      description: "Genex application",
      package: package()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :runtime_tools, :wx, :observer],
      mod: {Genex.Application, []}
    ]
  end

  def releases do
    [
      genex: [
        steps: [:assemble, &Burrito.wrap/1],
        burrito: [
          targets: [
            macos: [os: :darwin, cpu: :arm64],
            linux_x86_64: [
              os: :linux,
              cpu: :x86_64
            ],
            windows_x86_64: [os: :windows, cpu: :x86_64]
          ]
        ]
      ]
    ]
  end

  # Package configuration for hex
  defp package do
    [
      files: [
        "lib",
        "priv",
        "mix.exs",
        "README.md",
        ".formatter.exs"
      ],
      executables: ["genex"],
      maintainers: ["Hemifuture Team"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/hemifuture/genex"
      }
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:mdex, "~> 0.3"},
      {:burrito, "~> 1.0"},
      {:phoenix_live_view, "~> 1.0"},
      {:phoenix_html, "~> 4.1"},
      {:phoenix_view, "~> 2.0"},
      {:phoenix_template, "~> 1.0"},
      {:cowboy, "~> 2.12"},
      {:plug_cowboy, "~> 2.7"},
      {:file_system, "~> 1.0"}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end
