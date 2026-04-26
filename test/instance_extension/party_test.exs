# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.InstanceExtension.PartyTest do
  @moduledoc false
  use ExUnit.Case

  alias Diffo.Provider.Instance.Extension.Info, as: InstanceInfo
  alias Diffo.Provider.Party.Extension.Info, as: PartyInfo
  alias Diffo.Test.Organisation
  alias Diffo.Test.Person
  alias Diffo.Test.Shelf
  alias Diffo.Test.Nbn

  setup_all do
    AshNeo4j.BoltyHelper.start()
  end

  setup do
    on_exit(fn ->
      AshNeo4j.Neo4jHelper.delete_all()
    end)
  end

  describe "Party DSL — Organisation" do
    test "instance roles are declared" do
      roles = PartyInfo.instance(Organisation)
      assert length(roles) == 1
      assert hd(roles).role == :facilitates
      assert hd(roles).party_type == Diffo.Provider.Instance
    end

    test "no party roles declared" do
      assert PartyInfo.party(Organisation) == []
    end
  end

  describe "Party DSL — Person" do
    test "party roles are declared" do
      roles = PartyInfo.party(Person)
      assert length(roles) == 1
      assert hd(roles).role == :managed_by
      assert hd(roles).party_type == Diffo.Test.Person
    end

    test "no instance roles declared" do
      assert PartyInfo.instance(Person) == []
    end
  end

  describe "Instance DSL — Shelf parties" do
    test "party declarations are accessible via info" do
      parties = InstanceInfo.parties(Shelf)
      roles = Enum.map(parties, & &1.role)
      assert :facilitated_by in roles
      assert :overseen_by in roles
    end

    test "party types are correct" do
      parties = InstanceInfo.parties(Shelf)
      facilitated_by = Enum.find(parties, &(&1.role == :facilitated_by))
      overseen_by = Enum.find(parties, &(&1.role == :overseen_by))
      assert facilitated_by.party_type == Organisation
      assert overseen_by.party_type == Person
    end
  end

  describe "BaseParty — Organisation CRUD" do
    test "create and read organisation" do
      {:ok, org} = Nbn.create_organisation(%{name: "Acme Corp", kind: :organization})
      assert org.name == "Acme Corp"
      assert org.kind == :organization

      {:ok, loaded} = Nbn.get_organisation_by_id(org.id)
      assert loaded.name == "Acme Corp"
    end
  end

  describe "BaseParty — Person CRUD" do
    test "create and read person" do
      {:ok, person} = Nbn.create_person(%{name: "Alice", kind: :individual})
      assert person.name == "Alice"
      assert person.kind == :individual

      {:ok, loaded} = Nbn.get_person_by_id(person.id)
      assert loaded.name == "Alice"
    end
  end
end
