defmodule Diffo.Provider.PartyRefTest do
  @moduledoc false
  use ExUnit.Case
  use Diffo.DataCase, async: true
  use Outstand

  describe "Diffo.Provider read PartyRefs" do
    test "list party refs - success" do
      delete_all_party_refs()
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance = Diffo.Provider.create_instance!(%{specification_id: specification.id})
      party1 = Diffo.Provider.create_party!(%{id: "IND000000123456", name: :individualId, type: :Individual})
      party2 = Diffo.Provider.create_party!(%{id: "IND000000897353", name: :individualId, type: :Individual})
      Diffo.Provider.create_party_ref!(%{instance_id: instance.id, role: :Organization, party_id: party1.id})
      Diffo.Provider.create_party_ref!(%{instance_id: instance.id, role: :Organization, party_id: party2.id})
      party_refs = Diffo.Provider.list_party_refs!()
      assert length(party_refs) == 2
      # should be sorted
      assert List.first(party_refs).party_id == "IND000000123456"
      assert List.last(party_refs).party_id == "IND000000897353"
    end

    test "find party refs by party id - success" do
      specification = Diffo.Provider.create_specification!(%{name: "broadband"})
      instance = Diffo.Provider.create_instance!(%{specification_id: specification.id})
      party1 = Diffo.Provider.create_party!(%{id: "IND000000897353", name: :individualId, referredType: :Individual})
      party2 = Diffo.Provider.create_party!(%{id: "IND000000123456", name: :individualId, referredType: :Individual})
      party3 = Diffo.Provider.create_party!(%{id: "ORG000163435034", name: :organizationId, referredType: :Organization})
      Diffo.Provider.create_party_ref!(%{instance_id: instance.id, role: :SiteOwner, party_id: party1.id})
      Diffo.Provider.create_party_ref!(%{instance_id: instance.id, role: :PrimaryContact, party_id: party2.id})
      Diffo.Provider.create_party_ref!(%{instance_id: instance.id, role: :Reseller, party_id: party3.id})
      party_refs = Diffo.Provider.find_party_refs_by_party_id!("IND")
      assert length(party_refs) == 2
      # should be sorted
      assert List.first(party_refs).party_id == "IND000000123456"
      assert List.last(party_refs).party_id == "IND000000897353"
    end

    test "list party refs by related instance - success" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance1 = Diffo.Provider.create_instance!(%{specification_id: specification.id})
      instance2 = Diffo.Provider.create_instance!(%{specification_id: specification.id})
      party1 = Diffo.Provider.create_party!(%{id: "IND000000897353", name: :individualId, referredType: :Individual})
      party2 = Diffo.Provider.create_party!(%{id: "IND000000897354", name: :individualId, referredType: :Individual})
      party3 = Diffo.Provider.create_party!(%{id: "ORG000163435034", name: :organizationId, referredType: :Organization})
      Diffo.Provider.create_party_ref!(%{instance_id: instance1.id, role: :SiteOwner, party_id: party1.id})
      Diffo.Provider.create_party_ref!(%{instance_id: instance1.id, role: :PrimaryContact, party_id: party2.id})
      Diffo.Provider.create_party_ref!(%{instance_id: instance1.id, role: :Reseller, party_id: party3.id})
      Diffo.Provider.create_party_ref!(%{instance_id: instance2.id, role: :SiteOwner, party_id: party1.id})
      Diffo.Provider.create_party_ref!(%{instance_id: instance2.id, role: :PrimaryContact, party_id: party2.id})
      party_refs = Diffo.Provider.list_party_refs_by_instance_id!(instance1.id)
      assert length(party_refs) == 3
      # should be sorted
      assert List.first(party_refs).party_id == "IND000000897353"
      assert List.last(party_refs).party_id == "ORG000163435034"
    end

    test "list party refs by related party id - success" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance1 = Diffo.Provider.create_instance!(%{specification_id: specification.id})
      instance2 = Diffo.Provider.create_instance!(%{specification_id: specification.id})
      party1 = Diffo.Provider.create_party!(%{id: "IND000000897353", name: :individualId, referredType: :Individual})
      party2 = Diffo.Provider.create_party!(%{id: "IND000000897354", name: :individualId, referredType: :Individual})
      party3 = Diffo.Provider.create_party!(%{id: "ORG000000123456", name: :organizationId, referredType: :Organization})
      Diffo.Provider.create_party_ref!(%{instance_id: instance1.id, role: :SiteOwner, party_id: party1.id})
      Diffo.Provider.create_party_ref!(%{instance_id: instance1.id, role: :PrimaryContact, party_id: party2.id})
      Diffo.Provider.create_party_ref!(%{instance_id: instance1.id, role: :Reseller, party_id: party3.id})
      Diffo.Provider.create_party_ref!(%{instance_id: instance2.id, role: :SiteOwner, party_id: party1.id})
      Diffo.Provider.create_party_ref!(%{instance_id: instance2.id, role: :PrimaryContact, party_id: party2.id})
      party_refs = Diffo.Provider.list_party_refs_by_party_id!(party1.id)
      assert length(party_refs) == 2
      # should be sorted
      assert List.first(party_refs).instance_id == instance1.id
      assert List.last(party_refs).instance_id == instance2.id
    end
  end

  describe "Diffo.Provider create PartyRefs" do
    test "create a Organization role party ref  - success" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance = Diffo.Provider.create_instance!(%{specification_id: specification.id})
      party = Diffo.Provider.create_party!(%{id: "IND000000897353", name: :individualId, type: :Individual})
      party_ref = Diffo.Provider.create_party_ref!(%{instance_id: instance.id, role: :Organization, party_id: party.id})
      assert party_ref.role == :Organization
    end
  end

  describe "Diffo.Provider update PartyRefs" do

    test "update role to nil - success" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance = Diffo.Provider.create_instance!(%{specification_id: specification.id})
      party = Diffo.Provider.create_party!(%{id: "IND000000897353", name: :individualId, type: :Individual})
      party_ref = Diffo.Provider.create_party_ref!(%{instance_id: instance.id, role: :Organization, party_id: party.id})
      updated_party_ref = party_ref |> Diffo.Provider.update_party_ref!(%{role: nil})
      assert updated_party_ref.role == nil
    end

    test "update role - success" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance = Diffo.Provider.create_instance!(%{specification_id: specification.id})
      party = Diffo.Provider.create_party!(%{id: "IND000000897353", name: :individualId, type: :Individual})
      party_ref = Diffo.Provider.create_party_ref!(%{instance_id: instance.id, role: :NetworkSite, party_id: party.id})
      updated_party_ref = party_ref |> Diffo.Provider.update_party_ref!(%{role: :Organization})
      assert updated_party_ref.role == :Organization
    end

    test "update id - failure - not updatable" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance = Diffo.Provider.create_instance!(%{specification_id: specification.id})
      party = Diffo.Provider.create_party!(%{id: "IND000000897353", name: :individualId, type: :Individual})
      party_ref = Diffo.Provider.create_party_ref!(%{instance_id: instance.id, role: :Organization, party_id: party.id})
      {:error, _error} = party_ref |> Diffo.Provider.update_party_ref(%{id: "59889f96-3cb4-4d74-b911-56f230859b40"})
    end

    test "update instance_id - failure - not updatable" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance = Diffo.Provider.create_instance!(%{specification_id: specification.id})
      party = Diffo.Provider.create_party!(%{id: "IND000000897353", name: :individualId, type: :Individual})
      party_ref = Diffo.Provider.create_party_ref!(%{instance_id: instance.id, role: :Organization, party_id: party.id})
      other_instance = Diffo.Provider.create_instance!(%{specification_id: specification.id})
      {:error, _error} = party_ref |> Diffo.Provider.update_party_ref(%{instance_id: other_instance.id})
    end

    test "update party_id - failure - not updatable" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance = Diffo.Provider.create_instance!(%{specification_id: specification.id})
      party = Diffo.Provider.create_party!(%{id: "IND000000897353", name: :individualId, type: :Individual})
      party_ref = Diffo.Provider.create_party_ref!(%{instance_id: instance.id, role: :Organization, party_id: party.id})
      other_party = Diffo.Provider.create_party!(%{id: "IND000000897354", name: :individualId, type: :Individual})
      {:error, _error} = party_ref |> Diffo.Provider.update_party_ref(%{party_id: other_party.id})
    end
  end

  describe "Diffo.Provider encode PartyRefs" do
    test "encode json party type - success" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance = Diffo.Provider.create_instance!(%{specification_id: specification.id})
      party = Diffo.Provider.create_party!(%{id: "IND000000897353", name: :individualId, href: "party/internal/IND000000897353", type: :Individual})
      party_ref = Diffo.Provider.create_party_ref!(%{instance_id: instance.id, role: :Organization, party_id: party.id})
      encoding = Jason.encode!(party_ref)
      assert encoding == "{\"id\":\"IND000000897353\",\"href\":\"party/internal/IND000000897353\",\"name\":\"individualId\",\"role\":\"Organization\",\"@type\":\"Individual\"}"
    end

    test "encode json party referredType - success" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance = Diffo.Provider.create_instance!(%{specification_id: specification.id})
      party = Diffo.Provider.create_party!(%{id: "IND000000897353", name: :individualId, href: "party/internal/IND000000897353", referredType: :Individual})
      party_ref = Diffo.Provider.create_party_ref!(%{instance_id: instance.id, role: :Organization, party_id: party.id})
      encoding = Jason.encode!(party_ref)
      assert encoding == "{\"id\":\"IND000000897353\",\"href\":\"party/internal/IND000000897353\",\"name\":\"individualId\",\"role\":\"Organization\",\"@referredType\":\"Individual\",\"@type\":\"PartyRef\"}"
    end
  end

  describe "Diffo.Provider outstanding PartyRefs" do
    test "resolve a general expected party" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance = Diffo.Provider.create_instance!(%{specification_id: specification.id})
      party = Diffo.Provider.create_party!(%{id: "IND000000897353", name: :individualId, href: "party/internal/IND000000897353", referredType: :Individual})
      party_ref = Diffo.Provider.create_party_ref!(%{instance_id: instance.id, role: :Organization, party_id: party.id})
      expected_party_ref = %Diffo.Provider.PartyRef{party_id: ~r/IND\d{12}/, name: "individualId", role: :Organization, referredType: "Individual", type: "PartyRef"}
      refute expected_party_ref >>> party_ref
    end
  end

  describe "Diffo.Provider delete PartyRefs" do
    test "delete place_ref with related instance - success" do
      specification = Diffo.Provider.create_specification!(%{name: "nbnAccess"})
      instance = Diffo.Provider.create_instance!(%{specification_id: specification.id})
      party = Diffo.Provider.create_party!(%{id: "IND000000897353", name: :individualId, href: "party/internal/IND000000897353", referredType: :Individual})
      party_ref = Diffo.Provider.create_party_ref!(%{instance_id: instance.id, role: :Organization, party_id: party.id})
      :ok = Diffo.Provider.delete_party_ref(party_ref)
      {:error, _error} = Diffo.Provider.get_party_ref_by_id(party_ref.id)
    end
  end

  def delete_all_party_refs() do
    party_refs = Diffo.Provider.list_party_refs!()
    %Ash.BulkResult{status: :success} = Diffo.Provider.delete_party_ref(party_refs)
    Diffo.Provider.PartyTest.delete_all_parties()
  end
end
