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
      config: "config/config.exs"
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
            # 降低fortify级别
            linux: [
              os: :linux,
              cpu: :x86_64,
              nif_cxxflags: "-U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=0 -O2",
              nif_env: [
                {"CXXFLAGS", "-U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=0 -O2"},
                {"CFLAGS", "-U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=0 -O2"},
                {"LDFLAGS", "-static-libstdc++ -static-libgcc"}
              ],
              # 添加系统库依赖
              system_libs: [
                "/lib/x86_64-linux-gnu/libstdc++.so.6",
                "/lib/x86_64-linux-gnu/libc.so.6",
                "/usr/lib/x86_64-linux-gnu/libgcc_s.so.1"
              ]
            ],
            windows: [os: :windows, cpu: :x86_64]
          ]
        ]
      ]
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
      {:phoenix_template, "~> 1.0"}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end
