defmodule Diffo.Provider.Party_Test do
  @moduledoc false
  use ExUnit.Case
  use Diffo.DataCase, async: true

  describe "Diffo.Provider read Parties" do
    test "list parties - success" do
      Diffo.Provider.create_party!(%{id: "IND000000123456", name: :individualId, referredType: :Individual})
      Diffo.Provider.create_party!(%{id: "IND000000897353", name: :individualId, referredType: :Individual})
      parties = Diffo.Provider.list_parties!()
      assert length(parties) == 2
      # should be sorted
      assert List.first(parties).id == "IND000000123456"
      assert List.last(parties).id == "IND000000897353"
    end

    test "find parties by name - success" do
      Diffo.Provider.create_party!(%{id: "IND000000897353", name: :individualId, referredType: :Individual})
      Diffo.Provider.create_party!(%{id: "IND000000123456", name: :individualId, referredType: :Individual})
      Diffo.Provider.create_party!(%{id: "ORG000163435034", name: :organizationId, referredType: :Organization})
      parties = Diffo.Provider.find_parties_by_name!("individual")
      assert length(parties) == 2
      # should be sorted
      assert List.first(parties).id == "IND000000123456"
      assert List.last(parties).id == "IND000000897353"
    end
  end

  describe "Diffo.Provider create Parties" do
    test "create a Individual referredType party  - success" do
      party = Diffo.Provider.create_party!(%{id: "IND000000897353", name: :individualId, referredType: :Individual})
      assert party.type == :PartyRef
    end

    test "create a Organization referredType party - success" do
      party = Diffo.Provider.create_party!(%{id: "ORG000000124343", name: :organizationId, referredType: :Organization})
      assert party.type == :PartyRef
    end

    test "create a Entity party referredType - success" do
      party = Diffo.Provider.create_party!(%{id: "T8_NUMBERS", name: :entityId, referredType: :Entity})
      assert party.type == :PartyRef
    end

    test "create a Individual type party  - success" do
      party = Diffo.Provider.create_party!(%{id: "IND000000897353", name: :individualId, type: :Individual})
      assert party.referredType == nil
    end

    test "create a Organization type party - success" do
      party = Diffo.Provider.create_party!(%{id: "ORG000000124343", name: :organizationId, type: :Organization})
      assert party.referredType == nil
    end

    test "create a Entity party type - success" do
      party = Diffo.Provider.create_party!(%{id: "T8_NUMBERS", name: :entityId, type: :Entity})
      assert party.referredType == nil
    end

    test "create a Entity party type with a href - success" do
      party = Diffo.Provider.create_party!(%{id: "T8_NUMBERS", href: "entity/internal/T8_NUMBERS", name: :entityId, type: :Entity})
      assert party.referredType == nil
    end
  end

  describe "Diffo.Provider update Parties" do

    test "update href - success" do
      party = Diffo.Provider.create_party!(%{id: "IND000000897353", name: :individualId, type: :Individual})
      updated_party = party |> Diffo.Provider.update_party!(%{href: "party/nbnco/IND000000897353"})
      assert updated_party.href == "party/nbnco/IND000000897353"
    end

    test "update party name - success" do
      party = Diffo.Provider.create_party!(%{id: "IND000000897353", name: :location, type: :Individual})
      updated_party = party |> Diffo.Provider.update_party!(%{name: :individualId})
      assert updated_party.name == "individualId"
    end

    test "update party type - success" do
      party = Diffo.Provider.create_party!(%{id: "3BEN", name: :individualId, type: :Individual})
      updated_party = party |> Diffo.Provider.update_party!(%{type: :Entity})
      assert updated_party.type == :Entity
    end

    test "update party referredType - success" do
      party = Diffo.Provider.create_party!(%{id: "5ADE", name: :individualId, referredType: :Individual})
      updated_party = party |> Diffo.Provider.update_party!(%{referredType: :Entity})
      assert updated_party.referredType == :Entity
    end

    test "update party type to referredType - success" do
      party = Diffo.Provider.create_party!(%{id: "IND000000897353", name: :individualId, type: :Individual})
      updated_party = party |> Diffo.Provider.update_party!(%{type: :PartyRef, referredType: :Individual})
      assert updated_party.type == :PartyRef
      assert updated_party.referredType == :Individual
    end

    test "update party referredType to type - success" do
      party = Diffo.Provider.create_party!(%{id: "IND000000897353", name: :individualId, referredType: :Individual})
      updated_party = party |> Diffo.Provider.update_party!(%{type: :Individual, referredType: nil})
      assert updated_party.type == :Individual
      assert updated_party.referredType == :nil
    end

    test "update id - failure - href does not end with id" do
      party = Diffo.Provider.create_party!(%{id: "IND000000897353", name: :individualId, type: :Individual})
      {:error, _error} = party |> Diffo.Provider.update_party(%{href: "party/nbnco/IND000000897354"})
    end

    test "update referredType - failure - type Party cannot have referredTYpe" do
      party = Diffo.Provider.create_party!(%{id: "IND000000897353", name: :individualId, type: :Individual})
      {:error, _error} = party |> Diffo.Provider.update_party(%{referredType: :Individual})
    end

    test "update referredType - failure - PartyRef requires referredType" do
      party = Diffo.Provider.create_party!(%{id: "IND000000897353", name: :individualId, type: :PartyRef, referredType: :Individual})
      {:error, _error} = party |> Diffo.Provider.update_party(%{referredType: :nil})
    end

    test "update id - failure - not updatable" do
      party = Diffo.Provider.create_party!(%{id: "IND000000897353", name: :individualId, type: :Individual})
      {:error, _error} = party |> Diffo.Provider.update_party(%{id: "IND0000008973534"})
    end
  end

  describe "Diffo.Provider delete Parties" do
    test "bulk delete" do
      Diffo.Provider.delete_party!(Diffo.Provider.list_parties!())
    end
  end
end
