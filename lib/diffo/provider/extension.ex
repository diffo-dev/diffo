# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Extension do
  @moduledoc """
  Unified DSL extension for all Diffo provider resource kinds.

  Provides a single `provider do` section for Instance, Party, and Place kinds.
  The sections within `provider do` are self-similar across kinds — each kind uses
  the sections relevant to it, and verifiers enforce correct usage.

  ## Instance

      provider do
        specification do
          id "da9b207a-26c3-451d-8abd-0640c6349979"
          name "DSL Access Service"
          type :serviceSpecification
        end

        characteristics do
          characteristic :circuit, Diffo.Access.Circuit
        end

        features do
          feature :dynamic_line_management do
            characteristics do
              characteristic :constraints, Diffo.Access.Constraints
            end
          end
        end

        pools do
          pool :ports, :port
        end

        parties do
          party :provider, MyApp.Provider
          party_ref :owner, MyApp.InfrastructureCo
          parties :technicians, MyApp.Technician, constraints: [min: 1]
        end

        places do
          place :installation_site, MyApp.GeographicSite
          place_ref :billing_address, MyApp.GeographicAddress
        end

        behaviour do
          actions do
            create :build
          end
        end
      end

  ## Party

      provider do
        instances do
          role :facilitates, MyApp.AccessService
          instance_ref :manages, MyApp.InternalService
        end
        parties do
          role :employer, MyApp.Person
        end
        places do
          role :headquarters, MyApp.GeographicSite
        end
      end

  ## Place

      provider do
        instances do
          role :site_for, MyApp.AccessService
        end
        parties do
          role :managed_by, MyApp.Organization
        end
        places do
          role :within, MyApp.GeographicSite
        end
      end

  See `Diffo.Provider.Extension.Info` for runtime introspection.
  See `Diffo.Provider.BaseInstance`, `Diffo.Provider.BaseParty`, `Diffo.Provider.BasePlace`
  for full usage documentation.
  """

  alias Diffo.Provider.Extension.{
    ActionCreate,
    ActionUpdate,
    Characteristic,
    Feature,
    InstanceRole,
    PartyDeclaration,
    PartyRole,
    PlaceDeclaration,
    PlaceRole,
    Pool
  }

  # ── specification ──────────────────────────────────────────────────────────

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
        description "An access network service"
        category "Network Service"
      end
      """
    ],
    schema: [
      id: [
        type: :string,
        doc:
          "The id of the specification, a uuid4 the same in all environments, unique for name and major_version.",
        required: true
      ],
      name: [
        type: :string,
        doc: "The name of the specification.",
        required: true
      ],
      type: [
        type: :atom,
        doc: "The type of the specification.",
        default: :serviceSpecification
      ],
      major_version: [
        type: :integer,
        doc: "The major version of the specification.",
        default: 1
      ],
      minor_version: [
        type: :integer,
        doc: "The minor version of the specification."
      ],
      patch_version: [
        type: :integer,
        doc: "The patch version of the specification."
      ],
      tmf_version: [
        type: :integer,
        doc: "The TMF API version of the specification, e.g. 4."
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

  # ── characteristics ────────────────────────────────────────────────────────

  @characteristic_entity %Spark.Dsl.Entity{
    name: :characteristic,
    describe: "Adds a Characteristic",
    target: Characteristic,
    args: [:name, :value_type],
    schema: [
      name: [
        type: :atom,
        doc: "The name of the characteristic.",
        required: true
      ],
      value_type: [
        type: :any,
        doc:
          "The type of the characteristic value — a module or `{:array, module}` for an array."
      ]
    ]
  }

  @characteristics %Spark.Dsl.Section{
    name: :characteristics,
    describe: "List of Instance Characteristics",
    examples: [
      """
      characteristics do
        characteristic :circuit, Diffo.Access.Circuit
        characteristic :line, Diffo.Access.Line
      end
      """
    ],
    entities: [@characteristic_entity]
  }

  # ── features ───────────────────────────────────────────────────────────────

  @feature_entity %Spark.Dsl.Entity{
    name: :feature,
    describe: "Adds a Feature",
    target: Feature,
    args: [:name],
    schema: [
      name: [
        type: :atom,
        doc: "The name of the feature.",
        required: true
      ],
      is_enabled?: [
        type: :boolean,
        doc: "Whether the feature is enabled by default, defaults true."
      ]
    ],
    entities: [
      characteristics: [@characteristic_entity]
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
    entities: [@feature_entity]
  }

  # ── parties ────────────────────────────────────────────────────────────────

  @party_schema [
    role: [type: :atom, doc: "The role name.", required: true],
    party_type: [type: :any, doc: "The module of the Party kind."],
    calculate: [type: :atom, doc: "Ash calculation on this resource that produces the party."]
  ]

  @party_entity %Spark.Dsl.Entity{
    name: :party,
    describe: "Declares a singular party role on this Instance",
    target: PartyDeclaration,
    args: [:role, :party_type],
    auto_set_fields: [multiple: false, reference: false],
    schema: @party_schema
  }

  @parties_entity %Spark.Dsl.Entity{
    name: :parties,
    describe: "Declares a plural party role on this Instance",
    target: PartyDeclaration,
    args: [:role, :party_type],
    auto_set_fields: [multiple: true, reference: false],
    schema:
      @party_schema ++
        [
          constraints: [
            type: :keyword_list,
            doc: "Multiplicity constraints, e.g. [min: 1, max: 3]."
          ]
        ]
  }

  @party_ref_entity %Spark.Dsl.Entity{
    name: :party_ref,
    describe:
      "Declares a singular reference party role — no direct PartyRef edge, reachable by graph traversal",
    target: PartyDeclaration,
    args: [:role, :party_type],
    auto_set_fields: [multiple: false, reference: true],
    schema: @party_schema
  }

  @party_role_entity %Spark.Dsl.Entity{
    name: :role,
    describe: "Declares a role this Party or Place kind plays with respect to other Parties",
    target: PartyRole,
    args: [:role, :party_type],
    schema: [
      role: [type: :atom, doc: "The role name.", required: true],
      party_type: [type: :any, doc: "The module of the related Party kind."]
    ]
  }

  @parties %Spark.Dsl.Section{
    name: :parties,
    describe:
      "Party roles on this resource — `party`/`parties`/`party_ref` for Instance kinds; `role` for Party and Place kinds",
    examples: [
      """
      # Instance
      parties do
        party :provider, MyApp.Provider
        party_ref :owner, MyApp.InfrastructureCo
        parties :technicians, MyApp.Technician, constraints: [min: 1]
      end

      # Party or Place
      parties do
        role :employer, MyApp.Person
      end
      """
    ],
    entities: [@party_entity, @parties_entity, @party_ref_entity, @party_role_entity]
  }

  # ── places ─────────────────────────────────────────────────────────────────

  @place_schema [
    role: [type: :atom, doc: "The role name.", required: true],
    place_type: [type: :any, doc: "The module of the Place kind."],
    calculate: [type: :atom, doc: "Ash calculation on this resource that produces the place."]
  ]

  @place_entity %Spark.Dsl.Entity{
    name: :place,
    describe: "Declares a singular place role on this Instance",
    target: PlaceDeclaration,
    args: [:role, :place_type],
    auto_set_fields: [multiple: false, reference: false],
    schema: @place_schema
  }

  @places_entity %Spark.Dsl.Entity{
    name: :places,
    describe: "Declares a plural place role on this Instance",
    target: PlaceDeclaration,
    args: [:role, :place_type],
    auto_set_fields: [multiple: true, reference: false],
    schema:
      @place_schema ++
        [
          constraints: [
            type: :keyword_list,
            doc: "Multiplicity constraints, e.g. [min: 1, max: 3]."
          ]
        ]
  }

  @place_ref_entity %Spark.Dsl.Entity{
    name: :place_ref,
    describe:
      "Declares a singular reference place role — no direct PlaceRef edge, reachable by graph traversal",
    target: PlaceDeclaration,
    args: [:role, :place_type],
    auto_set_fields: [multiple: false, reference: true],
    schema: @place_schema
  }

  @place_role_entity %Spark.Dsl.Entity{
    name: :role,
    describe: "Declares a role this Party or Place kind plays with respect to Places",
    target: PlaceRole,
    args: [:role, :place_type],
    schema: [
      role: [type: :atom, doc: "The role name.", required: true],
      place_type: [type: :any, doc: "The module of the related Place kind."]
    ]
  }

  @places %Spark.Dsl.Section{
    name: :places,
    describe:
      "Place roles on this resource — `place`/`places`/`place_ref` for Instance kinds; `role` for Party and Place kinds",
    examples: [
      """
      # Instance
      places do
        place :installation_site, MyApp.GeographicSite
        place_ref :billing_address, MyApp.GeographicAddress
      end

      # Party or Place
      places do
        role :headquarters, MyApp.GeographicSite
      end
      """
    ],
    entities: [@place_entity, @places_entity, @place_ref_entity, @place_role_entity]
  }

  # ── instances ──────────────────────────────────────────────────────────────

  @instance_role_entity %Spark.Dsl.Entity{
    name: :role,
    describe: "Declares a role this Party or Place kind plays with respect to Instances",
    target: InstanceRole,
    args: [:role, :instance_type],
    auto_set_fields: [reference: false],
    schema: [
      role: [type: :atom, doc: "The role name.", required: true],
      instance_type: [type: :any, doc: "The module of the related Instance kind."]
    ]
  }

  @instance_ref_entity %Spark.Dsl.Entity{
    name: :instance_ref,
    describe:
      "Declares a reference instance role — no direct edge created, reachable by graph traversal",
    target: InstanceRole,
    args: [:role, :instance_type],
    auto_set_fields: [reference: true],
    schema: [
      role: [type: :atom, doc: "The role name.", required: true],
      instance_type: [type: :any, doc: "The module of the related Instance kind."]
    ]
  }

  @instances %Spark.Dsl.Section{
    name: :instances,
    describe: "Declares the roles this Party or Place kind plays with respect to Instances",
    examples: [
      """
      instances do
        role :facilitates, MyApp.AccessService
        instance_ref :manages, MyApp.InternalService
      end
      """
    ],
    entities: [@instance_role_entity, @instance_ref_entity]
  }

  # ── pools ──────────────────────────────────────────────────────────────────

  @pool_entity %Spark.Dsl.Entity{
    name: :pool,
    describe: "Declares an assignable pool — a named range of values for auto-assignment",
    target: Pool,
    args: [:name, :thing],
    schema: [
      name: [
        type: :atom,
        doc: "The pool name (matches the AssignableCharacteristic name).",
        required: true
      ],
      thing: [
        type: :atom,
        doc: "The name of the thing being assigned within the pool (e.g. :port).",
        required: true
      ]
    ]
  }

  @pools %Spark.Dsl.Section{
    name: :pools,
    describe: "Assignable pools on this Instance — each pool maps to an AssignableCharacteristic",
    examples: [
      """
      pools do
        pool :ports, :port
      end
      """
    ],
    entities: [@pool_entity]
  }

  # ── behaviour ──────────────────────────────────────────────────────────────

  @action_create_entity %Spark.Dsl.Entity{
    name: :create,
    describe: "Marks a create action for instance build wiring",
    target: ActionCreate,
    args: [:name],
    schema: [
      name: [type: :atom, doc: "The name of the create action to wire.", required: true]
    ]
  }

  @action_update_entity %Spark.Dsl.Entity{
    name: :update,
    describe: "Marks an update action for instance behaviour wiring",
    target: ActionUpdate,
    args: [:name],
    schema: [
      name: [type: :atom, doc: "The name of the update action to wire.", required: true]
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
    entities: [@action_create_entity, @action_update_entity]
  }

  @behaviour_section %Spark.Dsl.Section{
    name: :behaviour,
    describe: "Defines the behavioural wiring for the Instance — actions, and in future triggers",
    examples: [
      """
      behaviour do
        actions do
          create :build
        end
      end
      """
    ],
    sections: [@behaviour_actions]
  }

  # ── provider (top-level wrapper) ───────────────────────────────────────────

  @provider %Spark.Dsl.Section{
    name: :provider,
    describe: "Provider DSL — structure, roles, and behaviour for this resource kind",
    sections: [
      @specification,
      @characteristics,
      @features,
      @pools,
      @parties,
      @places,
      @instances,
      @behaviour_section
    ]
  }

  use Spark.Dsl.Extension,
    sections: [@provider],
    persisters: [
      Diffo.Provider.Extension.Persisters.PersistSpecification,
      Diffo.Provider.Extension.Persisters.PersistCharacteristics,
      Diffo.Provider.Extension.Persisters.PersistFeatures,
      Diffo.Provider.Extension.Persisters.PersistPools,
      Diffo.Provider.Extension.Persisters.PersistParties,
      Diffo.Provider.Extension.Persisters.PersistPlaces,
      Diffo.Provider.Extension.Persisters.PersistInstances,
      Diffo.Provider.Extension.Transformers.TransformBehaviour
    ],
    verifiers: [
      Diffo.Provider.Extension.Verifiers.VerifySpecification,
      Diffo.Provider.Extension.Verifiers.VerifyCharacteristics,
      Diffo.Provider.Extension.Verifiers.VerifyFeatures,
      Diffo.Provider.Extension.Verifiers.VerifyPools,
      Diffo.Provider.Extension.Verifiers.VerifyParties,
      Diffo.Provider.Extension.Verifiers.VerifyPlaces,
      Diffo.Provider.Extension.Verifiers.VerifyInstances,
      Diffo.Provider.Extension.Verifiers.VerifyBehaviour
    ]
end
