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
  - `location` — optional `AshGeo.GeoJson` (`:point`, WGS-84) for point-like Places.
    Values are `%Geo.Point{coordinates: {lon, lat}, srid: 4326}`.
  - `bounds` — optional `AshGeo.GeoJson` (`:polygon`, WGS-84) for region Places.
    Values are `%Geo.Polygon{coordinates: [ring], srid: 4326}`. Polygon is the wire form;
    axis-aligned-bounding-box is the conventional use today but not type-enforced.
    At most one of `location`/`bounds` may be set on a record, and only when
    `type == :GeographicLocation` (per TMF675).

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

  ## Domain-specific attributes

  Add Ash `attribute` declarations directly to your derived resource for any fields beyond the
  base set. Those attributes can only be set via actions you declare on the derived resource —
  the base `create` action provided by `BasePlace` only accepts the base fields (`id`, `href`,
  `name`, `type`, `referred_type`). Use your domain API to call the derived resource's action:

      defmodule MyApp.DataCentre do
        use Ash.Resource, fragments: [BasePlace], domain: MyApp.Domain

        attributes do
          attribute :tier, :integer, public?: true
          attribute :power_capacity_kw, :integer, public?: true
        end

        actions do
          create :build do
            accept [:id, :href, :name, :tier, :power_capacity_kw]
            change set_attribute(:type, :GeographicSite)
          end
        end
      end

      # Use the domain API — Provider.create_place!/1 does not know about :tier
      MyApp.Domain.create_data_centre!(%{name: "M2", tier: 3, power_capacity_kw: 40_000})

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
      Diffo.Provider.Extension,
      Diffo.Provider.Place.Extension
    ]

  neo4j do
    relate [
      {:place_refs, :RELATES, :incoming, :PlaceRef}
    ]

    label :Place
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

    attribute :location, AshGeo.GeoJson do
      description "WGS-84 2D point for point-like Places (TMF675 GeoJsonPoint)"
      constraints geo_types: [:point], force_srid: 4326
      allow_nil? true
      public? true
    end

    attribute :bounds, AshGeo.GeoJson do
      description "WGS-84 2D polygon for region Places (TMF675 GeoJsonPolygon)"
      constraints geo_types: [:polygon], force_srid: 4326
      allow_nil? true
      public? true
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
      accept [:id, :href, :name, :type, :referred_type, :location, :bounds]
      upsert? true
    end

    update :update do
      description "updates the place"
      accept [:href, :name, :type, :referred_type, :location, :bounds]
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

    validate absent([:location, :bounds], at_least: 1) do
      message "at most one of [location, bounds] may be set"
    end

    validate attribute_equals(:type, :GeographicLocation) do
      where present([:location, :bounds], at_least: 1)
      message "location and bounds are only allowed when type is :GeographicLocation"
    end
  end

  preparations do
    prepare build(sort: [id: :asc, name: :asc])
  end

  jason do
    pick [:id, :href, :name, :referred_type, :type, :location, :bounds]
    compact true
    rename referred_type: "@referredType", type: "@type"
    customize &Diffo.Provider.BasePlace.encode_geo_json/2
  end

  outstanding do
    expect [:id, :name, :referred_type, :type]
  end

  @doc false
  def encode_geo_json(result, record) do
    case {record.location, record.bounds} do
      {nil, nil} ->
        result

      {%Geo.Point{coordinates: {lon, lat}}, nil} ->
        result
        |> List.keydelete(:location, 0)
        |> List.keydelete(:bounds, 0)
        |> rebrand_type("GeoJsonPoint")
        |> List.keystore("geoJson", 0,
          {"geoJson", %{geometry: %{type: "Point", coordinates: [lon, lat]}}}
        )

      {nil, %Geo.Polygon{coordinates: rings}} ->
        ring_coords =
          Enum.map(rings, fn ring ->
            Enum.map(ring, fn {x, y} -> [x, y] end)
          end)

        result
        |> List.keydelete(:location, 0)
        |> List.keydelete(:bounds, 0)
        |> rebrand_type("GeoJsonPolygon")
        |> List.keystore("geoJson", 0,
          {"geoJson", %{geometry: %{type: "Polygon", coordinates: ring_coords}}}
        )
    end
  end

  defp rebrand_type(result, concrete) do
    case List.keyfind(result, "@type", 0) do
      {"@type", _} ->
        result
        |> List.keyreplace("@type", 0, {"@type", concrete})
        |> List.keystore("@baseType", 0, {"@baseType", "GeographicLocation"})

      nil ->
        result
        |> List.keystore("@baseType", 0, {"@baseType", "GeographicLocation"})
        |> List.keystore("@type", 0, {"@type", concrete})
    end
  end
end
