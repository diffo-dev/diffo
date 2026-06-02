# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Test.Place.CellSite do
  @moduledoc """
  Test fixture for the `use_diffo_place_geo` livebook — a `GeographicLocation` leaf
  (`BasePlace` + `BaseGeographicLocation`) carrying `transmit_power` and two **expression
  calculations** built on AshNeo4j's graph-native `st_distance_in_meters`:

    * `distance_m` — geodesic distance to a given `:at` point.
    * `signal_strength` — power flux density (W/m²) `transmit_power / (4·π·d²)`.

  Exercised by `inherited_characteristic`-unrelated `cell_site_test.exs` to prove the
  spatial expressions evaluate against the AshNeo4j sandbox.
  """
  alias Diffo.Provider.BasePlace
  alias Diffo.Provider.BaseGeographicLocation
  alias Diffo.Test.Nbn

  use Ash.Resource,
    fragments: [BasePlace, BaseGeographicLocation],
    domain: Nbn

  resource do
    description "A test cell site (GeographicLocation) with spatial calculations"
    plural_name :cell_sites
  end

  actions do
    create :build do
      accept [
        :id,
        :href,
        :name,
        :location,
        :bounds,
        :accuracy,
        :cell_id,
        :technology,
        :transmit_power
      ]

      change set_attribute(:type, :GeographicLocation)
    end
  end

  attributes do
    attribute :cell_id, :string, public?: true

    attribute :technology, :atom do
      description "the radio access technology of the cell site"
      public? true
      default :FixedWireless
      constraints one_of: [:FixedWireless, :Mobile4G, :Mobile5G]
    end

    # equivalent isotropically radiated power, in watts
    attribute :transmit_power, :float, public?: true
  end

  calculations do
    # the distance expression between two points — graph-native st_distance_in_meters
    calculate :distance_m, :float, expr(st_distance_in_meters(location, ^arg(:at))) do
      argument :at, AshGeo.GeoJson do
        constraints geo_types: [:point], force_srid: 4326
        allow_nil? false
      end
    end

    # signal strength (power flux density, W/m²) from EIRP and that distance
    calculate :signal_strength,
              :float,
              expr(
                transmit_power /
                  (4 * 3.141592653589793 *
                     st_distance_in_meters(location, ^arg(:at)) *
                     st_distance_in_meters(location, ^arg(:at)))
              ) do
      argument :at, AshGeo.GeoJson do
        constraints geo_types: [:point], force_srid: 4326
        allow_nil? false
      end
    end
  end
end
