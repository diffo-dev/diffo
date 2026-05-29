# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.BaseGeographicSite do
  @moduledoc """
  Ash Resource Fragment for TMF675 GeographicSite — named-location-style Place
  (exchange, office, branch, data centre, etc.).

  Compose with `BasePlace` on a concrete leaf to get the TMF GeographicSite
  attribute set, an optional projected reference to an associated
  `GeographicAddress`, TMF camelCase jason wire shape, and a site-shaped
  outstanding signature.

  `Diffo.Provider.GeographicSite` uses this fragment directly as the
  out-of-the-box TMF GeographicSite resource. Domain extenders compose the same
  two fragments on their own leaf for richer domain identity:

      defmodule MyApp.SydneyExchange do
        use Ash.Resource,
          fragments: [Diffo.Provider.BasePlace, Diffo.Provider.BaseGeographicSite],
          domain: MyApp.Domain

        attributes do
          attribute :rack_count, :integer, public?: true
        end

        actions do
          create :build do
            accept [:id, :href, :name, :site_type, :site_code, :address_id, :rack_count]
            change set_attribute(:type, :GeographicSite)
          end
        end
      end

  ## Attributes

  All site attributes are permissive — tighten on your derived leaf if needed.

  - `site_type` — atom, free-form (e.g. `:office`, `:exchange`, `:branch`,
    `:datacentre`). Convention only; not constrained.
  - `site_code` — string, an opaque human-readable identifier scoped to the
    site (e.g. `"SYD-01"`).
  - `address_id` — string FK to an associated address Place. Resolved by the
    `:address` calculation.

  ## Address association — `:address` (projected)

  A `calculate :address` calculation uses `Diffo.Provider.Calculations.ProjectedRef`
  to resolve `address_id` to the concrete `GeographicAddress` subtype (or a
  consumer-domain Address leaf) via `AshNeo4j.worlds/1`. Open-world by
  construction — works whether the target is `Provider.GeographicAddress` or
  `MyApp.PostalAddress`.

  Result is `nil` when `address_id` is unset; a concrete address struct when
  resolved; `%Diffo.Unknown{}` when the id is set but can't be projected.

  ## Wire shape (TMF675)

  `jason.pick` selects base + site fields and renames to TMF camelCase
  (`siteType`, `siteCode`). Inherits BasePlace's `encode_geo_json/2` customize
  — a no-op for typical Site records (no geometry).
  """
  use Spark.Dsl.Fragment,
    of: Ash.Resource,
    extensions: [AshOutstanding.Resource, AshJason.Resource]

  attributes do
    attribute :site_type, :atom do
      description "the kind of site (e.g. :office, :exchange, :datacentre)"
      allow_nil? true
      public? true
    end

    attribute :site_code, :string do
      description "a human-readable identifier for the site"
      allow_nil? true
      public? true
    end

    attribute :address_id, :string do
      description "id of the associated address Place (resolved via :address calc)"
      allow_nil? true
      public? true
    end
  end

  calculations do
    calculate :address,
              :struct,
              {Diffo.Provider.Calculations.ProjectedRef,
               [id_field: :address_id, reader: Diffo.Provider.Place]}
  end

  jason do
    pick [:id, :href, :name, :type, :site_type, :site_code]
    compact true

    rename type: "@type",
           site_type: "siteType",
           site_code: "siteCode"

    customize &Diffo.Provider.BasePlace.encode_geo_json/2
  end

  outstanding do
    expect [:id, :name, :type]
  end
end
