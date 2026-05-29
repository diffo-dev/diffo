# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.GeographicLocationTest do
  @moduledoc false
  use ExUnit.Case, async: true
  @moduletag :provider_only

  alias Diffo.Provider.GeographicLocation

  setup do
    AshNeo4j.Sandbox.checkout()
    on_exit(&AshNeo4j.Sandbox.rollback/0)
  end

  describe "build with location point" do
    test "creates a GeographicLocation with a WGS-84 point" do
      assert {:ok, location} =
               Ash.create(
                 GeographicLocation,
                 %{
                   id: "LOC-CREATE-001",
                   name: "Sydney CBD point",
                   location: %Geo.Point{coordinates: {151.2093, -33.8688}, srid: 4326},
                   accuracy: 10.0
                 },
                 action: :build,
                 domain: Diffo.Provider
               )

      assert location.id == "LOC-CREATE-001"
      assert location.type == :GeographicLocation
      assert %Geo.Point{coordinates: {151.2093, -33.8688}, srid: 4326} = location.location
      assert location.accuracy == 10.0
    end
  end

  describe "build with bounds polygon" do
    test "creates a GeographicLocation with a WGS-84 polygon" do
      polygon = %Geo.Polygon{
        coordinates: [
          [
            {151.0, -33.5},
            {151.5, -33.5},
            {151.5, -34.0},
            {151.0, -34.0},
            {151.0, -33.5}
          ]
        ],
        srid: 4326
      }

      assert {:ok, location} =
               Ash.create(
                 GeographicLocation,
                 %{
                   id: "LOC-CREATE-002",
                   name: "Sydney region",
                   bounds: polygon
                 },
                 action: :build,
                 domain: Diffo.Provider
               )

      assert location.type == :GeographicLocation
      assert %Geo.Polygon{srid: 4326} = location.bounds
    end
  end

  describe "tightened validation — GeographicLocation requires geometry" do
    test "fails to build when neither location nor bounds is set" do
      assert {:error, %Ash.Error.Invalid{}} =
               Ash.create(
                 GeographicLocation,
                 %{id: "LOC-CREATE-003", name: "No geometry"},
                 action: :build,
                 domain: Diffo.Provider
               )
    end
  end

  describe "TMF wire shape" do
    test "encodes point as GeoJsonPoint with @baseType GeographicLocation" do
      location =
        Ash.create!(
          GeographicLocation,
          %{
            id: "LOC-JSON-001",
            name: "Point JSON",
            location: %Geo.Point{coordinates: {151.2093, -33.8688}, srid: 4326},
            accuracy: 5.5
          },
          action: :build,
          domain: Diffo.Provider
        )

      json = Jason.encode!(location) |> Jason.decode!()

      assert json["@type"] == "GeoJsonPoint"
      assert json["@baseType"] == "GeographicLocation"
      assert json["id"] == "LOC-JSON-001"
      assert json["accuracy"] == 5.5
      assert json["geoJson"]["geometry"]["type"] == "Point"
      assert json["geoJson"]["geometry"]["coordinates"] == [151.2093, -33.8688]
      refute Map.has_key?(json, "location")
      refute Map.has_key?(json, "bounds")
    end

    test "encodes polygon as GeoJsonPolygon with @baseType GeographicLocation" do
      polygon = %Geo.Polygon{
        coordinates: [
          [
            {151.0, -33.5},
            {151.5, -33.5},
            {151.5, -34.0},
            {151.0, -34.0},
            {151.0, -33.5}
          ]
        ],
        srid: 4326
      }

      location =
        Ash.create!(
          GeographicLocation,
          %{id: "LOC-JSON-002", name: "Polygon JSON", bounds: polygon},
          action: :build,
          domain: Diffo.Provider
        )

      json = Jason.encode!(location) |> Jason.decode!()

      assert json["@type"] == "GeoJsonPolygon"
      assert json["@baseType"] == "GeographicLocation"
      assert json["geoJson"]["geometry"]["type"] == "Polygon"
    end
  end

  describe "cross-world projection (the cascade pattern)" do
    test "AshNeo4j.worlds/1 resolves a GeographicLocation node to its concrete leaf" do
      location =
        Ash.create!(
          GeographicLocation,
          %{
            id: "LOC-WORLDS-001",
            name: "Worlds Test",
            location: %Geo.Point{coordinates: {151.0, -33.0}, srid: 4326}
          },
          action: :build,
          domain: Diffo.Provider
        )

      [{domain, resource} | _] = AshNeo4j.worlds(location)

      assert domain == Diffo.Provider
      assert resource == Diffo.Provider.GeographicLocation
    end
  end
end
