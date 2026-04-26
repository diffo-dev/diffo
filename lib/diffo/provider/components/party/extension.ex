# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Party.Extension do
  @moduledoc """
  DSL Extension customising a Party
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

  @instance %Spark.Dsl.Section{
    name: :instance,
    describe: "Declares the roles this Party kind plays with respect to Instances",
    examples: [
      """
      instance do
        role :facilitates, MyApp.AccessService
      end
      """
    ],
    entities: [@role]
  }

  @party %Spark.Dsl.Section{
    name: :party,
    describe: "Declares the roles this Party kind plays with respect to other Parties",
    examples: [
      """
      party do
        role :managed_by, MyApp.Person
      end
      """
    ],
    entities: [@party_role]
  }

  use Spark.Dsl.Extension,
    sections: [@instance, @party]
end
