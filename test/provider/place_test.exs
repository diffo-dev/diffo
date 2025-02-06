defmodule Diffo.Provider.Place_Test do
  @moduledoc false
  use ExUnit.Case
  use Diffo.DataCase, async: true

  describe "Diffo.Provider read Places" do
    test "list places - success" do
      Diffo.Provider.create_place!(%{id: "LOC000000123456", name: :locationId, referredType: :GeographicAddress})
      Diffo.Provider.create_place!(%{id: "LOC000000897353", name: :locationId, referredType: :GeographicAddress})
      places = Diffo.Provider.list_places!()
      assert length(places) == 2
      # should be sorted
      assert List.first(places).id == "LOC000000123456"
      assert List.last(places).id == "LOC000000897353"
    end

    test "find places by name - success" do
      Diffo.Provider.create_place!(%{id: "LOC000000897353", name: :locationId, referredType: :GeographicAddress})
      Diffo.Provider.create_place!(%{id: "LOC000000123456", name: :locationId, referredType: :GeographicAddress})
      Diffo.Provider.create_place!(%{id: "163435034", name: :adborId, referredType: :GeographicAddress})
      places = Diffo.Provider.find_places_by_name!("location")
      assert length(places) == 2
      # should be sorted
      assert List.first(places).id == "LOC000000123456"
      assert List.last(places).id == "LOC000000897353"
    end
  end

  describe "Diffo.Provider create Places" do
    test "create a GeographicAddress referredType place  - success" do
      place = Diffo.Provider.create_place!(%{id: "LOC000000897353", name: :locationId, referredType: :GeographicAddress})
      assert place.type == :PlaceRef
    end

    test "create a GeographicLocation referredType place - success" do
      place = Diffo.Provider.create_place!(%{id: "CSA000000124343", name: :csaId, referredType: :GeographicLocation})
      assert place.type == :PlaceRef
    end

    test "create a GeographicSite place referredType - success" do
      place = Diffo.Provider.create_place!(%{id: "3NBA", name: :poiId, referredType: :GeographicSite})
      assert place.type == :PlaceRef
    end

    test "create a GeographicAddress type place  - success" do
      place = Diffo.Provider.create_place!(%{id: "LOC000000897353", name: :locationId, type: :GeographicAddress})
      assert place.referredType == nil
    end

    test "create a GeographicLocation type place - success" do
      place = Diffo.Provider.create_place!(%{id: "CSA000000124343", name: :csaId, type: :GeographicLocation})
      assert place.referredType == nil
    end

    test "create a GeographicSite place type - success" do
      place = Diffo.Provider.create_place!(%{id: "3NBA", name: :poiId, type: :GeographicSite})
      assert place.referredType == nil
    end

    test "create a GeographicSite place type with a href - success" do
      place = Diffo.Provider.create_place!(%{id: "3NBA", href: "place/nbnco/3NBA", name: :poiId, type: :GeographicSite})
      assert place.referredType == nil
    end
  end

  describe "Diffo.Provider update Places" do

    test "update href - success" do
      place = Diffo.Provider.create_place!(%{id: "LOC000000897353", name: :locationId, type: :GeographicAddress})
      updated_place = place |> Diffo.Provider.update_place!(%{href: "place/nbnco/LOC000000897353"})
      assert updated_place.href == "place/nbnco/LOC000000897353"
    end

    test "update place name - success" do
      place = Diffo.Provider.create_place!(%{id: "LOC000000897353", name: :location, type: :GeographicAddress})
      updated_place = place |> Diffo.Provider.update_place!(%{name: :locationId})
      assert updated_place.name == "locationId"
    end

    test "update place type - success" do
      place = Diffo.Provider.create_place!(%{id: "3BEN", name: :locationId, type: :GeographicAddress})
      updated_place = place |> Diffo.Provider.update_place!(%{type: :GeographicSite})
      assert updated_place.type == :GeographicSite
    end

    test "update place referredType - success" do
      place = Diffo.Provider.create_place!(%{id: "5ADE", name: :locationId, referredType: :GeographicAddress})
      updated_place = place |> Diffo.Provider.update_place!(%{referredType: :GeographicSite})
      assert updated_place.referredType == :GeographicSite
    end

    test "update place type to referredType - success" do
      place = Diffo.Provider.create_place!(%{id: "LOC000000897353", name: :locationId, type: :GeographicAddress})
      updated_place = place |> Diffo.Provider.update_place!(%{type: :PlaceRef, referredType: :GeographicAddress})
      assert updated_place.type == :PlaceRef
      assert updated_place.referredType == :GeographicAddress
    end

    test "update place referredType to type - success" do
      place = Diffo.Provider.create_place!(%{id: "LOC000000897353", name: :locationId, referredType: :GeographicAddress})
      updated_place = place |> Diffo.Provider.update_place!(%{type: :GeographicAddress, referredType: nil})
      assert updated_place.type == :GeographicAddress
      assert updated_place.referredType == :nil
    end

    test "update id - failure - href does not end with id" do
      place = Diffo.Provider.create_place!(%{id: "LOC000000897353", name: :locationId, type: :GeographicAddress})
      {:error, _error} = place |> Diffo.Provider.update_place(%{href: "place/nbnco/LOC000000897354"})
    end

    test "update referredType - failure - type Place cannot have referredTYpe" do
      place = Diffo.Provider.create_place!(%{id: "LOC000000897353", name: :locationId, type: :GeographicAddress})
      {:error, _error} = place |> Diffo.Provider.update_place(%{referredType: :GeographicAddress})
    end

    test "update referredType - failure - PlaceRef requires referredType" do
      place = Diffo.Provider.create_place!(%{id: "LOC000000897353", name: :locationId, type: :PlaceRef, referredType: :GeographicAddress})
      {:error, _error} = place |> Diffo.Provider.update_place(%{referredType: :nil})
    end

    test "update id - failure - not updatable" do
      place = Diffo.Provider.create_place!(%{id: "LOC000000897353", name: :locationId, type: :GeographicAddress})
      {:error, _error} = place |> Diffo.Provider.update_place(%{id: "LOC0000008973534"})
    end
  end

  describe "Diffo.Provider delete Places" do
    test "bulk delete" do
      Diffo.Provider.delete_place!(Diffo.Provider.list_places!())
    end
  end
end
