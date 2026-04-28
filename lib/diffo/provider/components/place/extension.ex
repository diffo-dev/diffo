# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Place.Extension do
  @moduledoc """
  DSL Extension customising a Place.

  Provides compile-time declaration blocks for domain-specific Place kinds
  built on `Diffo.Provider.BasePlace`. All declarations are introspectable via
  `Diffo.Provider.Place.Extension.Info`.

  See the [DSL cheat sheet](DSL-Diffo.Provider.Place.Extension.html) for the full DSL reference.
  See `Diffo.Provider.BasePlace` for full usage documentation.
  """
  @instance_role %Spark.Dsl.Entity{
    name: :role,
    describe: "Declares a role this Place kind plays with respect to Instances",
    target: Diffo.Provider.Place.Extension.InstanceRole,
    args: [:role, :instance_type],
    schema: [
      role: [
        type: :atom,
        required: true,
        doc: "The role name, an atom"
      ],
      instance_type: [
        type: :any,
        doc: "The module of the related Instance resource"
      ]
    ]
  }

  @party_role %Spark.Dsl.Entity{
    name: :role,
    describe: "Declares a role this Place kind plays with respect to Parties",
    target: Diffo.Provider.Place.Extension.PartyRole,
    args: [:role, :party_type],
    schema: [
      role: [
        type: :atom,
        required: true,
        doc: "The role name, an atom"
      ],
      party_type: [
        type: :any,
        doc: "The module of the related Party resource"
      ]
    ]
  }

  @place_role %Spark.Dsl.Entity{
    name: :role,
    describe: "Declares a role this Place kind plays with respect to other Places",
    target: Diffo.Provider.Place.Extension.PlaceRole,
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

  @instances %Spark.Dsl.Section{
    name: :instances,
    describe: "Declares the roles this Place kind plays with respect to Instances",
    examples: [
      """
      instances do
        role :site_for, MyApp.AccessService
      end
      """
    ],
    entities: [@instance_role]
  }

  @parties %Spark.Dsl.Section{
    name: :parties,
    describe: "Declares the roles this Place kind plays with respect to Parties",
    examples: [
      """
      parties do
        role :home_of, MyApp.Organization
      end
      """
    ],
    entities: [@party_role]
  }

  @places %Spark.Dsl.Section{
    name: :places,
    describe: "Declares the roles this Place kind plays with respect to other Places",
    examples: [
      """
      places do
        role :within, MyApp.GeographicSite
      end
      """
    ],
    entities: [@place_role]
  }

  use Spark.Dsl.Extension,
    sections: [@instances, @parties, @places]
end
