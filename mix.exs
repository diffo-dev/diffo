defmodule Diffo.MixProject do
  @moduledoc false
  use Mix.Project

  @version "0.1.1"
  @name :diffo
  @description "TMF Service and Resource Manager with a difference"
  @github_url "https://github.com/diffo-dev/diffo"

  def project do
    [
      app: @name,
      version: @version,
      name: @name,
      description: @description,
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      package: package(),
      elixirc_paths: elixirc_paths(Mix.env()),
      source_url: @github_url,
      homepage_url: "http://diffo.dev/diffo/",
      # hex.pm stuff
      deps: deps(),
      docs: [main: "readme", extras: ["README.md"]],
      aliases: aliases()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Diffo.Application, []}
    ]
  end

  defp ash_neo4j_version(default_version) do
    case System.get_env("ASH_NEO4J_VERSION") do
      nil -> default_version
      "local" -> [path: "../ash_neo4j"]
      "dev" -> [git: "https://github.com/diffo-dev/ash_neo4j"]
      version -> "~> #{version}"
    end
  end

  defp ash_version(default_version) do
    case System.get_env("ASH_VERSION") do
      nil -> default_version
      "local" -> [path: "../ash"]
      "main" -> [git: "https://github.com/ash-project/ash.git"]
      version -> "~> #{version}"
    end
  end

  def docs do
    [
      homepage_url: @github_url,
      source_url: @github_url,
      source_ref: "v#{@version}",
      main: "readme",
      logo: "logos/diffo.jpg",
      extras: [
        "README.md": [title: "Guide"],
        "LICENSE.md": [title: "License"],
        "documentation/dsls/DSL-Diffo.Provider.Instance.md": [
          title: "DSL: Diffo Provider Instance Extension",
          search_data: Spark.Docs.search_data_for(Diffo.Provider.Instance.Extension)
        ]
      ]
    ]
  end

  defp package do
    [
      name: @name,
      licenses: ["MIT"],
      files: ~w(lib .formatter.exs mix.exs README* LICENSE* CHANGELOG* documentation),
      links: %{
        "GitHub" => @github_url,
        "Author's home page" => "https://www.diffo.dev"
      }
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ash_outstanding, "~> 0.2.2"},
      {:ash_jason, "~> 3.0"},
      {:ash_state_machine, "~> 0.2.7"},
      {:ash_neo4j, ash_neo4j_version("~> 0.2.10")},
      {:boltx, "~> 0.0.6"},
      {:ash, ash_version("~> 3.5")},
      {:spark, "~> 2.2.65"},
      {:uuid, "~> 1.1"},
      {:igniter, "~> 0.5", only: [:dev, :test]},
      {:ex_doc, "~> 0.37", only: [:dev, :test], runtime: false}
    ]
  end

  defp aliases() do
    [
      test: ["ash.setup --quiet", "test"],
      setup: "ash.setup",
      docs: ["spark.cheat_sheets", "docs", "spark.replace_doc_links"],
      "spark.cheat_sheets": "spark.cheat_sheets --extensions Diffo.Provider.Instance.Extension",
      "spark.formatter": [
        "spark.formatter --extensions Diffo.Provider.Instance.Extension",
        "format .formatter.exs"
      ]
    ]
  end

  defp elixirc_paths(:test), do: elixirc_paths(:dev) ++ ["test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
