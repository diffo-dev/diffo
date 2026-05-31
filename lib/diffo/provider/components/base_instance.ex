# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.BaseInstance do
  @moduledoc """
  Ash Resource Fragment which is the shared base for your TMF Service or Resource Instance.

  `BaseInstance` carries everything common to both kinds — identity, the graph
  relationships (specification, characteristics, features, parties, places,
  entities, notes, events, relationships), build wiring, the shared actions, and
  the `Diffo.Provider.Instance.Extension` DSL. It is **not** composed alone:
  pair it with a subtype fragment on a concrete leaf —

      use Ash.Resource, fragments: [Diffo.Provider.BaseInstance, Diffo.Provider.Service]   # a Service
      use Ash.Resource, fragments: [Diffo.Provider.BaseInstance, Diffo.Provider.Resource]  # a Resource

  `Diffo.Provider.Service` (TMF638) adds the service lifecycle state machine
  (`state` / `operating_status`) and lifecycle actions; `Diffo.Provider.Resource`
  (TMF639) adds `lifecycle_state`. An instance is exactly one of Service or
  Resource. `Diffo.Provider.Instance` is the generic Service + projection reader.

  ## Instance Extension DSL

  All declarations live inside a single `provider do` section. It describes what the
  instance kind is (`specification`, `characteristics`, `features`, `parties`, `places`)
  and wires it to Ash actions (`behaviour`). The blocks below are each shown on their own
  for clarity, but all sit inside one `provider do`.

  `specification do` — declares the TMF Specification for this Instance kind (id, name, type,
  major_version, description, category).

  `characteristics do` — declares the top-level Characteristics of this Instance kind, each
  backed by an `Ash.TypedStruct`.

  `features do` — declares the Features this Instance kind may have, each optionally carrying
  its own typed characteristic payload.

  `parties do` — declares the Party roles this Instance kind relates to. Role names are
  domain-specific nouns describing what the party means to the instance. Two forms:

      parties do
        party :provider, MyApp.Provider, calculate: :provider_calculation
        parties :installer, MyApp.Installer
        parties :technician, MyApp.Technician, constraints: [min: 1, max: 3]
        party_ref :owner, MyApp.InfrastructureCo
      end

  - `party` — singular (at most one party in this role per instance)
  - `parties` — plural (unbounded, or bounded with `constraints: [min: n, max: m]`)
  - `party_ref` — a reference: no direct `PartyRef` edge; party is reachable by graph traversal
  - `calculate:` — names an Ash calculation on this resource that produces the party at build time

  `places do` — declares the Place roles this Instance kind relates to. Mirrors `parties do`:

      places do
        place :installation_site, MyApp.GeographicSite
        places :coverage_areas, MyApp.GeographicLocation, constraints: [min: 1]
        place_ref :billing_address, MyApp.GeographicAddress
      end

  All declarations are introspectable at runtime via `Diffo.Provider.Instance.Info` and at
  compile time via `Diffo.Provider.Instance.Extension.Info`.

  `behaviour do actions do create :name end end` — marks a named create action for build
  wiring. This injects `:specified_by`, `:features`, and `:characteristics` arguments onto
  that action so Ash accepts the values that `build_before/1` sets automatically.

  You still write the action body yourself for domain-specific accepts, arguments, and changes.
  The build arguments are not public and do not need to appear in `accept`.

  ## Generated functions

  Every resource using `BaseInstance` with a `specification do` gets the following functions
  generated at compile time:

  - `specification/0` — the specification keyword list baked at compile time
  - `characteristics/0` — list of `Characteristic` structs
  - `features/0` — list of `Feature` structs
  - `parties/0` — list of `PartyDeclaration` structs
  - `places/0` — list of `PlaceDeclaration` structs
  - `characteristic/1` — returns the named `Characteristic` or `nil`
  - `feature/1` — returns the named `Feature` or `nil`
  - `feature_characteristic/2` — returns the named characteristic within a feature, or `nil`
  - `party/1` — returns the `PartyDeclaration` for the given role, or `nil`
  - `place/1` — returns the `PlaceDeclaration` for the given role, or `nil`
  - `build_before/1` — called automatically before every create action; upserts the
    specification and creates features, characteristics, and parties, setting their ids
    as action arguments
  - `build_after/2` — called automatically after every create action; relates the created
    TMF entities to the new instance node

  Resources without a `specification do id` get trivial passthroughs for `build_before/1`
  and `build_after/2`.

  ## Usage

      defmodule MyApp.Cluster do
        # a Cluster is a Resource, so it composes the Resource fragment
        use Ash.Resource, fragments: [BaseInstance, Diffo.Provider.Resource], domain: MyApp.Domain

        resource do
          description "A Cluster Resource Instance"
          plural_name :clusters
        end

        provider do
          specification do
            id "4bcfc4c9-e776-4878-a658-e8d81857bed7"
            name "cluster"
            type :resourceSpecification
          end

          parties do
            party :operator, MyApp.Organization
            parties :installer, MyApp.Engineer
          end

          places do
            place :site, MyApp.GeographicSite
          end

          behaviour do
            actions do
              create :build
            end
          end
        end

        actions do
          create :build do
            description "creates a new Cluster resource instance"
            accept [:id, :name, :type, :which]
            argument :relationships, {:array, :struct}
            argument :parties, {:array, :struct}

            change set_attribute(:type, :resource)
            change load [:href]
            upsert? false
          end
        end
      end

  ## Rolling your own actions

  The `behaviour do actions do create :name end end` declaration is optional. Omitting it
  means the `:specified_by`, `:features`, and `:characteristics` arguments are not declared
  on that action — but `build_before/1` and `build_after/2` are still called for every
  create via the global `BuildBefore` and `BuildAfter` changes registered on `BaseInstance`.

  If you have a create action that should NOT trigger the full build wiring (e.g. a
  lightweight admin create), you can override `build_before/1` or `build_after/2` on your
  resource, or use Ash's `skip_unknown_inputs` to absorb the injected arguments without
  declaring them.

  ## Instance versioning

  Each Instance kind is tied to a specific major version of its Specification via the `id`
  declared in `specification do`. Patch and minor version bumps update the existing
  Specification node in place and require no instance changes. Major version bumps introduce
  a new Instance kind module (e.g. `BroadbandV2`) with a new `id` and `major_version`,
  leaving the original module and all its instances untouched.

  To migrate an existing instance from one major version to another, call
  `Diffo.Provider.respecify_instance/2` with the new specification's id:

      {:ok, v2_spec} = Diffo.Provider.get_specification_by_id(BroadbandV2.specification()[:id])
      {:ok, migrated} = Diffo.Provider.respecify_instance(instance, %{specified_by: v2_spec.id})

  Any breaking data changes (e.g. a characteristic value that no longer exists in V2) must
  be handled before or as part of respecification — either via Cypher directly against the
  graph or via a domain-specific migration action you build on your own resource.

  See `Diffo.Provider.Specification` for the full versioning lifecycle.
  """
  use Spark.Dsl.Fragment,
    of: Ash.Resource,
    otp_app: :diffo,
    domain: Diffo.Provider,
    data_layer: AshNeo4j.DataLayer,
    extensions: [
      AshOutstanding.Resource,
      AshJason.Resource,
      Diffo.Provider.Extension,
      Diffo.Provider.Instance.Extension
    ]

  neo4j do
    relate [
      {:external_identifiers, :REFERENCES, :outgoing, :ExternalIdentifier},
      {:specification, :SPECIFIED_BY, :outgoing, :Specification},
      {:process_statuses, :STATUSES, :incoming, :ProcessStatus},
      {:forward_relationships, :RELATES, :outgoing, :Relationship},
      {:reverse_relationships, :RELATES, :incoming, :Relationship},
      {:assignments, :RELATES, :outgoing, :AssignmentRelationship},
      {:features, :HAS, :outgoing, :Feature},
      {:characteristics, :HAS, :outgoing, :Characteristic},
      {:entities, :RELATES, :outgoing, :EntityRef},
      {:notes, :ANNOTATES, :incoming, :Note},
      {:event, :FIRED, :outgoing, :Event},
      {:places, :RELATES, :outgoing, :PlaceRef},
      {:parties, :RELATES, :outgoing, :PartyRef}
    ]

    label :Instance
  end

  attributes do
    attribute :id, :uuid do
      description "a uuid4, unique to this instance, generated by default"
      primary_key? true
      allow_nil? false
      public? true
      default &Diffo.Uuid.uuid4/0
      source :uuid
    end

    attribute :which, :atom do
      description "the which of the instance, either expected or actual"
      allow_nil? false
      default :actual
      public? true
      constraints one_of: [:expected, :actual]
    end

    attribute :type, :atom do
      description "the type of the instance, either service or resource"
      allow_nil? false
      default :service
      public? true
      constraints one_of: [:service, :resource]
    end

    attribute :name, :string do
      description "the name of this service or resource instance"
      allow_nil? true
      public? true
      constraints match: ~r/^[a-zA-Z0-9\s._-]+$/
    end

    create_timestamp :created_at

    update_timestamp :updated_at

    attribute :started_at, :utc_datetime_usec do
      allow_nil? true
    end

    attribute :stopped_at, :utc_datetime_usec do
      allow_nil? true
    end
  end

  relationships do
    has_many :external_identifiers, Diffo.Provider.ExternalIdentifier do
      description "the instance's list of external identifiers"
      public? true
      destination_attribute :instance_id
    end

    belongs_to :specification, Diffo.Provider.Specification do
      description "the specification which specifies this instance"
      public? true
    end

    has_many :process_statuses, Diffo.Provider.ProcessStatus do
      description "the instance's process status collection"
      public? true
      destination_attribute :instance_id
    end

    has_many :forward_relationships, Diffo.Provider.Relationship do
      description "the instance's outgoing relationships to other instances"
      destination_attribute :source_id
      public? true
    end

    has_many :reverse_relationships, Diffo.Provider.Relationship do
      description "the instance's incoming relationships from other instances"
      destination_attribute :target_id
      public? true
    end

    has_many :assignments, Diffo.Provider.AssignmentRelationship do
      description "the instance's outgoing pool assignment relationships"
      destination_attribute :source_id
      public? true
    end

    has_many :features, Diffo.Provider.Feature do
      description "the instance's collection of defining features"
      public? true
      destination_attribute :instance_id
    end

    has_many :characteristics, Diffo.Provider.Characteristic do
      description "the instance's collection of defining characteristics"
      public? true
      destination_attribute :instance_id
    end

    has_many :entities, Diffo.Provider.EntityRef do
      description "the instance's collection of related entities"
      public? true
      destination_attribute :instance_id
    end

    has_many :notes, Diffo.Provider.Note do
      description "the instance's collection of annotating notes"
      public? true
      destination_attribute :instance_id
    end

    has_one :event, Diffo.Provider.Event do
      description "the most recently fired event"
      public? true
      destination_attribute :instance_id
    end

    has_many :places, Diffo.Provider.PlaceRef do
      description "the instance's collection of related places"
      public? true
      destination_attribute :instance_id
    end

    has_many :parties, Diffo.Provider.PartyRef do
      description "the instance's collection of related parties"
      public? true
      destination_attribute :instance_id
    end
  end

  changes do
    change Diffo.Provider.Instance.Extension.Changes.BuildBefore, on: [:create]
    change Diffo.Provider.Instance.Extension.Changes.BuildAfter, on: [:create]
  end

  validations do
    validate Diffo.Provider.Validations.ValidateRelationshipPermitted, on: [:update]
  end

  actions do
    defaults [:destroy]

    create :create do
      description "creates a new instance of a service or resource according by specification id"
      accept [:id, :name, :type, :which]
      argument :specified_by, :uuid
      argument :features, {:array, :uuid}
      argument :characteristics, {:array, :uuid}

      change manage_relationship(:specified_by, :specification, type: :append)
      change manage_relationship(:features, type: :append)
      change manage_relationship(:characteristics, type: :append)
      change load [:href]
      upsert? true
    end

    read :read do
      description "read a service or resource instance"
      primary? true
    end

    read :list do
      description "lists all service and resource instances"
    end

    read :find_by_name do
      description "finds service and resource instances by name"
      get? false

      argument :query, :ci_string do
        description "Return only instances with names including the given value."
      end

      filter expr(contains(name, ^arg(:query)))
    end

    read :find_by_specification_id do
      description "list service or resource instances by specification id"
      get? false

      argument :query, :string do
        description "Return only instances specified by the given specification id."
      end

      # prepare build(sort: [name: :asc])
      filter expr(specification_id == ^arg(:query))
    end

    update :name do
      description "updates the name"
      require_atomic? false
      accept [:name]
    end

    update :specify do
      description "specifies the instance by specification id"
      require_atomic? false
      argument :specified_by, :uuid
      change manage_relationship(:specified_by, :specification, type: :append_and_remove)
      # todo validate that the new specification has same name (will have different major version)
    end

    update :relate_features do
      description "relates features to the instance"
      argument :features, {:array, :uuid}
      change manage_relationship(:features, type: :append)
    end

    update :unrelate_features do
      description "unrelates features from the instance"
      argument :features, {:array, :uuid}
      change manage_relationship(:features, type: :remove)
    end

    update :relate_characteristics do
      description "relates characteristics to the instance"
      argument :characteristics, {:array, :uuid}
      change manage_relationship(:characteristics, type: :append)
    end

    update :unrelate_characteristics do
      description "unrelates characteristics from the instance"
      argument :characteristics, {:array, :uuid}
      change manage_relationship(:characteristics, type: :remove)
    end

    update :annotate do
      description "annotates the instance with a note"
      argument :note, :uuid
      change manage_relationship(:note, :notes, type: :append)
    end

    update :fire_event do
      description "fires an event, maintaining the event chain"

      argument :event, :map do
        allow_nil? false
      end

      change Diffo.Changes.DetailEvent
      change manage_relationship(:event, type: :create)
      change load [:event]
    end
  end

  code_interface do
    define :read
  end

  identities do
    identity :unique_name_per_type, [:name] do
      message "instance name must be unique"
      pre_check? true
    end
  end

  preparations do
    prepare build(
              load: [
                :href,
                :external_identifiers,
                :specification,
                :process_statuses,
                :forward_relationships,
                :assignments,
                :entities,
                :notes,
                :features,
                :characteristics,
                :typed_characteristics,
                :pool_characteristics,
                :places,
                :parties
              ],
              sort: [created_at: :desc]
            )
  end

  calculations do
    calculate :href, :string, Diffo.Provider.Calculations.InstanceHref do
      description "the inventory href of the service or resource instance"
    end

    calculate :typed_characteristics,
              {:array, :struct},
              Diffo.Provider.Calculations.TypedCharacteristics do
      description "typed BaseCharacteristic records declared via the characteristics DSL"
    end

    calculate :pool_characteristics,
              {:array, :struct},
              Diffo.Provider.Calculations.PoolCharacteristics do
      description "AssignableCharacteristic records declared via the pools DSL"
    end
  end
end
