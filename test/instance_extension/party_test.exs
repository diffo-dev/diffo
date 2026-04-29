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

    test "party roles are declared" do
      roles = PartyInfo.parties(Organization)
      assert length(roles) == 1
      assert hd(roles).role == :employer
    end
  end

  describe "Party DSL — Person" do
    test "party roles are declared" do
      roles = PartyInfo.parties(Person)
      assert length(roles) == 1
      assert hd(roles).role == :manager
      assert hd(roles).party_type == Diffo.Test.Person
    end

    test "instance roles are declared" do
      roles = PartyInfo.instances(Person)
      assert length(roles) == 1
      assert hd(roles).role == :overseer
    end
  end

  describe "Instance DSL — Shelf parties" do
    test "party declarations are accessible via info" do
      parties = InstanceInfo.structure_parties(Shelf)
      roles = Enum.map(parties, & &1.role)
      assert :facilitator in roles
      assert :overseer in roles
    end

    test "party types are correct" do
      parties = InstanceInfo.structure_parties(Shelf)
      facilitator = Enum.find(parties, &(&1.role == :facilitator))
      overseer = Enum.find(parties, &(&1.role == :overseer))
      assert facilitator.party_type == Organization
      assert overseer.party_type == Person
    end

    test "singular party defaults to multiple: false" do
      parties = InstanceInfo.structure_parties(Shelf)
      facilitator = Enum.find(parties, &(&1.role == :facilitator))
      assert facilitator.multiple == false
    end

    test "reference: true is declared" do
      parties = InstanceInfo.structure_parties(Shelf)
      provider = Enum.find(parties, &(&1.role == :provider))
      assert provider.reference == true
      assert provider.multiple == false
    end

    test "reference defaults to false" do
      parties = InstanceInfo.structure_parties(Shelf)
      facilitator = Enum.find(parties, &(&1.role == :facilitator))
      assert facilitator.reference == false
    end

    test "calculate: is declared" do
      parties = InstanceInfo.structure_parties(Shelf)
      manager = Enum.find(parties, &(&1.role == :manager))
      assert manager.calculate == :manager_calc
    end

    test "parties (plural) sets multiple: true" do
      parties = InstanceInfo.structure_parties(Shelf)
      installer = Enum.find(parties, &(&1.role == :installer))
      assert installer.multiple == true
    end

    test "parties (plural) constraints are declared" do
      parties = InstanceInfo.structure_parties(Shelf)
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

  describe "BaseParty — simple pattern (Organization)" do
    test "create and read using only base attributes" do
      {:ok, org} = Nbn.create_organization(%{name: "Acme Corp"})
      assert org.name == "Acme Corp"
      assert org.type == :Organization

      {:ok, loaded} = Nbn.get_organization_by_id(org.id)
      assert loaded.name == "Acme Corp"
    end
  end

  describe "BaseParty — complex pattern (Carrier)" do
    test "domain-specific attributes are accepted and persisted" do
      {:ok, carrier} = Nbn.create_carrier(%{
        name: "Acme Wholesale",
        abn: "51824753556",
        trading_name: "Acme"
      })

      assert carrier.name == "Acme Wholesale"
      assert carrier.type == :Organization
      assert carrier.abn == "51824753556"
      assert carrier.trading_name == "Acme"
    end

    test "domain-specific attributes are readable after creation" do
      {:ok, carrier} = Nbn.create_carrier(%{
        name: "Acme Wholesale",
        abn: "51824753556",
        trading_name: "Acme"
      })

      {:ok, loaded} = Nbn.get_carrier_by_id(carrier.id)
      assert loaded.abn == "51824753556"
      assert loaded.trading_name == "Acme"
    end

    test "domain-specific attributes are nil when not provided" do
      {:ok, carrier} = Nbn.create_carrier(%{name: "Bare Carrier"})
      assert carrier.abn == nil
      assert carrier.trading_name == nil
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
