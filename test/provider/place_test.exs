defmodule Diffo.Provider.PlaceTest do
  @moduledoc false
  use ExUnit.Case
  use Outstand

  setup_all do
    AshNeo4j.BoltxHelper.start()
  end

  setup do
    on_exit(fn ->
      AshNeo4j.Neo4jHelper.delete_all()
    end)
  end

  describe "Diffo.Provider read Places" do
    test "list places - success" do
      delete_all_places()

      Diffo.Provider.create_place!(%{
        id: "LOC000000123456",
        name: :locationId,
        referredType: :GeographicAddress
      })

      Diffo.Provider.create_place!(%{
        id: "LOC000000897353",
        name: :locationId,
        referredType: :GeographicAddress
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
        referredType: :GeographicAddress
      })

      Diffo.Provider.create_place!(%{
        id: "LOC000000123456",
        name: :locationId,
        referredType: :GeographicAddress
      })

      Diffo.Provider.create_place!(%{
        id: "163435034",
        name: :adborId,
        referredType: :GeographicAddress
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
        referredType: :GeographicAddress
      })

      Diffo.Provider.create_place!(%{
        id: "LOC000000123456",
        name: :locationId,
        referredType: :GeographicAddress
      })

      Diffo.Provider.create_place!(%{
        id: "163435034",
        name: :adborId,
        referredType: :GeographicAddress
      })

      places = Diffo.Provider.find_places_by_name!("location")
      assert length(places) == 2
      # should be sorted
      assert List.first(places).id == "LOC000000123456"
      assert List.last(places).id == "LOC000000897353"
    end
  end

  describe "Diffo.Provider create Places" do
    test "create a GeographicAddress referredType place  - success" do
      place =
        Diffo.Provider.create_place!(%{
          id: "LOC000000897353",
          name: :locationId,
          referredType: :GeographicAddress
        })

      assert place.type == :PlaceRef
    end

    test "create a GeographicLocation referredType place - success" do
      place =
        Diffo.Provider.create_place!(%{
          id: "CSA000000124343",
          name: :csaId,
          referredType: :GeographicLocation
        })

      assert place.type == :PlaceRef
    end

    test "create a GeographicSite place referredType - success" do
      place =
        Diffo.Provider.create_place!(%{id: "3NBA", name: :poiId, referredType: :GeographicSite})

      assert place.type == :PlaceRef
    end

    test "create a GeographicAddress type place  - success" do
      place =
        Diffo.Provider.create_place!(%{
          id: "LOC000000897353",
          name: :locationId,
          type: :GeographicAddress
        })

      assert place.referredType == nil
    end

    test "create a GeographicLocation type place - success" do
      place =
        Diffo.Provider.create_place!(%{
          id: "CSA000000124343",
          name: :csaId,
          type: :GeographicLocation
        })

      assert place.referredType == nil
    end

    test "create a GeographicSite place type - success" do
      place = Diffo.Provider.create_place!(%{id: "3NBA", name: :poiId, type: :GeographicSite})
      assert place.referredType == nil
    end

    test "create a GeographicSite place type with a href - success" do
      place =
        Diffo.Provider.create_place!(%{
          id: "3NBA",
          href: "place/nbnco/3NBA",
          name: :poiId,
          type: :GeographicSite
        })

      assert place.referredType == nil
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

    test "update place referredType - success" do
      place =
        Diffo.Provider.create_place!(%{
          id: "5ADE",
          name: :locationId,
          referredType: :GeographicAddress
        })

      updated_place = place |> Diffo.Provider.update_place!(%{referredType: :GeographicSite})
      assert updated_place.referredType == :GeographicSite
    end

    test "update place type to referredType - success" do
      place =
        Diffo.Provider.create_place!(%{
          id: "LOC000000897353",
          name: :locationId,
          type: :GeographicAddress
        })

      updated_place =
        place
        |> Diffo.Provider.update_place!(%{type: :PlaceRef, referredType: :GeographicAddress})

      assert updated_place.type == :PlaceRef
      assert updated_place.referredType == :GeographicAddress
    end

    test "update place referredType to type - success" do
      place =
        Diffo.Provider.create_place!(%{
          id: "LOC000000897353",
          name: :locationId,
          referredType: :GeographicAddress
        })

      updated_place =
        place |> Diffo.Provider.update_place!(%{type: :GeographicAddress, referredType: nil})

      assert updated_place.type == :GeographicAddress
      assert updated_place.referredType == nil
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

    test "update referredType - failure - type Place cannot have referredTYpe" do
      place =
        Diffo.Provider.create_place!(%{
          id: "LOC000000897353",
          name: :locationId,
          type: :GeographicAddress
        })

      {:error, _error} = place |> Diffo.Provider.update_place(%{referredType: :GeographicAddress})
    end

    test "update referredType - failure - PlaceRef requires referredType" do
      place =
        Diffo.Provider.create_place!(%{
          id: "LOC000000897353",
          name: :locationId,
          type: :PlaceRef,
          referredType: :GeographicAddress
        })

      {:error, _error} = place |> Diffo.Provider.update_place(%{referredType: nil})
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

    test "encode json place referredType - success" do
      place =
        Diffo.Provider.create_place!(%{
          id: "LOC000000897353",
          name: :locationId,
          href: "place/nbnco/LOC000000897353",
          referredType: :GeographicAddress
        })

      encoding = Jason.encode!(place)

      assert encoding ==
               "{\"id\":\"LOC000000897353\",\"href\":\"place/nbnco/LOC000000897353\",\"name\":\"locationId\",\"@referredType\":\"GeographicAddress\",\"@type\":\"PlaceRef\"}"
    end
  end

  describe "Diffo.Provider outstanding Places" do
    test "resolve a general expected place" do
      place =
        Diffo.Provider.create_place!(%{
          id: "LOC000000897353",
          name: "locationId",
          href: "place/nbnco/LOC000000897353",
          referredType: :GeographicAddress
        })

      expected_place = %Diffo.Provider.Place{
        id: ~r/LOC\d{12}/,
        name: "locationId",
        type: :PlaceRef,
        referredType: :GeographicAddress
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
          referredType: :GeographicAddress
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
          referredType: :GeographicAddress
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
