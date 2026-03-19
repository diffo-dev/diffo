# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.MixProject do
  @moduledoc false
  use Mix.Project

  @version "0.1.5"
  @name "Diffo"
  @description "TMF Service and Resource Manager with a difference"
  @github_url "https://github.com/diffo-dev/diffo"

  def project do
    [
      app: :diffo,
      version: @version,
      name: @name,
      description: @description,
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      package: package(),
      # ex_doc
      source_url: "https://github.com/diffo-dev/diffo/",
      homepage_url: "http://diffo.dev/diffo/",
      docs: [main: "readme", extras: ["README.md"]],
      elixirc_paths: elixirc_paths(Mix.env()),
      # hex.pm stuff
      deps: deps(),
      docs: &docs/0,
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
        "LICENSES/MIT.md": [title: "License"],
        "documentation/dsls/DSL-Diffo.Provider.Instance.Extension.md": [
          title: "DSL: Diffo.Provider.Instance.Extension",
          search_data: Spark.Docs.search_data_for(Diffo.Provider.Instance.Extension)
        ]
      ]
    ]
  end

  defp package do
    [
      name: :diffo,
      licenses: ["MIT"],
      files: ~w(lib .formatter.exs mix.exs README* LICENSE*),
      links: %{
        "GitHub" => @github_url,
        "Author's home page" => "https://www.diffo.dev"
      }
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ash_outstanding, "~> 0.2.3"},
      {:ash_jason, "~> 3.0"},
      {:ash_state_machine, "~> 0.2.12"},
      {:ash_neo4j, ash_neo4j_version("~> 0.2.14")},
      {:ash, ash_version("~> 3.0 and >= 3.19.1")},
      {:uuid, "~> 1.1"},
      {:igniter, ">= 0.6.29 and < 1.0.0-0",
       [env: :prod, hex: "igniter", repo: "hexpm", optional: true]},
      {:ex_doc, "~> 0.37", only: [:dev, :test], runtime: false}
    ]
  end

  defp aliases() do
    [
      test: ["ash.setup --quiet", "test"],
      setup: "ash.setup",
      docs: [
        "spark.cheat_sheets",
        "docs",
        "spark.replace_doc_links"
      ],
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
