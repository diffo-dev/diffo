# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Instance.Extension do
  @moduledoc """
  DSL Extension customising an Instance.

  Provides compile-time declaration blocks for domain-specific Service and Resource kinds
  built on `Diffo.Provider.BaseInstance`. All declarations are introspectable via
  `Diffo.Provider.Instance.Extension.Info`.

  See the [DSL cheat sheet](DSL-Diffo.Provider.Instance.Extension.html) for the full DSL reference.
  See `Diffo.Provider.BaseInstance` for full usage documentation.
  """
  @specification %Spark.Dsl.Section{
    name: :specification,
    describe: "Defines the Instance Specification",
    examples: [
      """
      specification do
        id "da9b207a-26c3-451d-8abd-0640c6349979"
        name "DSL Access Service"
        type :serviceSpecification
        major_version 1
        description "An access network service connecting a subscriber premises to an access NNI via DSL"
        category "Network Service"
      end
      """
    ],
    schema: [
      id: [
        type: :string,
        doc: """
        The id of the specification, a uuid4 the same in all environments, unique for name and major_version.
        """,
        required: true
      ],
      name: [
        type: :string,
        doc: """
        The name of the specification, unique to a service but common for all versions.
        """,
        required: true
      ],
      type: [
        type: :atom,
        doc: """
        The type of the specification.
        """,
        default: :serviceSpecification
      ],
      major_version: [
        type: :integer,
        doc: """
        The major_version of the specification.
        """,
        default: 1
      ],
      description: [
        type: :string,
        doc: """
        A generic description of the specified service or resource.
        """
      ],
      category: [
        type: :string,
        doc: """
        The category the specified service or resource belongs to.
        """
      ]
    ]
  }

  @characteristic %Spark.Dsl.Entity{
    name: :characteristic,
    describe: "Adds a Characteristic",
    target: Diffo.Provider.Instance.Characteristic,
    args: [:name, :value_type],
    schema: [
      name: [
        doc: """
          The name of the characteristic, an atom
        """,
        type: :atom,
        required: true
      ],
      value_type: [
        doc: """
          The type of the characteristic's value. An atom module name such as an Ash.TypedStruct for a scalar value,
          or `{:array, module}` for an array of values of that type.
        """,
        type: :any
      ]
    ]
  }

  @characteristics %Spark.Dsl.Section{
    name: :characteristics,
    describe: "List of Instance Characteristics",
    examples: [
      """
      characteristics do
        characteristic :dslam, Diffo.Access.Dslam
        characteristic :aggregate_interface, Diffo.Access.AggregateInterface
        characteristic :circuit, Diffo.Access.Circuit
        characteristic :line, Diffo.Access.Line
      end
      """
    ],
    entities: [
      @characteristic
    ]
  }

  @feature %Spark.Dsl.Entity{
    name: :feature,
    describe: "Adds a Feature",
    target: Diffo.Provider.Instance.Feature,
    args: [:name],
    schema: [
      name: [
        doc: """
          The name of the feature, an atom
        """,
        type: :atom,
        required: true
      ],
      is_enabled?: [
        doc: """
          Whether the feature is enabled by default, defaults true
        """,
        type: :boolean
      ]
    ],
    entities: [
      characteristics: [@characteristic]
    ]
  }

  @features %Spark.Dsl.Section{
    name: :features,
    describe: "Configuration for Instance Features",
    examples: [
      """
      features do
        feature :dynamic_line_management do
          is_enabled? true
          characteristics do
            characteristic :constraints, Diffo.Access.Constraints
          end
        end
      end
      """
    ],
    entities: [
      @feature
    ]
  }

  @party_schema [
    role: [
      doc: "The role name, an atom",
      type: :atom,
      required: true
    ],
    party_type: [
      doc: "The module of the Party kind. An atom module name such as a BaseParty-derived resource.",
      type: :any
    ],
    reference: [
      doc: "If true, no direct PartyRef edge is created; the party is reachable by graph traversal.",
      type: :boolean,
      default: false
    ],
    calculate: [
      doc: "Name of an Ash calculation on this resource that produces the party at build time.",
      type: :atom
    ]
  ]

  @party_entity %Spark.Dsl.Entity{
    name: :party,
    describe: "Declares a singular party role on this Instance",
    target: Diffo.Provider.Instance.Extension.PartyDeclaration,
    args: [:role, :party_type],
    auto_set_fields: [multiple: false],
    schema: @party_schema
  }

  @parties_entity %Spark.Dsl.Entity{
    name: :parties,
    describe: "Declares a plural party role on this Instance",
    target: Diffo.Provider.Instance.Extension.PartyDeclaration,
    args: [:role, :party_type],
    auto_set_fields: [multiple: true],
    schema:
      @party_schema ++
        [
          constraints: [
            doc: "Multiplicity constraints on the number of parties in this role, e.g. [min: 1, max: 3]",
            type: :keyword_list
          ]
        ]
  }

  @parties %Spark.Dsl.Section{
    name: :parties,
    describe: "List of Instance Party roles",
    examples: [
      """
      parties do
        party :provider, MyApp.Provider, calculate: :provider_calculation
        parties :technician, MyApp.Technician, constraints: [min: 1, max: 3]
        party :owner, MyApp.InfrastructureCo, reference: true
      end
      """
    ],
    entities: [
      @party_entity,
      @parties_entity
    ]
  }

  use Spark.Dsl.Extension,
    sections: [@specification, @features, @characteristics, @parties],
    verifiers: [
      Diffo.Provider.Instance.Extension.Verifiers.VerifySpecification,
      Diffo.Provider.Instance.Extension.Verifiers.VerifyCharacteristics,
      Diffo.Provider.Instance.Extension.Verifiers.VerifyFeatures,
      Diffo.Provider.Instance.Extension.Verifiers.VerifyParties
    ]
end
