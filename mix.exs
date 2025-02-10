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
      elixirc_paths: elixirc_paths(Mix.env())
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Diffo.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:simple_sat, "~> 0.1.3"},
      {:ash_state_machine, "~> 0.2.7"},
      {:ash_jason, git: "https://github.com/vonagam/ash_jason", branch: "master"},#{:ash_jason, "~> 1.2"},
      {:spark, ">= 2.1.21 and < 3.0.0"},
      {:ash_postgres, "~> 2.0"},
      {:ash, "~> 3.4"},
      {:igniter, "~> 0.3"},
      # {:phoenix, "~> 1.7.14"},
      {:uuid, "~> 1.1"},
      {:ex_doc, "~> 0.12"},
      # {:aja, "~>0.7"},
      {:untangle, "~> 0.3"}
    ]
  end

  defp aliases() do
    [test: ["ash.setup --quiet", "test"], setup: "ash.setup"]
  end

  defp elixirc_paths(:test), do: elixirc_paths(:dev) ++ ["test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
