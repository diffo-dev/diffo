# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.DomainFragment do
  @moduledoc """
  Domain fragment for Ash domains that extend the Diffo Provider.

  Include this fragment in any domain whose resources need to participate in provider
  polymorphism — i.e., where `belongs_to :instance, Diffo.Provider.Instance` or
  `belongs_to :party, Diffo.Provider.Party` relationships must resolve via `manage_relationship`.

  Adding this fragment causes AshNeo4j to write `:Provider` as an additional label on every
  node in the domain at CREATE time. Because AshNeo4j MATCH patterns include all node labels,
  `Ash.get(Diffo.Provider.Instance, uuid)` (which matches on `[:Provider, :Instance]`) will
  then find concrete instance nodes (e.g. `ShelfInstance`) that carry both `:Instance` (from
  `BaseInstance`) and `:Provider` (from this fragment).

  ## Usage

      defmodule MyApp.SRM do
        use Ash.Domain, fragments: [Diffo.Provider.DomainFragment]
        ...
      end
  """
  use Spark.Dsl.Fragment,
    of: Ash.Domain,
    extensions: [AshNeo4j.DataLayer.Domain]

  neo4j do
    label :Provider
  end
end
