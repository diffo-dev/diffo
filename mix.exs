defmodule Diffo.MixProject do
  use Mix.Project

  def project do
    [
      app: :diffo,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      elixirc_paths: elixirc_paths(Mix.env()),
      name: "Diffo",
      source_url: "https://github.com/matt-beanland/diffo/",
      homepage_url: "http://diffo.dev/diffo/",
      docs: [
        main: "Diffo.Provider",
        before_closing_body_tag: fn
          :html ->
            """
            <script src="https://cdn.jsdelivr.net/npm/mermaid/dist/mermaid.min.js"></script>
            <script>mermaid.initialize({startOnLoad: true})</script>
            """

          _ ->
            ""
        end
      ]
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

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:outstanding, "~> 0.2.2"},
      {:ash_outstanding, "~> 0.2"},
      {:ash_jason, "~> 2.0"},
      {:ash_state_machine, "~> 0.2.7"},
      {:ash_neo4j, ash_neo4j_version("~> 0.2.3")},
      {:boltx, "~> 0.0.6"},
      {:ash, ash_version("~> 3.5")},
      {:spark, "~> 2.2.65"},
      {:uuid, "~> 1.1"},
      {:igniter, "~> 0.5", only: [:dev, :test]},
      {:ex_doc, "~> 0.37", only: [:dev, :test], runtime: false}
    ]
  end

  defp aliases() do
    [test: ["ash.setup --quiet", "test"], setup: "ash.setup"]
  end

  defp elixirc_paths(:test), do: elixirc_paths(:dev) ++ ["test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
