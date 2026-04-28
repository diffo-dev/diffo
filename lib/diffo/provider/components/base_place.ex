# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.BasePlace do
  @moduledoc """
  Ash Resource Fragment which is the point of extension for your TMF Place.

  `BasePlace` is the foundation for domain-specific Place kinds.
  Include it as a fragment on an `Ash.Resource` to get common Place attributes, Neo4j graph
  wiring, and the `Diffo.Provider.Place.Extension` DSL.

  `Diffo.Provider.Place` uses `BasePlace` directly as the out-of-the-box TMF Place resource.
  Domain-specific resources extend it for richer domain identity.

  ## Attributes

  - `id` — string primary key (required, no default — set by domain).
  - `href` — optional URI for the place.
  - `name` — the place name.
  - `type` — TMF `@type`. Defaults to `:PlaceRef`. One of `:PlaceRef`, `:GeographicSite`,
    `:GeographicLocation`, `:GeographicAddress`. When `referred_type` is present, `type` must
    be `:PlaceRef`.
  - `referred_type` — TMF `@referredType`. One of `:GeographicSite`, `:GeographicLocation`,
    `:GeographicAddress`. When present, indicates this is a reference to a place of that kind;
    `type` must be `:PlaceRef`.

  ## Usage

      defmodule MyApp.GeographicSite do
        use Ash.Resource, fragments: [BasePlace], domain: MyApp.Domain

        resource do
          description "A Geographic Site"
          plural_name :geographic_sites
        end

        jason do
          pick [:id, :href, :name, :referred_type, :type]
          compact true
          rename referred_type: "@referredType", type: "@type"
        end

        outstanding do
          expect [:id, :name, :referred_type, :type]
        end

        actions do
          create :build do
            accept [:id, :href, :name]
            change set_attribute(:type, :GeographicSite)
          end
        end
      end

  ## TMF type and referred_type

  The `type` and `referred_type` attributes map to the TMF `@type` and `@referredType` JSON
  fields via the jason layer. When `referred_type` is present, `type` must be `:PlaceRef`;
  otherwise `type` must not be `:PlaceRef`.
  """
  use Spark.Dsl.Fragment,
    of: Ash.Resource,
    otp_app: :diffo,
    domain: Diffo.Provider,
    data_layer: AshNeo4j.DataLayer,
    extensions: [
      AshOutstanding.Resource,
      AshJason.Resource,
      Diffo.Provider.Place.Extension
    ]

  neo4j do
    relate [
      {:place_refs, :RELATES, :incoming, :PlaceRef}
    ]
  end

  attributes do
    attribute :id, :string do
      description "the unique id of the place"
      primary_key? true
      allow_nil? false
      public? true
      source :key
    end

    attribute :href, :string do
      description "the href of the place"
      allow_nil? true
      public? true
    end

    attribute :name, :string do
      description "the name of the place"
      allow_nil? true
      public? true
      constraints match: ~r/^[a-zA-Z0-9\s._-]+$/
    end

    attribute :type, :atom do
      description "the type of the place"
      allow_nil? false
      public? true
      default :PlaceRef
      constraints one_of: [:PlaceRef, :GeographicSite, :GeographicLocation, :GeographicAddress]
    end

    attribute :referred_type, :atom do
      description "the referred type of the place"
      allow_nil? true
      public? true
      constraints one_of: [:GeographicSite, :GeographicLocation, :GeographicAddress]
    end

    create_timestamp :created_at

    update_timestamp :updated_at
  end

  relationships do
    has_many :place_refs, Diffo.Provider.PlaceRef do
      description "the place refs relating this place to instances"
      destination_attribute :place_id
      public? true
    end
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      description "creates a place"
      accept [:id, :href, :name, :type, :referred_type]
      upsert? true
    end

    update :update do
      description "updates the place"
      accept [:href, :name, :type, :referred_type]
    end

    read :list do
      description "lists all places"
    end

    read :find_by_id do
      description "finds place by id"
      get? false

      argument :query, :ci_string do
        description "Return only places with id's including the given value."
      end

      filter expr(contains(id, ^arg(:query)))
    end

    read :find_by_name do
      description "finds place by name"
      get? false

      argument :query, :ci_string do
        description "Return only places with names including the given value."
      end

      filter expr(contains(name, ^arg(:query)))
    end
  end

  validations do
    validate {Diffo.Validations.HrefEndsWithId, id: :id, href: :href} do
      where [present(:id), present(:href)]
    end

    validate attribute_equals(:type, :PlaceRef) do
      where present(:referred_type)
      message "when referred_type is present, type must be PlaceRef"
    end

    validate attribute_does_not_equal(:type, :PlaceRef) do
      where absent(:referred_type)
      message "when referred_type is absent, type must be not be PlaceRef"
    end
  end

  preparations do
    prepare build(sort: [id: :asc, name: :asc])
  end
end
