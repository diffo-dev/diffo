# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Specification do
  @moduledoc """
  Ash Resource for a TMF Service or Resource Specification.

  A Specification identifies the kind of a TMF Service or Resource Instance. Every instance
  carries a relationship to exactly one Specification node in the graph, established at build
  time and changeable via `Diffo.Provider.respecify_instance/2`.

  ## Identity

  A Specification is uniquely identified by `{name, major_version}`. The `id` is a stable
  UUID4 that is the same across all environments for a given `{name, major_version}` pair —
  it is typically declared as a constant in the Instance Extension DSL and committed to source
  control.

  ## Versioning

  Diffo uses semantic versioning for Specifications with three independent mechanisms:

  | Change | Mechanism                                 | Instance impact                                        | Intended usage                                                                    |
  | ------ | ----------------------------------------- | ------------------------------------------------------ | --------------------------------------------------------------------------------- |
  | Patch  | `next_patch_specification!/1`             | None — internal fix                                    | Corrections to metadata: description wording, category typos                     |
  | Minor  | `next_minor_specification!/1`             | None — all instances immediately reflect new version   | Backward-compatible additions: new optional characteristics, new enum values      |
  | Major  | New module, new `id`, new `major_version` | Instances stay on old spec until explicitly migrated   | Breaking changes                                                                  |

  What constitutes a breaking change is deliberately vague — it depends on the specification
  domain and may require negotiation between provider and consumers.

  ## Major version lifecycle

  Major versions are decoupled across the provider/consumer boundary:

  1. **Provider publishes V2** — deploys a new Instance kind module (e.g. `BroadbandV2`)
     with the same specification `name`, a new `id`, and `major_version: 2`. V1 and V2
     coexist; both can be used to create instances.
  2. **Consumers adopt at their own pace** — each consumer (e.g. an RSP) decides when to
     start creating V2 instances and when to migrate existing V1 instances.
  3. **Provider withdraws V1** — removes the V1 module. Existing V1 instances remain in
     the graph and continue to operate; the domain API for creating new V1 instances is
     removed.
  4. **Consumers complete migration** — each consumer migrates remaining V1 instances to V2
     via `Diffo.Provider.respecify_instance/2`, handling any breaking data changes (e.g.
     remapping or removing an enum value) before or as part of the respecification.

  ## create upsert behaviour

  `create_specification/1` uses `upsert? true` on the `{name, major_version}` identity.
  Calling it for an existing `{name, major_version}` pair preserves any attributes not
  supplied — a second call without `category` leaves the existing category intact.
  """
  require Ash.Resource.Change.Builtins

  use Ash.Resource,
    otp_app: :diffo,
    domain: Diffo.Provider,
    data_layer: AshNeo4j.DataLayer,
    extensions: [AshOutstanding.Resource, AshJason.Resource]

  resource do
    description "An Ash Resource for a TMF Service or Resource Specification"
    plural_name :specifications
  end

  neo4j do
    guard [
      {:SPECIFIED_BY, :incoming, :Instance}
    ]
  end

  jason do
    pick [:id, :href, :name, :version]
  end

  outstanding do
    expect [:name, :major_version]
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      description "creates a major version of a named serviceSpecification or resourceSpecification"

      accept [
        :id,
        :type,
        :name,
        :major_version,
        :minor_version,
        :patch_version,
        :tmf_version,
        :description,
        :category
      ]

      change load [:version, :href, :instance_type]
      upsert? true
      upsert_identity :unique_major_version_per_name
    end

    read :list do
      description "lists all serviceSpecification and resourceSpecification"
    end

    read :find_by_name do
      description "finds specifications by name"
      get? false

      argument :query, :ci_string do
        description "Return only specifications with names including the given value."
      end

      filter expr(contains(name, ^arg(:query)))
    end

    read :find_by_category do
      description "finds specifications by category"
      get? false

      argument :query, :ci_string do
        description "Return only specifications with category including the given value."
      end

      prepare build(sort: [name: :asc])
      filter expr(contains(category, ^arg(:query)))
    end

    read :get_latest do
      description "gets the serviceSpecification or resourceSpecification by name with highest major version"
      get? true

      argument :query, :ci_string do
        description "Return only specifications with names including the given value."
      end

      prepare build(limit: 1, sort: [major_version: :desc])
      filter expr(contains(name, ^arg(:query)))
    end

    update :describe do
      description "updates the description"
      accept [:description]
    end

    update :categorise do
      description "updates the category"
      accept [:category]
    end

    update :next_minor do
      description "increments the minor version and resets the patch version"
      change increment(:minor_version)
      change set_attribute(:patch_version, 0)
      change load [:version, :href, :instance_type]
    end

    update :next_patch do
      transaction? false
      description "increments the patch version"
      change increment(:patch_version)
      change load [:version, :href, :instance_type]
    end
  end

  attributes do
    attribute :id, :uuid do
      description "a uuid4, unique to a major version of this specification and common across all environments, generated by default"
      primary_key? true
      allow_nil? false
      public? true
      default &Diffo.Uuid.uuid4/0
    end

    attribute :type, :atom do
      description "indicates whether a serviceSpecification or resourceSpecification, defaults serviceSpecification"
      allow_nil? false
      public? false
      default :serviceSpecification
      constraints one_of: [:serviceSpecification, :resourceSpecification]
    end

    attribute :name, :string do
      description "the generic name of the service or resource specified by any version of this specification, e.g. adslAccess"
      allow_nil? false
      public? true
      constraints match: ~r/^[a-z][a-zA-Z0-9]*$/
    end

    attribute :major_version, :integer do
      description "the major version, defaults 1"
      allow_nil? false
      public? false
      default 1
      constraints min: 0
    end

    attribute :minor_version, :integer do
      description "the minor version, defaults 0"
      allow_nil? false
      public? false
      default 0
      constraints min: 0
    end

    attribute :patch_version, :integer do
      description "the patch version, defaults 0"
      allow_nil? false
      public? false
      default 0
      constraints min: 0
    end

    attribute :description, :string do
      description "a description of the service or resource specified by a major version of this specification"
      allow_nil? true
      public? true
    end

    attribute :category, :string do
      description "the category of the service or resource specified by a major version of this specification"
      allow_nil? true
      public? true
    end

    attribute :tmf_version, :integer do
      description "the TMF version of the specified service or resource, e.g. v4"
      allow_nil? false
      public? false
      default 4
      constraints min: 1
    end

    create_timestamp :created_at

    update_timestamp :updated_at
  end

  identities do
    identity :unique_major_version_per_name, [:name, :major_version]
  end

  validations do
    validate {Diffo.Validations.IsUuid4OrNil, attribute: :id}, on: :create
  end

  calculations do
    calculate :version, :string, Diffo.Provider.Calculations.SpecificationVersion
    calculate :href, :string, Diffo.Provider.Calculations.SpecificationHref
    calculate :instance_type, :atom, Diffo.Provider.Calculations.SpecificationInstanceType
  end

  preparations do
    prepare build(
              load: [:version, :href, :instance_type],
              sort: [name: :asc, major_version: :desc]
            )
  end

  @doc """
  Derives the catalog prefix from the type
  ## Examples
    iex> Diffo.Provider.Specification.catalog(:serviceSpecification)
    :serviceCatalogManagement

    iex> Diffo.Provider.Specification.catalog(:resourceSpecification)
    :resourceCatalogManagement

  """
  def catalog(type) do
    case type do
      :serviceSpecification -> :serviceCatalogManagement
      :resourceSpecification -> :resourceCatalogManagement
    end
  end
end
