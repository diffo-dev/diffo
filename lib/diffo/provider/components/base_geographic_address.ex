# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.BaseGeographicAddress do
  @moduledoc """
  Ash Resource Fragment for TMF673 GeographicAddress — postal-address-style Place.

  Compose with `BasePlace` on a concrete leaf to get the TMF GeographicAddress
  attribute set (`street_name`, `street_nr`, `locality`, `state_or_province`,
  `country`, `postcode`), TMF camelCase jason wire shape, and address-shaped
  outstanding signature.

  `Diffo.Provider.GeographicAddress` uses this fragment directly as the
  out-of-the-box TMF GeographicAddress resource. Domain extenders compose the
  same two fragments on their own leaf for richer domain identity:

      defmodule MyApp.SydneyOffice do
        use Ash.Resource,
          fragments: [Diffo.Provider.BasePlace, Diffo.Provider.BaseGeographicAddress],
          domain: MyApp.Domain

        attributes do
          attribute :floor, :integer, public?: true
        end

        actions do
          create :build do
            accept [:id, :href, :name, :street_name, :street_nr, :locality,
                    :state_or_province, :country, :postcode, :floor]
            change set_attribute(:type, :GeographicAddress)
          end
        end
      end

  ## Attributes

  All address attributes are permissive (`allow_nil? true`) — tighten on your
  derived leaf if your domain requires e.g. country + postcode.

  - `street_name` — the street name.
  - `street_nr` — the street number.
  - `locality` — locality / suburb.
  - `state_or_province` — state or province.
  - `country` — country (ISO 3166-1 alpha-2 code or full name; not constrained).
  - `postcode` — postcode.

  ## Wire shape (TMF673)

  `jason.pick` selects base + address fields and renames to TMF camelCase
  (`streetName`, `streetNr`, `stateOrProvince`). Inherits BasePlace's
  `encode_geo_json/2` customize — a no-op for Address records since
  `location`/`bounds` are always nil under the BasePlace validations.
  """
  use Spark.Dsl.Fragment,
    of: Ash.Resource,
    extensions: [AshOutstanding.Resource, AshJason.Resource]

  attributes do
    attribute :street_name, :string do
      description "the street name"
      allow_nil? true
      public? true
    end

    attribute :street_nr, :string do
      description "the street number"
      allow_nil? true
      public? true
    end

    attribute :locality, :string do
      description "the locality or suburb"
      allow_nil? true
      public? true
    end

    attribute :state_or_province, :string do
      description "the state or province"
      allow_nil? true
      public? true
    end

    attribute :country, :string do
      description "the country (ISO 3166-1 alpha-2 or full name)"
      allow_nil? true
      public? true
    end

    attribute :postcode, :string do
      description "the postcode"
      allow_nil? true
      public? true
    end
  end

  jason do
    pick [
      :id,
      :href,
      :name,
      :type,
      :street_name,
      :street_nr,
      :locality,
      :state_or_province,
      :country,
      :postcode
    ]

    compact true

    rename type: "@type",
           street_name: "streetName",
           street_nr: "streetNr",
           state_or_province: "stateOrProvince"

    customize &Diffo.Provider.BasePlace.encode_geo_json/2
  end

  outstanding do
    expect [:id, :name, :type]
  end
end
