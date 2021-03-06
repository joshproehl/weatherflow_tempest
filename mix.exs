defmodule WeatherflowTempest.MixProject do
  use Mix.Project

  def project do
    [
      app: :weatherflow_tempest,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      name: "Weatherflow Tempest",
      docs: docs(),
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {WeatherflowTempest.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
      #{:ex_doc, "~> 0.23", only: :dev, runtime: false}, # Bumped down to older version to maintain Elixir v1.6 compatibility
      {:ex_doc, "~> 0.18.0", only: :dev, runtime: false},
      {:jason, "~> 1.0"},
      {:timex, "~> 3.6"},
      {:phoenix_pubsub, "~> 2.0"},
    ]
  end

  defp description do
    """
    Convert the UDP messages from a WeatherFlow weather station into Phoenix.PubSub messages
    """
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README*", "LICENSE*"],
      maintainers: ["Josh Proehl"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/joshproehl/weatherflow_tempest",
        "Docs" => "https://hexdocs.pm/weatherflow_tempest",
      }
    ]
  end

  defp docs do
    [
      extras: ["README.md": [filename: "readme", title: "Weatherflow Tempest"]],
      main: "readme"
    ]
  end
end
