defmodule Diffo.Provider.PlaceRefTest do
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

  describe "Diffo.Provider read PlaceRefs" do
    test "list place refs - success" do
      delete_all_place_refs()
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance = Diffo.Provider.create_instance!(%{specification_id: specification.id})
      place1 = Diffo.Provider.create_place!(%{id: "LOC000000123456", name: :locationId, type: :GeographicAddress})
      place2 = Diffo.Provider.create_place!(%{id: "LOC000000897353", name: :locationId, type: :GeographicAddress})
      Diffo.Provider.create_place_ref!(%{instance_id: instance.id, role: :CustomerSite, place_id: place1.id})
      Diffo.Provider.create_place_ref!(%{instance_id: instance.id, role: :CustomerSite, place_id: place2.id})
      place_refs = Diffo.Provider.list_place_refs!()
      assert length(place_refs) == 2
      # should be sorted
      assert List.first(place_refs).place_id == "LOC000000123456"
      assert List.last(place_refs).place_id == "LOC000000897353"
    end

    test "find place refs by place id - success" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance = Diffo.Provider.create_instance!(%{specification_id: specification.id})
      place1 = Diffo.Provider.create_place!(%{id: "LOC000000897353", name: :locationId, referredType: :GeographicAddress})
      place2 = Diffo.Provider.create_place!(%{id: "LOC000000123456", name: :locationId, referredType: :GeographicAddress})
      place3 = Diffo.Provider.create_place!(%{id: "163435034", name: :adborId, referredType: :GeographicAddress})
      Diffo.Provider.create_place_ref!(%{instance_id: instance.id, role: :CustomerSite, place_id: place1.id})
      Diffo.Provider.create_place_ref!(%{instance_id: instance.id, role: :CustomerSite, place_id: place2.id})
      Diffo.Provider.create_place_ref!(%{instance_id: instance.id, role: :CustomerSite, place_id: place3.id})
      place_refs = Diffo.Provider.find_place_refs_by_place_id!("LOC")
      assert length(place_refs) == 2
      # should be sorted
      assert List.first(place_refs).place_id == "LOC000000123456"
      assert List.last(place_refs).place_id == "LOC000000897353"
    end

    test "list place refs by related instance - success" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance1 = Diffo.Provider.create_instance!(%{specification_id: specification.id})
      instance2 = Diffo.Provider.create_instance!(%{specification_id: specification.id})
      place1 = Diffo.Provider.create_place!(%{id: "LOC000000897353", name: :locationId, referredType: :GeographicAddress})
      place2 = Diffo.Provider.create_place!(%{id: "LOC000000897354", name: :locationId, referredType: :GeographicAddress})
      place3 = Diffo.Provider.create_place!(%{id: "CSA000000123456", name: :csaId, referredType: :GeographicLocation})
      Diffo.Provider.create_place_ref!(%{instance_id: instance1.id, role: :CustomerSite, place_id: place1.id})
      Diffo.Provider.create_place_ref!(%{instance_id: instance1.id, role: :ServingArea, place_id: place3.id})
      Diffo.Provider.create_place_ref!(%{instance_id: instance2.id, role: :CustomerSite, place_id: place2.id})
      Diffo.Provider.create_place_ref!(%{instance_id: instance2.id, role: :ServingArea, place_id: place3.id})
      place_refs = Diffo.Provider.list_place_refs_by_instance_id!(instance1.id)
      assert length(place_refs) == 2
      # should be sorted
      assert List.first(place_refs).place_id == "CSA000000123456"
      assert List.last(place_refs).place_id == "LOC000000897353"
    end

    test "list place refs by related place id - success" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance1 = Diffo.Provider.create_instance!(%{specification_id: specification.id})
      instance2 = Diffo.Provider.create_instance!(%{specification_id: specification.id})
      place1 = Diffo.Provider.create_place!(%{id: "LOC000000897353", name: :locationId, referredType: :GeographicAddress})
      place2 = Diffo.Provider.create_place!(%{id: "LOC000000897354", name: :locationId, referredType: :GeographicAddress})
      place3 = Diffo.Provider.create_place!(%{id: "CSA000000123456", name: :csaId, referredType: :GeographicLocation})
      Diffo.Provider.create_place_ref!(%{instance_id: instance1.id, role: :CustomerSite, place_id: place1.id})
      Diffo.Provider.create_place_ref!(%{instance_id: instance1.id, role: :ServingArea, place_id: place3.id})
      Diffo.Provider.create_place_ref!(%{instance_id: instance2.id, role: :CustomerSite, place_id: place2.id})
      Diffo.Provider.create_place_ref!(%{instance_id: instance2.id, role: :ServingArea, place_id: place3.id})
      place_refs = Diffo.Provider.list_place_refs_by_place_id!(place3.id)
      assert length(place_refs) == 2
      # should be sorted
      assert List.first(place_refs).instance_id == instance1.id
      assert List.last(place_refs).instance_id == instance2.id
    end
  end

  describe "Diffo.Provider create PlaceRefs" do
    test "create a CustomerSite role place ref  - success" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance = Diffo.Provider.create_instance!(%{specification_id: specification.id})
      place = Diffo.Provider.create_place!(%{id: "LOC000000897353", name: :locationId, type: :GeographicAddress})
      place_ref = Diffo.Provider.create_place_ref!(%{instance_id: instance.id, role: :CustomerSite, place_id: place.id})
      assert place_ref.role == :CustomerSite
    end
  end

  describe "Diffo.Provider update PlaceRefs" do

    test "update role to nil - success" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance = Diffo.Provider.create_instance!(%{specification_id: specification.id})
      place = Diffo.Provider.create_place!(%{id: "LOC000000897353", name: :locationId, type: :GeographicAddress})
      place_ref = Diffo.Provider.create_place_ref!(%{instance_id: instance.id, role: :CustomerSite, place_id: place.id})
      updated_place_ref = place_ref |> Diffo.Provider.update_place_ref!(%{role: nil})
      assert updated_place_ref.role == nil
    end

    test "update role - success" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance = Diffo.Provider.create_instance!(%{specification_id: specification.id})
      place = Diffo.Provider.create_place!(%{id: "LOC000000897353", name: :locationId, type: :GeographicAddress})
      place_ref = Diffo.Provider.create_place_ref!(%{instance_id: instance.id, role: :NetworkSite, place_id: place.id})
      updated_place_ref = place_ref |> Diffo.Provider.update_place_ref!(%{role: :CustomerSite})
      assert updated_place_ref.role == :CustomerSite
    end

    test "update id - failure - not updatable" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance = Diffo.Provider.create_instance!(%{specification_id: specification.id})
      place = Diffo.Provider.create_place!(%{id: "LOC000000897353", name: :locationId, type: :GeographicAddress})
      place_ref = Diffo.Provider.create_place_ref!(%{instance_id: instance.id, role: :CustomerSite, place_id: place.id})
      {:error, _error} = place_ref |> Diffo.Provider.update_place_ref(%{id: "59889f96-3cb4-4d74-b911-56f230859b40"})
    end

    test "update instance_id - failure - not updatable" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance = Diffo.Provider.create_instance!(%{specification_id: specification.id})
      place = Diffo.Provider.create_place!(%{id: "LOC000000897353", name: :locationId, type: :GeographicAddress})
      place_ref = Diffo.Provider.create_place_ref!(%{instance_id: instance.id, role: :CustomerSite, place_id: place.id})
      other_instance = Diffo.Provider.create_instance!(%{specification_id: specification.id})
      {:error, _error} = place_ref |> Diffo.Provider.update_place_ref(%{instance_id: other_instance.id})
    end

    test "update place_id - failure - not updatable" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance = Diffo.Provider.create_instance!(%{specification_id: specification.id})
      place = Diffo.Provider.create_place!(%{id: "LOC000000897353", name: :locationId, type: :GeographicAddress})
      place_ref = Diffo.Provider.create_place_ref!(%{instance_id: instance.id, role: :CustomerSite, place_id: place.id})
      other_place = Diffo.Provider.create_place!(%{id: "LOC000000897354", name: :locationId, type: :GeographicAddress})
      {:error, _error} = place_ref |> Diffo.Provider.update_place_ref(%{place_id: other_place.id})
    end
  end

  describe "Diffo.Provider encode PlaceRefs" do
    test "encode json place type - success" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance = Diffo.Provider.create_instance!(%{specification_id: specification.id})
      place = Diffo.Provider.create_place!(%{id: "LOC000000897353", name: :locationId, href: "place/nbnco/LOC000000897353", type: :GeographicAddress})
      place_ref = Diffo.Provider.create_place_ref!(%{instance_id: instance.id, role: :CustomerSite, place_id: place.id})
      encoding = Jason.encode!(place_ref)
      assert encoding == "{\"id\":\"LOC000000897353\",\"href\":\"place/nbnco/LOC000000897353\",\"name\":\"locationId\",\"role\":\"CustomerSite\",\"@type\":\"GeographicAddress\"}"
    end

    test "encode json place referredType - success" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance = Diffo.Provider.create_instance!(%{specification_id: specification.id})
      place = Diffo.Provider.create_place!(%{id: "LOC000000897353", name: :locationId, href: "place/nbnco/LOC000000897353", referredType: :GeographicAddress})
      place_ref = Diffo.Provider.create_place_ref!(%{instance_id: instance.id, role: :CustomerSite, place_id: place.id})
      encoding = Jason.encode!(place_ref)
      assert encoding == "{\"id\":\"LOC000000897353\",\"href\":\"place/nbnco/LOC000000897353\",\"name\":\"locationId\",\"role\":\"CustomerSite\",\"@referredType\":\"GeographicAddress\",\"@type\":\"PlaceRef\"}"
    end
  end

  describe "Diffo.Provider outstanding PlaceRefs" do
    test "resolve a general expected place" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance = Diffo.Provider.create_instance!(%{specification_id: specification.id})
      place = Diffo.Provider.create_place!(%{id: "LOC000000897353", name: :locationId, href: "place/nbnco/LOC000000897353", referredType: :GeographicAddress})
      place_ref = Diffo.Provider.create_place_ref!(%{instance_id: instance.id, role: :CustomerSite, place_id: place.id})

      expected_place_ref = %Diffo.Provider.PlaceRef{place_id: ~r/LOC\d{12}/, name: "locationId", role: :CustomerSite, referredType: "GeographicAddress", type: "PlaceRef"}
      refute expected_place_ref >>> place_ref
    end
  end

  describe "Diffo.Provider delete PlaceRefs" do
    test "delete place_ref with related instance - success" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance = Diffo.Provider.create_instance!(%{specification_id: specification.id})
      place = Diffo.Provider.create_place!(%{id: "LOC000000897353", name: :locationId, href: "place/nbnco/LOC000000897353", referredType: :GeographicAddress})
      place_ref = Diffo.Provider.create_place_ref!(%{instance_id: instance.id, role: :CustomerSite, place_id: place.id})
      :ok = Diffo.Provider.delete_place_ref(place_ref)
      {:error, _error} = Diffo.Provider.get_place_ref_by_id(place_ref.id)
    end
  end

  def delete_all_place_refs() do
    place_refs = Diffo.Provider.list_place_refs!()
    %Ash.BulkResult{status: :success} = Diffo.Provider.delete_place_ref(place_refs)
    Diffo.Provider.PlaceTest.delete_all_places()
  end
end
