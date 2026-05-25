# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.PlaceTest do
  @moduledoc false
  use ExUnit.Case, async: true
  @moduletag :provider_only
  use Outstand

  setup do
    AshNeo4j.Sandbox.checkout()
    on_exit(&AshNeo4j.Sandbox.rollback/0)
  end

  describe "Diffo.Provider read Places" do
    test "list places - success" do
      delete_all_places()

      Diffo.Provider.create_place!(%{
        id: "LOC000000123456",
        name: :locationId,
        referred_type: :GeographicAddress
      })

      Diffo.Provider.create_place!(%{
        id: "LOC000000897353",
        name: :locationId,
        referred_type: :GeographicAddress
      })

      places = Diffo.Provider.list_places!()
      assert length(places) == 2
      # should be sorted
      assert List.first(places).id == "LOC000000123456"
      assert List.last(places).id == "LOC000000897353"
    end

    test "find places by id - success" do
      Diffo.Provider.create_place!(%{
        id: "LOC000000897353",
        name: :locationId,
        referred_type: :GeographicAddress
      })

      Diffo.Provider.create_place!(%{
        id: "LOC000000123456",
        name: :locationId,
        referred_type: :GeographicAddress
      })

      Diffo.Provider.create_place!(%{
        id: "163435034",
        name: :adborId,
        referred_type: :GeographicAddress
      })

      places = Diffo.Provider.find_places_by_id!("LOC")
      assert length(places) == 2
      # should be sorted
      assert List.first(places).id == "LOC000000123456"
      assert List.last(places).id == "LOC000000897353"
    end

    test "find places by name - success" do
      Diffo.Provider.create_place!(%{
        id: "LOC000000897353",
        name: :locationId,
        referred_type: :GeographicAddress
      })

      Diffo.Provider.create_place!(%{
        id: "LOC000000123456",
        name: :locationId,
        referred_type: :GeographicAddress
      })

      Diffo.Provider.create_place!(%{
        id: "163435034",
        name: :adborId,
        referred_type: :GeographicAddress
      })

      places = Diffo.Provider.find_places_by_name!("location")
      assert length(places) == 2
      # should be sorted
      assert List.first(places).id == "LOC000000123456"
      assert List.last(places).id == "LOC000000897353"
    end
  end

  describe "Diffo.Provider create Places" do
    test "create a GeographicAddress referred_type place  - success" do
      place =
        Diffo.Provider.create_place!(%{
          id: "LOC000000897353",
          name: :locationId,
          referred_type: :GeographicAddress
        })

      assert place.type == :PlaceRef
    end

    test "create a GeographicLocation referred_type place - success" do
      place =
        Diffo.Provider.create_place!(%{
          id: "CSA000000124343",
          name: :csaId,
          referred_type: :GeographicLocation
        })

      assert place.type == :PlaceRef
    end

    test "create a GeographicSite place referred_type - success" do
      place =
        Diffo.Provider.create_place!(%{id: "3NBA", name: :poiId, referred_type: :GeographicSite})

      assert place.type == :PlaceRef
    end

    test "create a GeographicAddress type place  - success" do
      place =
        Diffo.Provider.create_place!(%{
          id: "LOC000000897353",
          name: :locationId,
          type: :GeographicAddress
        })

      assert place.referred_type == nil
    end

    test "create a GeographicLocation type place - success" do
      place =
        Diffo.Provider.create_place!(%{
          id: "CSA000000124343",
          name: :csaId,
          type: :GeographicLocation
        })

      assert place.referred_type == nil
    end

    test "create a GeographicSite place type - success" do
      place = Diffo.Provider.create_place!(%{id: "3NBA", name: :poiId, type: :GeographicSite})
      assert place.referred_type == nil
    end

    test "create a GeographicSite place type with a href - success" do
      place =
        Diffo.Provider.create_place!(%{
          id: "3NBA",
          href: "place/nbnco/3NBA",
          name: :poiId,
          type: :GeographicSite
        })

      assert place.referred_type == nil
    end

    test "create a Place that already exists, preserving attributes - success" do
      place =
        Diffo.Provider.create_place!(%{
          id: "3NBA",
          href: "place/nbnco/3NBA",
          name: :poiId,
          type: :GeographicSite
        })

      Diffo.Provider.create_place!(%{id: "3NBA", name: :poiId, type: :GeographicSite})
      refreshed_place = Diffo.Provider.get_place_by_id!(place.id)
      assert refreshed_place.href == "place/nbnco/3NBA"
    end

    test "create a Place that already exists, adding attributes - success" do
      place = Diffo.Provider.create_place!(%{id: "3NBA", name: :poiId, type: :GeographicSite})

      Diffo.Provider.create_place!(%{
        id: "3NBA",
        href: "place/nbnco/3NBA",
        name: :poiId,
        type: :GeographicSite
      })

      refreshed_place = Diffo.Provider.get_place_by_id!(place.id)
      assert refreshed_place.href == "place/nbnco/3NBA"
    end
  end

  describe "Diffo.Provider update Places" do
    test "update href - success" do
      place =
        Diffo.Provider.create_place!(%{
          id: "LOC000000897353",
          name: :locationId,
          type: :GeographicAddress
        })

      updated_place =
        place |> Diffo.Provider.update_place!(%{href: "place/nbnco/LOC000000897353"})

      assert updated_place.href == "place/nbnco/LOC000000897353"
    end

    test "update place name - success" do
      place =
        Diffo.Provider.create_place!(%{
          id: "LOC000000897353",
          name: :location,
          type: :GeographicAddress
        })

      updated_place = place |> Diffo.Provider.update_place!(%{name: :locationId})
      assert updated_place.name == "locationId"
    end

    test "update place type - success" do
      place =
        Diffo.Provider.create_place!(%{id: "3BEN", name: :locationId, type: :GeographicAddress})

      updated_place = place |> Diffo.Provider.update_place!(%{type: :GeographicSite})
      assert updated_place.type == :GeographicSite
    end

    test "update place referred_type - success" do
      place =
        Diffo.Provider.create_place!(%{
          id: "5ADE",
          name: :locationId,
          referred_type: :GeographicAddress
        })

      updated_place = place |> Diffo.Provider.update_place!(%{referred_type: :GeographicSite})
      assert updated_place.referred_type == :GeographicSite
    end

    test "update place type to referred_type - success" do
      place =
        Diffo.Provider.create_place!(%{
          id: "LOC000000897353",
          name: :locationId,
          type: :GeographicAddress
        })

      updated_place =
        place
        |> Diffo.Provider.update_place!(%{type: :PlaceRef, referred_type: :GeographicAddress})

      assert updated_place.type == :PlaceRef
      assert updated_place.referred_type == :GeographicAddress
    end

    test "update place referred_type to type - success" do
      place =
        Diffo.Provider.create_place!(%{
          id: "LOC000000897353",
          name: :locationId,
          referred_type: :GeographicAddress
        })

      updated_place =
        place |> Diffo.Provider.update_place!(%{type: :GeographicAddress, referred_type: nil})

      assert updated_place.type == :GeographicAddress
      assert updated_place.referred_type == nil
    end

    test "update id - failure - href does not end with id" do
      place =
        Diffo.Provider.create_place!(%{
          id: "LOC000000897353",
          name: :locationId,
          type: :GeographicAddress
        })

      {:error, _error} =
        place |> Diffo.Provider.update_place(%{href: "place/nbnco/LOC000000897354"})
    end

    test "update referred_type - failure - type Place cannot have referredTYpe" do
      place =
        Diffo.Provider.create_place!(%{
          id: "LOC000000897353",
          name: :locationId,
          type: :GeographicAddress
        })

      {:error, _error} =
        place |> Diffo.Provider.update_place(%{referred_type: :GeographicAddress})
    end

    test "update referred_type - failure - PlaceRef requires referred_type" do
      place =
        Diffo.Provider.create_place!(%{
          id: "LOC000000897353",
          name: :locationId,
          type: :PlaceRef,
          referred_type: :GeographicAddress
        })

      {:error, _error} = place |> Diffo.Provider.update_place(%{referred_type: nil})
    end

    test "update id - failure - not updatable" do
      place =
        Diffo.Provider.create_place!(%{
          id: "LOC000000897353",
          name: :locationId,
          type: :GeographicAddress
        })

      {:error, _error} = place |> Diffo.Provider.update_place(%{id: "LOC0000008973534"})
    end
  end

  describe "Diffo.Provider encode Places" do
    test "encode json place type - success" do
      place =
        Diffo.Provider.create_place!(%{
          id: "LOC000000897353",
          name: :locationId,
          href: "place/nbnco/LOC000000897353",
          type: :GeographicAddress
        })

      encoding = Jason.encode!(place)

      assert encoding ==
               "{\"id\":\"LOC000000897353\",\"href\":\"place/nbnco/LOC000000897353\",\"name\":\"locationId\",\"@type\":\"GeographicAddress\"}"
    end

    test "encode json place referred_type - success" do
      place =
        Diffo.Provider.create_place!(%{
          id: "LOC000000897353",
          name: :locationId,
          href: "place/nbnco/LOC000000897353",
          referred_type: :GeographicAddress
        })

      encoding = Jason.encode!(place)

      assert encoding ==
               "{\"id\":\"LOC000000897353\",\"href\":\"place/nbnco/LOC000000897353\",\"name\":\"locationId\",\"@referredType\":\"GeographicAddress\",\"@type\":\"PlaceRef\"}"
    end
  end

  describe "Diffo.Provider spatial Places" do
    alias AshNeo4j.Type.Box
    alias Bolty.Types.Point

    # Sydney-ish bounding box used by the box-create tests
    @sw Point.create(:wgs_84, 151.0, -34.0)
     # nw not needed — Box derives it from sw/ne
    @ne Point.create(:wgs_84, 151.5, -33.5)
    @inside_pt Point.create(:wgs_84, 151.25, -33.75)
    @outside_pt Point.create(:wgs_84, 150.0, -30.0)

    test "create a GeographicLocation with a location point - success" do
      place =
        Diffo.Provider.create_place!(%{
          id: "LOC-PT-1",
          name: :locationId,
          type: :GeographicLocation,
          location: @inside_pt
        })

      assert place.type == :GeographicLocation
      assert %Bolty.Types.Point{x: 151.25, y: -33.75} = place.location
      assert place.bounds == nil
    end

    test "create a GeographicLocation with a bounds box - success" do
      place =
        Diffo.Provider.create_place!(%{
          id: "CSA-PG-1",
          name: :csaId,
          type: :GeographicLocation,
          bounds: %Box{sw: @sw, ne: @ne}
        })

      assert place.type == :GeographicLocation
      assert place.location == nil
      assert %Box{sw: %Bolty.Types.Point{}, ne: %Bolty.Types.Point{}} = place.bounds
    end

    test "create with both location and bounds - failure" do
      {:error, error} =
        Diffo.Provider.create_place(%{
          id: "BAD-BOTH-1",
          name: :badId,
          type: :GeographicLocation,
          location: @inside_pt,
          bounds: %Box{sw: @sw, ne: @ne}
        })

      assert is_struct(error, Ash.Error.Invalid)
    end

    test "create location on non-:GeographicLocation type - failure" do
      {:error, error} =
        Diffo.Provider.create_place(%{
          id: "BAD-GA-1",
          name: :badId,
          type: :GeographicAddress,
          location: @inside_pt
        })

      assert is_struct(error, Ash.Error.Invalid)
    end

    test "create bounds on non-:GeographicLocation type - failure" do
      {:error, error} =
        Diffo.Provider.create_place(%{
          id: "BAD-GS-1",
          name: :badId,
          type: :GeographicSite,
          bounds: %Box{sw: @sw, ne: @ne}
        })

      assert is_struct(error, Ash.Error.Invalid)
    end

    test "update from location to bounds - success" do
      place =
        Diffo.Provider.create_place!(%{
          id: "LOC-SWITCH-1",
          name: :locationId,
          type: :GeographicLocation,
          location: @inside_pt
        })

      updated =
        place
        |> Diffo.Provider.update_place!(%{location: nil, bounds: %Box{sw: @sw, ne: @ne}})

      assert updated.location == nil
      assert %Box{} = updated.bounds
    end

    test "encode json GeoJsonPoint - success" do
      place =
        Diffo.Provider.create_place!(%{
          id: "LOC-PT-2",
          name: :locationId,
          type: :GeographicLocation,
          location: @inside_pt
        })

      decoded = place |> Jason.encode!() |> Jason.decode!()

      assert decoded == %{
               "id" => "LOC-PT-2",
               "name" => "locationId",
               "@baseType" => "GeographicLocation",
               "@type" => "GeoJsonPoint",
               "geoJson" => %{
                 "geometry" => %{"type" => "Point", "coordinates" => [151.25, -33.75]}
               }
             }
    end

    test "encode json GeoJsonPolygon - success" do
      place =
        Diffo.Provider.create_place!(%{
          id: "CSA-PG-2",
          name: :csaId,
          type: :GeographicLocation,
          bounds: %Box{sw: @sw, ne: @ne}
        })

      decoded = place |> Jason.encode!() |> Jason.decode!()

      assert decoded == %{
               "id" => "CSA-PG-2",
               "name" => "csaId",
               "@baseType" => "GeographicLocation",
               "@type" => "GeoJsonPolygon",
               "geoJson" => %{
                 "geometry" => %{
                   "type" => "Polygon",
                   "coordinates" => [
                     [
                       [151.0, -34.0],
                       [151.5, -34.0],
                       [151.5, -33.5],
                       [151.0, -33.5],
                       [151.0, -34.0]
                     ]
                   ]
                 }
               }
             }
    end

    test "encode non-spatial Place leaves @type intact - regression" do
      place =
        Diffo.Provider.create_place!(%{
          id: "REG-GA-1",
          name: :locationId,
          href: "place/nbnco/REG-GA-1",
          type: :GeographicAddress
        })

      decoded = place |> Jason.encode!() |> Jason.decode!()
      assert decoded["@type"] == "GeographicAddress"
      refute Map.has_key?(decoded, "@baseType")
      refute Map.has_key?(decoded, "geoJson")
    end

    test "st_contains pushes down to Cypher and returns boxes containing the point" do
      require Ash.Query

      Diffo.Provider.create_place!(%{
        id: "CSA-SQ-1",
        name: :csaId,
        type: :GeographicLocation,
        bounds: %Box{sw: @sw, ne: @ne}
      })

      hits =
        Diffo.Provider.Place
        |> Ash.Query.filter(st_contains(bounds, ^@inside_pt))
        |> Ash.read!()

      assert Enum.any?(hits, &(&1.id == "CSA-SQ-1"))

      misses =
        Diffo.Provider.Place
        |> Ash.Query.filter(st_contains(bounds, ^@outside_pt))
        |> Ash.read!()

      refute Enum.any?(misses, &(&1.id == "CSA-SQ-1"))
    end

    test "st_dwithin returns points near the customer point" do
      require Ash.Query

      Diffo.Provider.create_place!(%{
        id: "LOC-NEAR-1",
        name: :locationId,
        type: :GeographicLocation,
        location: @inside_pt
      })

      # within ~50 km — same suburb scale
      near = Point.create(:wgs_84, 151.26, -33.76)

      hits =
        Diffo.Provider.Place
        |> Ash.Query.filter(st_dwithin(location, ^near, 5_000))
        |> Ash.read!()

      assert Enum.any?(hits, &(&1.id == "LOC-NEAR-1"))
    end
  end

  describe "Diffo.Provider outstanding Places" do
    test "resolve a general expected place" do
      place =
        Diffo.Provider.create_place!(%{
          id: "LOC000000897353",
          name: "locationId",
          href: "place/nbnco/LOC000000897353",
          referred_type: :GeographicAddress
        })

      expected_place = %Diffo.Provider.Place{
        id: ~r/LOC\d{12}/,
        name: "locationId",
        type: :PlaceRef,
        referred_type: :GeographicAddress
      }

      refute expected_place >>> place
    end
  end

  describe "Diffo.Provider delete Places" do
    test "delete place - success" do
      place =
        Diffo.Provider.create_place!(%{
          id: "LOC000000898353",
          name: :locationId,
          href: "place/nbnco/LOC000000898353",
          referred_type: :GeographicAddress
        })

      :ok = Diffo.Provider.delete_place(place)
      {:error, _error} = Diffo.Provider.get_place_by_id(place.id)
    end

    test "delete place - failure, related PlaceRef" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance = Diffo.Provider.create_instance!(%{specified_by: specification.id})

      place =
        Diffo.Provider.create_place!(%{
          id: "LOC000000899353",
          name: :locationId,
          href: "place/nbnco/LOC000000899353",
          referred_type: :GeographicAddress
        })

      place_ref =
        Diffo.Provider.create_place_ref!(%{
          instance_id: instance.id,
          role: :CustomerSite,
          place_id: place.id
        })

      # we should not be able to delete the place if related to place_refs
      {:error, error} = Diffo.Provider.delete_place(place)
      assert is_struct(error, Ash.Error.Invalid)

      # now delete the place_ref and we should be able to delete the place
      :ok = Diffo.Provider.delete_place_ref(place_ref)
      :ok = Diffo.Provider.delete_place(place)
    end
  end

  def delete_all_places() do
    places = Diffo.Provider.list_places!()
    %Ash.BulkResult{status: :success} = Diffo.Provider.delete_place(places)
  end
end
