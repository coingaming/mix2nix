defmodule Mix2nix.MixProject do
  use Mix.Project
  @app :mix2nix

  def project do
    [
      app: @app,
      version: "0.1.6",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      escript: [main_module: :mix2nix],
      deps: deps(),
      archives: [mix_gleam: "~> 0.6.1"],
      compilers: [:gleam | Mix.compilers()],
      aliases: ["deps.get": ["deps.get", "gleam.deps.get"]],
      preferred_cli_env: ["test.watch": :test],
      erlc_include_path: "build/dev/erlang/#{@app}/include",
      erlc_paths: [
        "build/dev/erlang/#{@app}/_gleam_artefacts",
        "build/dev/erlang/#{@app}/build"
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:hex_core, "~> 0.9"},
      {:hackney, "~> 1.18"},
      {:temp, "~> 0.4"},
      {:mix_test_watch, "~> 1.0", only: [:dev, :test], runtime: false},
      {:gleam_stdlib, "~> 0.27.0"},
      {:gleam_erlang, "~> 0.18.1"},
      {:gleam_http, "~> 3.1"},
      {:gleam_hackney, "~> 1.0"},
      {:glint, "~> 0.11.0"}
    ]
  end
end
