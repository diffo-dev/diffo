# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Party.Extension do
  @moduledoc """
  DSL Extension customising a Party.

  Provides compile-time declaration blocks for domain-specific Party kinds
  built on `Diffo.Provider.BaseParty`. All declarations are introspectable via
  `Diffo.Provider.Party.Extension.Info`.

  See the [DSL cheat sheet](DSL-Diffo.Provider.Party.Extension.html) for the full DSL reference.
  """
  @role %Spark.Dsl.Entity{
    name: :role,
    describe: "Declares a role this Party kind plays",
    target: Diffo.Provider.Party.Extension.InstanceRole,
    args: [:role, :party_type],
    schema: [
      role: [
        type: :atom,
        required: true,
        doc: "The role name, an atom"
      ],
      party_type: [
        type: :any,
        doc: "The module of the related resource"
      ]
    ]
  }

  @party_role %Spark.Dsl.Entity{
    name: :role,
    describe: "Declares a role this Party kind plays with respect to other Parties",
    target: Diffo.Provider.Party.Extension.PartyRole,
    args: [:role, :party_type],
    schema: [
      role: [
        type: :atom,
        required: true,
        doc: "The role name, an atom"
      ],
      party_type: [
        type: :any,
        doc: "The module of the related Party kind"
      ]
    ]
  }

  @instances %Spark.Dsl.Section{
    name: :instances,
    describe: "Declares the roles this Party kind plays with respect to Instances",
    examples: [
      """
      instances do
        role :facilitates, MyApp.AccessService
      end
      """
    ],
    entities: [@role]
  }

  @parties %Spark.Dsl.Section{
    name: :parties,
    describe: "Declares the roles this Party kind plays with respect to other Parties",
    examples: [
      """
      parties do
        role :managed_by, MyApp.Person
      end
      """
    ],
    entities: [@party_role]
  }

  @place_role %Spark.Dsl.Entity{
    name: :role,
    describe: "Declares a role this Party kind plays with respect to Places",
    target: Diffo.Provider.Party.Extension.PlaceRole,
    args: [:role, :place_type],
    schema: [
      role: [
        type: :atom,
        required: true,
        doc: "The role name, an atom"
      ],
      place_type: [
        type: :any,
        doc: "The module of the related Place resource"
      ]
    ]
  }

  @places %Spark.Dsl.Section{
    name: :places,
    describe: "Declares the roles this Party kind plays with respect to Places",
    examples: [
      """
      places do
        role :headquartered_at, MyApp.GeographicSite
      end
      """
    ],
    entities: [@place_role]
  }

  use Spark.Dsl.Extension,
    sections: [@instances, @parties, @places]
end
