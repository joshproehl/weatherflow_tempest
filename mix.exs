defmodule WeatherflowTempest.MixProject do
  use Mix.Project

  def project do
    [
      app: :weatherflow_tempest,
      name: "Weatherflow Tempest",
      description: "A library for handling the data from the LAN API for WeatherFlow weather stations.",
      version: "1.0.1",
      elixir: "~> 1.11", # ExDoc 0.29 requires 1.11
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      package: package(),
      deps: deps(),
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

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:jason, "~> 1.0"},
      {:timex, "~> 3.6"},
      {:ex_doc, "~> 0.29", only: :dev, runtime: false}, # Use 0.29 min to get admonition blocks, but not require any higher elixir version than 1.11
      {:phoenix_pubsub, "~> 2.0", only: [:dev, :test]},
    ]
  end

  defp package do
    [
      files: ["lib", "mix.exs", "CHANGELOG.md", "README.md", "LICENSE.md"],
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
      extras: [
        "README.md": [filename: "readme", title: "Weatherflow Tempest"],
        "CHANGELOG.md": [filename: "changelog", title: "Changelog"],
        "LICENSE.md": [filename: "license", title: "License"],
      ],
      main: "readme"
    ]
  end
end
