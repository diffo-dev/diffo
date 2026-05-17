# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.MixProject do
  @moduledoc false
  use Mix.Project

  @version "0.3.0"
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
      source_url: "https://github.com/diffo-dev/diffo/",
      homepage_url: "http://diffo.dev/diffo/",
      elixirc_paths: elixirc_paths(Mix.env()),
      docs: &docs/0,
      deps: deps(),
      aliases: aliases(),
      consolidate_protocols: Mix.env() != :dev,
      usage_rules: usage_rules()
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
        "diffo.livemd": [title: "Tutorial"],
        "documentation/dsls/DSL-Diffo.Provider.Extension.md": [
          title: "DSL: Diffo.Provider.Extension",
          search_data: Spark.Docs.search_data_for(Diffo.Provider.Extension)
        ],
        "documentation/how_to/use_diffo_type.livemd": [title: "Using Diffo.Type"],
        "documentation/how_to/use_diffo_provider_extension.livemd": [
          title: "Using the Diffo Provider Extension"
        ],
        "documentation/how_to/use_diffo_provider_versioning.livemd": [
          title: "Instance Versioning with the Diffo Provider"
        ]
      ],
      groups_for_extras: [
        "How-to": ~r/documentation\/how_to\//,
        Tutorials: ~r/\.livemd$/,
        DSLs: ~r/documentation\/dsls\//
      ]
    ]
  end

  defp package do
    [
      name: :diffo,
      licenses: ["MIT"],
      files: ~w(lib .formatter.exs mix.exs README* LICENSE* usage-rules.md),
      links: %{
        "GitHub" => @github_url,
        "Author's home page" => "https://www.diffo.dev"
      }
    ]
  end

  defp usage_rules do
    [
      file: "CLAUDE.md",
      usage_rules: ["usage_rules:all"],
      skills: [
        location: ".claude/skills",
        build: [
          "diffo-framework": [
            description:
              "Use when working with Diffo or its underlying Ash ecosystem. Consult when making any domain, resource, or provider changes.",
            usage_rules: [:ash, :ash_neo4j, :spark, :reactor, :igniter]
          ]
        ]
      ]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:usage_rules, "~> 1.2", only: [:dev]},
      {:ash_outstanding, "~> 0.2.3"},
      {:ash_jason, "~> 3.0"},
      {:ash_state_machine, "~> 0.2.12"},
      {:ash_neo4j, ash_neo4j_version("~> 0.5")},
      {:bolty, ">= 0.0.12"},
      {:ash, ash_version("~> 3.0 and >= 3.24.2")},
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
      "spark.cheat_sheets":
        "spark.cheat_sheets --extensions Diffo.Provider.Extension",
      "spark.formatter": [
        "spark.formatter --extensions Diffo.Provider.Extension",
        "format .formatter.exs"
      ]
    ]
  end

  defp elixirc_paths(:test), do: elixirc_paths(:dev) ++ ["test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
