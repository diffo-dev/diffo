# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.BaseGeographicLocation do
  @moduledoc """
  Ash Resource Fragment for TMF675 GeographicLocation — geometry-bearing Place
  (a point or polygon region in WGS-84).

  Compose with `BasePlace` on a concrete leaf to require the BasePlace geometry
  attributes (`location` or `bounds`) be set, add the `accuracy` attribute, and
  carry the TMF675 GeoJson wire shape through `BasePlace`'s existing
  `encode_geo_json/2` customize.

  `Diffo.Provider.GeographicLocation` uses this fragment directly as the
  out-of-the-box TMF GeographicLocation resource. Domain extenders compose the
  same two fragments on their own leaf.

  ## Attributes

  - `accuracy` — float, meters of positional accuracy (TMF675 `accuracy` field).
    Free-form numeric; not constrained.

  ## Geometry (inherited from `BasePlace`)

  - `location` — `AshGeo.GeoJson` (`:point`, WGS-84). `%Geo.Point{coordinates: {lon, lat}, srid: 4326}`.
  - `bounds` — `AshGeo.GeoJson` (`:polygon`, WGS-84). `%Geo.Polygon{coordinates: [ring], srid: 4326}`.

  ## Tightened validation

  `BasePlace` already enforces:

  - At most one of `[location, bounds]` may be set.
  - Geometry is only allowed when `type == :GeographicLocation`.

  This fragment adds the inverse direction:

  - `type == :GeographicLocation` **requires** at least one of `[location, bounds]` set.

  ## Wire shape (TMF675)

  Inherits BasePlace's `encode_geo_json/2` customize which rebrands `@type` to
  `GeoJsonPoint` or `GeoJsonPolygon` and emits the geometry as a TMF675 `geoJson`
  field with `@baseType: "GeographicLocation"`.
  """
  use Spark.Dsl.Fragment,
    of: Ash.Resource,
    extensions: [AshOutstanding.Resource, AshJason.Resource]

  attributes do
    attribute :accuracy, :float do
      description "positional accuracy in meters"
      allow_nil? true
      public? true
    end
  end

  validations do
    validate present([:location, :bounds], at_least: 1) do
      where attribute_equals(:type, :GeographicLocation)
      message "GeographicLocation must have location or bounds set"
    end
  end

  jason do
    pick [:id, :href, :name, :type, :location, :bounds, :accuracy]
    compact true
    rename type: "@type"
    customize &Diffo.Provider.BasePlace.encode_geo_json/2
  end

  outstanding do
    expect [:id, :name, :type]
  end
end
