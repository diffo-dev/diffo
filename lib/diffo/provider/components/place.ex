# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Place do
  @moduledoc """
  Ash Resource for a TMF Place.

  For `:GeographicLocation` records the JSON encoder folds `location` /
  `bounds` into a TMF675 `geoJson.geometry.{type, coordinates}` payload and
  promotes the existing `@type` (the base TMF class) to `@baseType`, deriving
  a concrete `@type` of `GeoJsonPoint` or `GeoJsonPolygon` from which
  attribute is populated.
  """
  use Ash.Resource, fragments: [Diffo.Provider.BasePlace], domain: Diffo.Provider

  resource do
    description "An Ash Resource for a TMF Place"
    plural_name :places
  end

  jason do
    pick [:id, :href, :name, :referred_type, :type, :location, :bounds]
    compact true
    rename referred_type: "@referredType", type: "@type"
    customize &Diffo.Provider.Place.encode_geo_json/2
  end

  outstanding do
    expect [:id, :name, :referred_type, :type]
  end

  @doc false
  def encode_geo_json(result, record) do
    case {record.location, record.bounds} do
      {nil, nil} ->
        result

      {%Bolty.Types.Point{x: lon, y: lat}, nil} ->
        result
        |> List.keydelete(:location, 0)
        |> List.keydelete(:bounds, 0)
        |> rebrand_type("GeoJsonPoint")
        |> List.keystore("geoJson", 0,
          {"geoJson", %{geometry: %{type: "Point", coordinates: [lon, lat]}}}
        )

      {nil, %AshNeo4j.Type.Box{sw: sw, ne: ne}} ->
        ring = [
          [sw.x, sw.y],
          [ne.x, sw.y],
          [ne.x, ne.y],
          [sw.x, ne.y],
          [sw.x, sw.y]
        ]

        result
        |> List.keydelete(:location, 0)
        |> List.keydelete(:bounds, 0)
        |> rebrand_type("GeoJsonPolygon")
        |> List.keystore("geoJson", 0,
          {"geoJson", %{geometry: %{type: "Polygon", coordinates: [ring]}}}
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
