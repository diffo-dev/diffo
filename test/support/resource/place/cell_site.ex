# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Test.Rf do
  @moduledoc """
  Free-space (Friis) link-budget calculation for a Point-located site.

  `metric: :path_loss_db` — free-space path loss to the `:at` point;
  `metric: :rssi_dbm` — isotropic received power, `eirp_dbm − path_loss_db`.

  Distance uses `AshNeo4j.Geo.haversine_meters/2` so it matches Neo4j's WGS-84
  `point.distance` model (the same value the `distance_m` expression returns). dB math
  needs `log10`, which `Ash.Expr` doesn't provide, so this is an Elixir calculation rather
  than a graph expression.
  """
  use Ash.Resource.Calculation

  @impl true
  def load(_query, opts, _context) do
    case opts[:metric] do
      :rssi_dbm -> [:location, :eirp_dbm, :frequency_mhz]
      :path_loss_db -> [:location, :frequency_mhz]
    end
  end

  @impl true
  def calculate(records, opts, context) do
    %Geo.Point{coordinates: at} = context.arguments.at
    Enum.map(records, &compute(opts[:metric], &1, at))
  end

  defp compute(:path_loss_db, %{location: %Geo.Point{coordinates: site}, frequency_mhz: f}, at)
       when is_number(f) do
    fspl_db(AshNeo4j.Geo.haversine_meters(site, at), f)
  end

  defp compute(
         :rssi_dbm,
         %{location: %Geo.Point{coordinates: site}, eirp_dbm: eirp, frequency_mhz: f},
         at
       )
       when is_number(eirp) and is_number(f) do
    Float.round(eirp - fspl_db(AshNeo4j.Geo.haversine_meters(site, at), f), 1)
  end

  defp compute(_metric, _record, _at), do: nil

  # Friis free-space path loss; d in metres, f in MHz. Line-of-sight floor.
  defp fspl_db(+0.0, _f), do: 0.0

  defp fspl_db(d_m, f_mhz) do
    Float.round(20 * :math.log10(d_m) + 20 * :math.log10(f_mhz) - 27.55, 1)
  end
end

defmodule Diffo.Test.Place.CellSite do
  @moduledoc """
  Test fixture for the `use_diffo_place_geo` livebook — a `GeographicLocation` leaf
  (`BasePlace` + `BaseGeographicLocation`) carrying an `eirp_dbm` / `frequency_mhz` and
  three calculations:

    * `distance_m` — geodesic distance to a given `:at` point (a graph-native
      `st_distance_in_meters` expression, pushing to Neo4j `point.distance`).
    * `path_loss_db` / `rssi_dbm` — free-space link budget (`Diffo.Test.Rf`); dB math is an
      Elixir calculation because `log10` isn't an `Ash.Expr` function.

  Exercised by `cell_site_test.exs` to prove both the spatial expression and the link-budget
  calcs evaluate against the AshNeo4j sandbox.
  """
  alias Diffo.Provider.BasePlace
  alias Diffo.Provider.BaseGeographicLocation
  alias Diffo.Test.Nbn

  use Ash.Resource,
    fragments: [BasePlace, BaseGeographicLocation],
    domain: Nbn

  resource do
    description "A test cell site (GeographicLocation) with spatial + link-budget calculations"
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
        :eirp_dbm,
        :frequency_mhz
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

    # equivalent isotropically radiated power, in dBm (folds in the Tx antenna gain)
    attribute :eirp_dbm, :float, public?: true

    attribute :frequency_mhz, :float do
      description "carrier frequency in MHz (drives free-space path loss)"
      public? true
      default 3500.0
    end
  end

  calculations do
    # the distance expression between two points — graph-native st_distance_in_meters
    calculate :distance_m, :float, expr(st_distance_in_meters(location, ^arg(:at))) do
      argument :at, AshGeo.GeoJson do
        constraints geo_types: [:point], force_srid: 4326
        allow_nil? false
      end
    end

    # free-space path loss (dB) to the :at point
    calculate :path_loss_db, :float, {Diffo.Test.Rf, metric: :path_loss_db} do
      argument :at, AshGeo.GeoJson do
        constraints geo_types: [:point], force_srid: 4326
        allow_nil? false
      end
    end

    # received signal level (dBm), isotropic Rx: eirp_dbm − path_loss_db
    calculate :rssi_dbm, :float, {Diffo.Test.Rf, metric: :rssi_dbm} do
      argument :at, AshGeo.GeoJson do
        constraints geo_types: [:point], force_srid: 4326
        allow_nil? false
      end
    end
  end
end
