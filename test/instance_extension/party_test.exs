# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.InstanceExtension.PartyTest do
  @moduledoc false
  use ExUnit.Case

  alias Diffo.Provider.Instance.Extension.Info, as: InstanceInfo
  alias Diffo.Provider.Party.Extension.Info, as: PartyInfo
  alias Diffo.Test.Organization
  alias Diffo.Test.Person
  alias Diffo.Test.Shelf
  alias Diffo.Test.Nbn
  alias Diffo.Test.Servo
  alias Diffo.Provider.Instance.Party

  setup_all do
    AshNeo4j.BoltyHelper.start()
  end

  setup do
    on_exit(fn ->
      AshNeo4j.Neo4jHelper.delete_all()
    end)
  end

  describe "Party DSL — Organization" do
    test "instance roles are declared" do
      roles = PartyInfo.instances(Organization)
      assert length(roles) == 1
      assert hd(roles).role == :facilitator
      assert hd(roles).party_type == Diffo.Provider.Instance
    end

    test "no party roles declared" do
      assert PartyInfo.parties(Organization) == []
    end
  end

  describe "Party DSL — Person" do
    test "party roles are declared" do
      roles = PartyInfo.parties(Person)
      assert length(roles) == 1
      assert hd(roles).role == :manager
      assert hd(roles).party_type == Diffo.Test.Person
    end

    test "no instance roles declared" do
      assert PartyInfo.instances(Person) == []
    end
  end

  describe "Instance DSL — Shelf parties" do
    test "party declarations are accessible via info" do
      parties = InstanceInfo.parties(Shelf)
      roles = Enum.map(parties, & &1.role)
      assert :facilitator in roles
      assert :overseer in roles
    end

    test "party types are correct" do
      parties = InstanceInfo.parties(Shelf)
      facilitator = Enum.find(parties, &(&1.role == :facilitator))
      overseer = Enum.find(parties, &(&1.role == :overseer))
      assert facilitator.party_type == Organization
      assert overseer.party_type == Person
    end

    test "singular party defaults to multiple: false" do
      parties = InstanceInfo.parties(Shelf)
      facilitator = Enum.find(parties, &(&1.role == :facilitator))
      assert facilitator.multiple == false
    end

    test "reference: true is declared" do
      parties = InstanceInfo.parties(Shelf)
      provider = Enum.find(parties, &(&1.role == :provider))
      assert provider.reference == true
      assert provider.multiple == false
    end

    test "reference defaults to false" do
      parties = InstanceInfo.parties(Shelf)
      facilitator = Enum.find(parties, &(&1.role == :facilitator))
      assert facilitator.reference == false
    end

    test "calculate: is declared" do
      parties = InstanceInfo.parties(Shelf)
      manager = Enum.find(parties, &(&1.role == :manager))
      assert manager.calculate == :manager_calc
    end

    test "parties (plural) sets multiple: true" do
      parties = InstanceInfo.parties(Shelf)
      installer = Enum.find(parties, &(&1.role == :installer))
      assert installer.multiple == true
    end

    test "parties (plural) constraints are declared" do
      parties = InstanceInfo.parties(Shelf)
      installer = Enum.find(parties, &(&1.role == :installer))
      assert installer.constraints == [min: 1, max: 3]
    end
  end

  describe "Instance DSL — parties enforcement" do
    setup do
      {:ok, org} = Nbn.create_organization(%{name: "Acme"})
      {:ok, p1} = Nbn.create_person(%{name: "Alice"})
      {:ok, p2} = Nbn.create_person(%{name: "Bob"})
      {:ok, p3} = Nbn.create_person(%{name: "Carol"})
      {:ok, p4} = Nbn.create_person(%{name: "Dave"})
      %{org: org, p1: p1, p2: p2, p3: p3, p4: p4}
    end

    test "undeclared role is rejected", %{p1: p1} do
      parties = [%Party{id: p1.id, role: :unknown}]
      assert {:error, _} = Servo.build_shelf(%{name: "s", parties: parties})
    end

    test "installer below min (0 < 1) is rejected" do
      assert {:error, _} = Servo.build_shelf(%{name: "s", parties: []})
    end

    test "installer above max (4 > 3) is rejected", %{p1: p1, p2: p2, p3: p3, p4: p4} do
      parties = [
        %Party{id: p1.id, role: :installer},
        %Party{id: p2.id, role: :installer},
        %Party{id: p3.id, role: :installer},
        %Party{id: p4.id, role: :installer}
      ]
      assert {:error, _} = Servo.build_shelf(%{name: "s", parties: parties})
    end

    test "valid single installer is accepted", %{org: org, p1: p1} do
      parties = [
        %Party{id: org.id, role: :facilitator},
        %Party{id: p1.id, role: :installer}
      ]
      assert {:ok, shelf} = Servo.build_shelf(%{name: "s", parties: parties})
      assert length(shelf.parties) == 2
    end

    test "valid max installers (3) is accepted", %{p1: p1, p2: p2, p3: p3} do
      parties = [
        %Party{id: p1.id, role: :installer},
        %Party{id: p2.id, role: :installer},
        %Party{id: p3.id, role: :installer}
      ]
      assert {:ok, _shelf} = Servo.build_shelf(%{name: "s", parties: parties})
    end
  end

  describe "BaseParty — Organization CRUD" do
    test "create and read organization" do
      {:ok, org} = Nbn.create_organization(%{name: "Acme Corp"})
      assert org.name == "Acme Corp"
      assert org.type == :Organization

      {:ok, loaded} = Nbn.get_organization_by_id(org.id)
      assert loaded.name == "Acme Corp"
    end
  end

  describe "BaseParty — Person CRUD" do
    test "create and read person" do
      {:ok, person} = Nbn.create_person(%{name: "Alice"})
      assert person.name == "Alice"
      assert person.type == :Individual

      {:ok, loaded} = Nbn.get_person_by_id(person.id)
      assert loaded.name == "Alice"
    end
  end
end
