# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Instance.Extension do
  @moduledoc """
  DSL Extension customising an Instance.

  Provides two top-level sections:

  ## structure

  Describes the static shape of the Instance kind — what it is, what values it carries,
  and what parties it relates to. All structure declarations are baked into the resource
  module at compile time via persisters and are introspectable at runtime via
  `Diffo.Provider.Instance.Info` or directly as generated functions on the resource module.

  - `specification do` — the TMF Specification (id, name, type, version, description, category).
    The id is a stable UUID4 that is the same across all environments for this Instance kind.
  - `characteristics do` — typed value slots carried by instances of this kind, each backed
    by an `Ash.TypedStruct`.
  - `features do` — optional capabilities of this kind, each with its own typed characteristic
    payload and an enabled/disabled default.
  - `parties do` — the party roles that instances of this kind relate to, with multiplicity,
    reference, and calculation options.
  - `places do` — the place roles that instances of this kind relate to, mirroring `parties do`
    in structure and options.

  ## behaviour

  Declares which Ash actions should be wired for instance build lifecycle management.
  Currently supports `create` declarations; future sections will cover triggers and other
  lifecycle concerns.

  Declaring `create :name` in `behaviour do actions do` causes the `TransformBehaviour`
  transformer to inject `:specified_by`, `:features`, and `:characteristics` arguments onto
  the named Ash create action. These arguments carry the UUIDs of the TMF entities created
  by `build_before/1` and consumed by the Ash relationship management in the action.

  See the [DSL cheat sheet](DSL-Diffo.Provider.Instance.Extension.html) for the full DSL reference.
  See `Diffo.Provider.BaseInstance` for full usage documentation including generated functions.
  """

  # ── structure ──────────────────────────────────────────────────────────────

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
        doc: "The id of the specification, a uuid4 the same in all environments, unique for name and major_version.",
        required: true
      ],
      name: [
        type: :string,
        doc: "The name of the specification, unique to a service but common for all versions.",
        required: true
      ],
      type: [
        type: :atom,
        doc: "The type of the specification.",
        default: :serviceSpecification
      ],
      major_version: [
        type: :integer,
        doc: "The major_version of the specification.",
        default: 1
      ],
      description: [
        type: :string,
        doc: "A generic description of the specified service or resource."
      ],
      category: [
        type: :string,
        doc: "The category the specified service or resource belongs to."
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
        doc: "The name of the characteristic, an atom",
        type: :atom,
        required: true
      ],
      value_type: [
        doc: "The type of the characteristic's value. An atom module name such as an Ash.TypedStruct for a scalar value, or `{:array, module}` for an array of values of that type.",
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
    entities: [@characteristic]
  }

  @feature %Spark.Dsl.Entity{
    name: :feature,
    describe: "Adds a Feature",
    target: Diffo.Provider.Instance.Feature,
    args: [:name],
    schema: [
      name: [
        doc: "The name of the feature, an atom",
        type: :atom,
        required: true
      ],
      is_enabled?: [
        doc: "Whether the feature is enabled by default, defaults true",
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
    entities: [@feature]
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
    entities: [@party_entity, @parties_entity]
  }

  @place_schema [
    role: [
      doc: "The role name, an atom",
      type: :atom,
      required: true
    ],
    place_type: [
      doc: "The module of the Place kind. A BasePlace-derived resource.",
      type: :any
    ],
    reference: [
      doc: "If true, no direct PlaceRef edge is created; the place is reachable by graph traversal.",
      type: :boolean,
      default: false
    ],
    calculate: [
      doc: "Name of an Ash calculation on this resource that produces the place at build time.",
      type: :atom
    ]
  ]

  @place_entity %Spark.Dsl.Entity{
    name: :place,
    describe: "Declares a singular place role on this Instance",
    target: Diffo.Provider.Instance.Extension.PlaceDeclaration,
    args: [:role, :place_type],
    auto_set_fields: [multiple: false],
    schema: @place_schema
  }

  @places_entity %Spark.Dsl.Entity{
    name: :places,
    describe: "Declares a plural place role on this Instance",
    target: Diffo.Provider.Instance.Extension.PlaceDeclaration,
    args: [:role, :place_type],
    auto_set_fields: [multiple: true],
    schema:
      @place_schema ++
        [
          constraints: [
            doc: "Multiplicity constraints on the number of places in this role, e.g. [min: 1, max: 3]",
            type: :keyword_list
          ]
        ]
  }

  @places %Spark.Dsl.Section{
    name: :places,
    describe: "List of Instance Place roles",
    examples: [
      """
      places do
        place :installation_site, MyApp.GeographicSite
        places :coverage_areas, MyApp.GeographicLocation, constraints: [min: 1]
        place :billing_address, MyApp.GeographicAddress, reference: true
      end
      """
    ],
    entities: [@place_entity, @places_entity]
  }

  @structure %Spark.Dsl.Section{
    name: :structure,
    describe: "Defines the structural shape of the Instance — its specification, characteristics, features, parties, and places",
    examples: [
      """
      structure do
        specification do
          id "da9b207a-26c3-451d-8abd-0640c6349979"
          name "DSL Access Service"
          type :serviceSpecification
        end

        characteristics do
          characteristic :circuit, Diffo.Access.Circuit
        end

        parties do
          party :provider, MyApp.Provider
        end

        places do
          place :installation_site, MyApp.GeographicSite
        end
      end
      """
    ],
    sections: [@specification, @characteristics, @features, @parties, @places]
  }

  # ── behaviour ──────────────────────────────────────────────────────────────

  @action_create %Spark.Dsl.Entity{
    name: :create,
    describe: "Marks a create action for instance build wiring, injecting :specified_by, :features, and :characteristics arguments",
    target: Diffo.Provider.Instance.Extension.ActionCreate,
    args: [:name],
    schema: [
      name: [
        type: :atom,
        required: true,
        doc: "The name of the create action to wire"
      ]
    ]
  }

  @action_update %Spark.Dsl.Entity{
    name: :update,
    describe: "Marks an update action for instance behaviour wiring",
    target: Diffo.Provider.Instance.Extension.ActionUpdate,
    args: [:name],
    schema: [
      name: [
        type: :atom,
        required: true,
        doc: "The name of the update action to wire"
      ]
    ]
  }

  @behaviour_actions %Spark.Dsl.Section{
    name: :actions,
    describe: "Declares which actions to wire for instance behaviour",
    examples: [
      """
      actions do
        create :build
        update :define
      end
      """
    ],
    entities: [@action_create, @action_update]
  }

  @behaviour_section %Spark.Dsl.Section{
    name: :behaviour,
    describe: "Defines the behavioural wiring for the Instance — actions, and in future triggers and tasks",
    examples: [
      """
      behaviour do
        actions do
          create :build
          update :define
        end
      end
      """
    ],
    sections: [@behaviour_actions]
  }

  use Spark.Dsl.Extension,
    sections: [@structure, @behaviour_section],
    persisters: [
      Diffo.Provider.Instance.Extension.Persisters.PersistSpecification,
      Diffo.Provider.Instance.Extension.Persisters.PersistCharacteristics,
      Diffo.Provider.Instance.Extension.Persisters.PersistFeatures,
      Diffo.Provider.Instance.Extension.Persisters.PersistParties,
      Diffo.Provider.Instance.Extension.Persisters.PersistPlaces,
      Diffo.Provider.Instance.Extension.Transformers.TransformBehaviour
    ],
    verifiers: [
      Diffo.Provider.Instance.Extension.Verifiers.VerifySpecification,
      Diffo.Provider.Instance.Extension.Verifiers.VerifyCharacteristics,
      Diffo.Provider.Instance.Extension.Verifiers.VerifyFeatures,
      Diffo.Provider.Instance.Extension.Verifiers.VerifyParties,
      Diffo.Provider.Instance.Extension.Verifiers.VerifyBehaviour
    ]
end
