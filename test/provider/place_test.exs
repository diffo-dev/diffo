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

      Diffo.Provider.create_place!(:PlaceRef, %{
        id: "LOC000000123456",
        name: :locationId,
        referred_type: :GeographicAddress
      })

      Diffo.Provider.create_place!(:PlaceRef, %{
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
      Diffo.Provider.create_place!(:PlaceRef, %{
        id: "LOC000000897353",
        name: :locationId,
        referred_type: :GeographicAddress
      })

      Diffo.Provider.create_place!(:PlaceRef, %{
        id: "LOC000000123456",
        name: :locationId,
        referred_type: :GeographicAddress
      })

      Diffo.Provider.create_place!(:PlaceRef, %{
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
      Diffo.Provider.create_place!(:PlaceRef, %{
        id: "LOC000000897353",
        name: :locationId,
        referred_type: :GeographicAddress
      })

      Diffo.Provider.create_place!(:PlaceRef, %{
        id: "LOC000000123456",
        name: :locationId,
        referred_type: :GeographicAddress
      })

      Diffo.Provider.create_place!(:PlaceRef, %{
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
        Diffo.Provider.create_place!(:PlaceRef, %{
          id: "LOC000000897353",
          name: :locationId,
          referred_type: :GeographicAddress
        })

      assert place.type == :PlaceRef
    end

    test "create a GeographicLocation referred_type place - success" do
      place =
        Diffo.Provider.create_place!(:PlaceRef, %{
          id: "CSA000000124343",
          name: :csaId,
          referred_type: :GeographicLocation
        })

      assert place.type == :PlaceRef
    end

    test "create a GeographicSite place referred_type - success" do
      place =
        Diffo.Provider.create_place!(:PlaceRef, %{id: "3NBA", name: :poiId, referred_type: :GeographicSite})

      assert place.type == :PlaceRef
    end

    test "create a GeographicAddress type place  - success" do
      place =
        Diffo.Provider.create_place!(:GeographicAddress, %{
          id: "LOC000000897353",
          name: :locationId})

      assert place.referred_type == nil
    end

    test "create a GeographicLocation type place - success" do
      place =
        Diffo.Provider.create_place!(:GeographicLocation, %{
          id: "CSA000000124343",
          name: :csaId,
          location: %Geo.Point{coordinates: {151.0, -33.0}, srid: 4326}})

      assert place.referred_type == nil
      assert place.type == :GeographicLocation
    end

    test "create a GeographicSite place type - success" do
      place = Diffo.Provider.create_place!(:GeographicSite, %{id: "3NBA", name: :poiId})
      assert place.referred_type == nil
    end

    test "create a GeographicSite place type with a href - success" do
      place =
        Diffo.Provider.create_place!(:GeographicSite, %{
          id: "3NBA",
          href: "place/nbnco/3NBA",
          name: :poiId})

      assert place.referred_type == nil
    end

    test "create a Place that already exists, preserving attributes - success" do
      place =
        Diffo.Provider.create_place!(:GeographicSite, %{
          id: "3NBA",
          href: "place/nbnco/3NBA",
          name: :poiId})

      Diffo.Provider.create_place!(:GeographicSite, %{id: "3NBA", name: :poiId})
      refreshed_place = Diffo.Provider.get_place_by_id!(place.id)
      assert refreshed_place.href == "place/nbnco/3NBA"
    end

    test "create a Place that already exists, adding attributes - success" do
      place = Diffo.Provider.create_place!(:GeographicSite, %{id: "3NBA", name: :poiId})

      Diffo.Provider.create_place!(:GeographicSite, %{
        id: "3NBA",
        href: "place/nbnco/3NBA",
        name: :poiId})

      refreshed_place = Diffo.Provider.get_place_by_id!(place.id)
      assert refreshed_place.href == "place/nbnco/3NBA"
    end
  end

  describe "Diffo.Provider update Places" do
    test "update href - success" do
      place =
        Diffo.Provider.create_place!(:GeographicAddress, %{
          id: "LOC000000897353",
          name: :locationId})

      updated_place =
        place |> Diffo.Provider.update_place!(%{href: "place/nbnco/LOC000000897353"})

      assert updated_place.href == "place/nbnco/LOC000000897353"
    end

    test "update place name - success" do
      place =
        Diffo.Provider.create_place!(:GeographicAddress, %{
          id: "LOC000000897353",
          name: :location})

      updated_place = place |> Diffo.Provider.update_place!(%{name: :locationId})
      assert updated_place.name == "locationId"
    end

    # Note: type-conversion tests removed — under the cascade, typed leaves
    # (GeographicAddress/Site/Location) have fixed `:type`; changing type means
    # creating a different resource. The cascade-incompatible scenarios are:
    #
    #   * change `:type` from one cascade subtype to another
    #   * convert a typed leaf to a PlaceRef placeholder by setting `:type` and
    #     `:referred_type`
    #   * clear `:referred_type` to turn a placeholder into a typed leaf
    #
    # PlaceRef placeholders (`:PlaceRef` dispatcher) still support
    # `:referred_type` updates via the abstract Provider.Place's `:update` action.

    test "update place referred_type on a PlaceRef placeholder - success" do
      place =
        Diffo.Provider.create_place!(:PlaceRef, %{
          id: "5ADE",
          name: :locationId,
          referred_type: :GeographicAddress
        })

      updated_place = place |> Diffo.Provider.update_place!(%{referred_type: :GeographicSite})
      assert updated_place.referred_type == :GeographicSite
    end

    test "update id - failure - href does not end with id" do
      place =
        Diffo.Provider.create_place!(:GeographicAddress, %{
          id: "LOC000000897353",
          name: :locationId})

      {:error, _error} =
        place |> Diffo.Provider.update_place(%{href: "place/nbnco/LOC000000897354"})
    end

    test "update referred_type - failure - type Place cannot have referredTYpe" do
      place =
        Diffo.Provider.create_place!(:GeographicAddress, %{
          id: "LOC000000897353",
          name: :locationId})

      {:error, _error} =
        place |> Diffo.Provider.update_place(%{referred_type: :GeographicAddress})
    end

    test "update referred_type - failure - PlaceRef requires referred_type" do
      place =
        Diffo.Provider.create_place!(:PlaceRef, %{
          id: "LOC000000897353",
          name: :locationId,
          referred_type: :GeographicAddress
        })

      {:error, _error} = place |> Diffo.Provider.update_place(%{referred_type: nil})
    end

    test "update id - failure - not updatable" do
      place =
        Diffo.Provider.create_place!(:GeographicAddress, %{
          id: "LOC000000897353",
          name: :locationId})

      {:error, _error} = place |> Diffo.Provider.update_place(%{id: "LOC0000008973534"})
    end
  end

  describe "Diffo.Provider encode Places" do
    test "encode json place type - success" do
      place =
        Diffo.Provider.create_place!(:GeographicAddress, %{
          id: "LOC000000897353",
          name: :locationId,
          href: "place/nbnco/LOC000000897353"})

      encoding = Jason.encode!(place)

      assert encoding ==
               "{\"id\":\"LOC000000897353\",\"href\":\"place/nbnco/LOC000000897353\",\"name\":\"locationId\",\"@type\":\"GeographicAddress\"}"
    end

    test "encode json place referred_type - success" do
      place =
        Diffo.Provider.create_place!(:PlaceRef, %{
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
    # Sydney-ish bounding box used by the box-create tests
    @bbox %Geo.Polygon{
      coordinates: [
        [{151.0, -34.0}, {151.5, -34.0}, {151.5, -33.5}, {151.0, -33.5}, {151.0, -34.0}]
      ],
      srid: 4326
    }
    @inside_pt %Geo.Point{coordinates: {151.25, -33.75}, srid: 4326}
    @outside_pt %Geo.Point{coordinates: {150.0, -30.0}, srid: 4326}

    test "create a GeographicLocation with a location point - success" do
      place =
        Diffo.Provider.create_place!(:GeographicLocation, %{
          id: "LOC-PT-1",
          name: :locationId,
          location: @inside_pt
        })

      assert place.type == :GeographicLocation
      assert %Geo.Point{coordinates: {151.25, -33.75}} = place.location
      assert place.bounds == nil
    end

    test "create a GeographicLocation with a bounds box - success" do
      place =
        Diffo.Provider.create_place!(:GeographicLocation, %{
          id: "CSA-PG-1",
          name: :csaId,
          bounds: @bbox
        })

      assert place.type == :GeographicLocation
      assert place.location == nil
      assert %Geo.Polygon{coordinates: [_ring]} = place.bounds
    end

    test "create with both location and bounds - failure" do
      {:error, error} =
        Diffo.Provider.create_place(:GeographicLocation, %{
          id: "BAD-BOTH-1",
          name: :badId,
          location: @inside_pt,
          bounds: @bbox
        })

      assert is_struct(error, Ash.Error.Invalid)
    end

    test "create location on non-:GeographicLocation type - failure" do
      {:error, error} =
        Diffo.Provider.create_place(:GeographicAddress, %{
          id: "BAD-GA-1",
          name: :badId,
          location: @inside_pt
        })

      assert is_struct(error, Ash.Error.Invalid)
    end

    test "create bounds on non-:GeographicLocation type - failure" do
      {:error, error} =
        Diffo.Provider.create_place(:GeographicSite, %{
          id: "BAD-GS-1",
          name: :badId,
          bounds: @bbox
        })

      assert is_struct(error, Ash.Error.Invalid)
    end

    # Currently failing under AshNeo4j 0.8.0 — see
    # https://github.com/diffo-dev/ash_neo4j/issues/283 (geo attribute set to
    # nil on update doesn't clear persisted companions). Plain string attributes
    # (e.g. :href) clear correctly under the same path, so this is geo-specific.
    # Re-enable when the upstream fix lands.
    @tag :skip
    test "update from location to bounds - success" do
      place =
        Diffo.Provider.create_place!(:GeographicLocation, %{
          id: "LOC-SWITCH-1",
          name: :locationId,
          location: @inside_pt
        })

      updated =
        place
        |> Diffo.Provider.update_place!(%{location: nil, bounds: @bbox})

      assert updated.location == nil
      assert %Geo.Polygon{} = updated.bounds
    end

    test "st_contains pushes down to Cypher and returns boxes containing the point" do
      require Ash.Query

      Diffo.Provider.create_place!(:GeographicLocation, %{
        id: "CSA-SQ-1",
        name: :csaId,
        bounds: @bbox
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

      Diffo.Provider.create_place!(:GeographicLocation, %{
        id: "LOC-NEAR-1",
        name: :locationId,
        location: @inside_pt
      })

      # within ~50 km — same suburb scale
      near = %Geo.Point{coordinates: {151.26, -33.76}, srid: 4326}

      hits =
        Diffo.Provider.Place
        |> Ash.Query.filter(st_dwithin(location, ^near, 5_000))
        |> Ash.read!()

      assert Enum.any?(hits, &(&1.id == "LOC-NEAR-1"))
    end
  end

  describe "Diffo.Provider TMF675 json" do
    # Vodafone House — the GeoJsonPoint sample from TMF675 §"Json representation sample"
    @vodafone_house_pt %Geo.Point{
      coordinates: {-1.3197581470012665, 51.41671197068097},
      srid: 4326
    }
    # Vodafone HQ campus bounding box — the GeoJsonPolygon sample from TMF675 §"SAMPLE USE CASES"
    # closed CCW ring per RFC 7946 §3.1.6
    @vodafone_campus_box %Geo.Polygon{
      coordinates: [
        [
          {-1.3236808776855469, 51.413962700391956},
          {-1.3168895244598389, 51.413962700391956},
          {-1.3168895244598389, 51.417662927117235},
          {-1.3236808776855469, 51.417662927117235},
          {-1.3236808776855469, 51.413962700391956}
        ]
      ],
      srid: 4326
    }

    test "matches TMF675 GeoJsonPoint sample (Vodafone House) verbatim" do
      place =
        Diffo.Provider.create_place!(:GeographicLocation, %{
          id: "10c5f5b5-e408",
          name: "Vodafone House",
          location: @vodafone_house_pt
        })

      assert place |> Jason.encode!() |> Jason.decode!() == %{
               "id" => "10c5f5b5-e408",
               "name" => "Vodafone House",
               "@baseType" => "GeographicLocation",
               "@type" => "GeoJsonPoint",
               "geoJson" => %{
                 "geometry" => %{
                   "type" => "Point",
                   "coordinates" => [-1.3197581470012665, 51.41671197068097]
                 }
               }
             }
    end

    test "matches TMF675 GeoJsonPolygon sample (Vodafone HQ campus bbox), closed per RFC 7946" do
      place =
        Diffo.Provider.create_place!(:GeographicLocation, %{
          id: "VFG-CAMPUS-BBOX",
          name: "Vodafone HQ campus",
          bounds: @vodafone_campus_box
        })

      assert place |> Jason.encode!() |> Jason.decode!() == %{
               "id" => "VFG-CAMPUS-BBOX",
               "name" => "Vodafone HQ campus",
               "@baseType" => "GeographicLocation",
               "@type" => "GeoJsonPolygon",
               "geoJson" => %{
                 "geometry" => %{
                   "type" => "Polygon",
                   "coordinates" => [
                     [
                       [-1.3236808776855469, 51.413962700391956],
                       [-1.3168895244598389, 51.413962700391956],
                       [-1.3168895244598389, 51.417662927117235],
                       [-1.3236808776855469, 51.417662927117235],
                       [-1.3236808776855469, 51.413962700391956]
                     ]
                   ]
                 }
               }
             }
    end

    test "encode json GeoJsonPoint - success" do
      place =
        Diffo.Provider.create_place!(:GeographicLocation, %{
          id: "LOC-PT-2",
          name: :locationId,
          location: %Geo.Point{coordinates: {151.25, -33.75}, srid: 4326}
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
        Diffo.Provider.create_place!(:GeographicLocation, %{
          id: "CSA-PG-2",
          name: :csaId,
          bounds: %Geo.Polygon{
            coordinates: [
              [
                {151.0, -34.0},
                {151.5, -34.0},
                {151.5, -33.5},
                {151.0, -33.5},
                {151.0, -34.0}
              ]
            ],
            srid: 4326
          }
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
        Diffo.Provider.create_place!(:GeographicAddress, %{
          id: "REG-GA-1",
          name: :locationId,
          href: "place/nbnco/REG-GA-1"})

      decoded = place |> Jason.encode!() |> Jason.decode!()
      assert decoded["@type"] == "GeographicAddress"
      refute Map.has_key?(decoded, "@baseType")
      refute Map.has_key?(decoded, "geoJson")
    end
  end

  describe "Diffo.Provider service qualification (SQ)" do
    # CSA-SYD-01 covers a chunk of Sydney
    @sq_csa_bbox %Geo.Polygon{
      coordinates: [
        [{151.0, -34.0}, {151.5, -34.0}, {151.5, -33.5}, {151.0, -33.5}, {151.0, -34.0}]
      ],
      srid: 4326
    }
    # NSA-FOO-01 is a black-spot box inside the CSA
    @sq_nsa_bbox %Geo.Polygon{
      coordinates: [
        [
          {151.10, -33.90},
          {151.20, -33.90},
          {151.20, -33.80},
          {151.10, -33.80},
          {151.10, -33.90}
        ]
      ],
      srid: 4326
    }
    # Inside CSA, outside the NSA → served
    @sq_served_pt %Geo.Point{coordinates: {151.25, -33.75}, srid: 4326}
    # Inside CSA AND inside NSA → blocked (NSA dominates)
    @sq_blocked_pt %Geo.Point{coordinates: {151.15, -33.85}, srid: 4326}
    # Outside any CSA → out-of-footprint
    @sq_oof_pt %Geo.Point{coordinates: {150.0, -30.0}, srid: 4326}

    setup do
      Diffo.Provider.create_place!(:GeographicLocation, %{
        id: "CSA-SYD-01",
        name: :csa,
        bounds: @sq_csa_bbox
      })

      Diffo.Provider.create_place!(:GeographicLocation, %{
        id: "NSA-FOO-01",
        name: :nsa,
        bounds: @sq_nsa_bbox
      })

      :ok
    end

    test "served: point inside the CSA, no NSA covers it" do
      assert {:served, %Diffo.Provider.Place{id: "CSA-SYD-01"}} = qualify(@sq_served_pt)
    end

    test "blocked: point inside the CSA AND inside an NSA — NSA dominates" do
      assert {:blocked, %Diffo.Provider.Place{id: "NSA-FOO-01"}} = qualify(@sq_blocked_pt)
    end

    test "out_of_footprint: point outside every CSA" do
      assert {:out_of_footprint, nil} = qualify(@sq_oof_pt)
    end
  end

  # NSA dominates — check it first, short-circuit if hit. Discriminates CSAs from NSAs
  # by the `name` attribute since BasePlace doesn't (yet) carry a subtype kind.
  defp qualify(%Geo.Point{} = point) do
    require Ash.Query

    nsa_hits =
      Diffo.Provider.Place
      |> Ash.Query.filter(name == "nsa" and st_contains(bounds, ^point))
      |> Ash.Query.limit(1)
      |> Ash.read!()

    case nsa_hits do
      [nsa] ->
        {:blocked, nsa}

      [] ->
        csa_hits =
          Diffo.Provider.Place
          |> Ash.Query.filter(name == "csa" and st_contains(bounds, ^point))
          |> Ash.Query.limit(1)
          |> Ash.read!()

        case csa_hits do
          [csa] -> {:served, csa}
          [] -> {:out_of_footprint, nil}
        end
    end
  end

  describe "Diffo.Provider outstanding Places" do
    test "resolve a general expected place" do
      place =
        Diffo.Provider.create_place!(:PlaceRef, %{
          id: "LOC000000897353",
          name: "locationId",
          href: "place/nbnco/LOC000000897353",
          referred_type: :GeographicAddress
        })

      expected_place = %Diffo.Provider.Place{
        id: ~r/LOC\d{12}/,
        name: "locationId",
        referred_type: :GeographicAddress
      }

      refute expected_place >>> place
    end
  end

  describe "Diffo.Provider delete Places" do
    test "delete place - success" do
      place =
        Diffo.Provider.create_place!(:PlaceRef, %{
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
        Diffo.Provider.create_place!(:PlaceRef, %{
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
