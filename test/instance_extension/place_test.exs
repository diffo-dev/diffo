# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.InstanceExtension.PlaceTest do
  @moduledoc false
  use ExUnit.Case

  alias Diffo.Provider.Instance.Extension.Info, as: InstanceInfo
  alias Diffo.Provider.Place.Extension.Info, as: PlaceInfo
  alias Diffo.Test.Organization
  alias Diffo.Test.GeographicSite

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

  describe "Place DSL — GeographicSite" do
    test "instance roles are declared" do
      roles = PlaceInfo.instances(GeographicSite)
      assert length(roles) == 1
      assert hd(roles).role == :installed_at
      assert hd(roles).instance_type == Diffo.Provider.Instance
    end

    test "party roles are declared" do
      roles = PlaceInfo.parties(GeographicSite)
      assert length(roles) == 1
      assert hd(roles).role == :managed_by
      assert hd(roles).party_type == Organization
    end

    test "place roles are declared" do
      roles = PlaceInfo.places(GeographicSite)
      assert length(roles) == 1
      assert hd(roles).role == :contained_in
      assert hd(roles).place_type == Diffo.Provider.Place
    end
  end

  describe "Instance DSL — Shelf places" do
    test "place declarations are accessible via info" do
      places = InstanceInfo.structure_places(Shelf)
      roles = Enum.map(places, & &1.role)
      assert :installation_site in roles
      assert :billing_address in roles
    end

    test "place types are correct" do
      places = InstanceInfo.structure_places(Shelf)
      installation_site = Enum.find(places, &(&1.role == :installation_site))
      assert installation_site.place_type == Diffo.Provider.Place
    end

    test "singular place defaults to multiple: false" do
      places = InstanceInfo.structure_places(Shelf)
      installation_site = Enum.find(places, &(&1.role == :installation_site))
      assert installation_site.multiple == false
    end

    test "reference: true is declared" do
      places = InstanceInfo.structure_places(Shelf)
      billing = Enum.find(places, &(&1.role == :billing_address))
      assert billing.reference == true
      assert billing.multiple == false
    end

    test "reference defaults to false" do
      places = InstanceInfo.structure_places(Shelf)
      installation_site = Enum.find(places, &(&1.role == :installation_site))
      assert installation_site.reference == false
    end
  end

  describe "BasePlace — simple pattern (GeographicSite)" do
    test "create and read using only base attributes" do
      {:ok, site} = Nbn.create_geographic_site(%{id: "SITE-01", name: "Data Centre 1"})
      assert site.name == "Data Centre 1"
      assert site.type == :GeographicSite

      {:ok, loaded} = Nbn.get_geographic_site_by_id("SITE-01")
      assert loaded.name == "Data Centre 1"
    end
  end

  describe "BasePlace — complex pattern (ExchangeBuilding)" do
    test "domain-specific attributes are accepted and persisted" do
      {:ok, building} = Nbn.create_exchange_building(%{
        id: "EX-MEL-001",
        name: "Melbourne Central Exchange",
        nli: "MEXMELB0001",
        access_type: :unmanned
      })

      assert building.name == "Melbourne Central Exchange"
      assert building.type == :GeographicSite
      assert building.nli == "MEXMELB0001"
      assert building.access_type == :unmanned
    end

    test "domain-specific attributes are readable after creation" do
      {:ok, _building} = Nbn.create_exchange_building(%{
        id: "EX-MEL-002",
        name: "South Yarra Exchange",
        nli: "MEXMELB0002",
        access_type: :attended
      })

      {:ok, loaded} = Nbn.get_exchange_building_by_id("EX-MEL-002")
      assert loaded.nli == "MEXMELB0002"
      assert loaded.access_type == :attended
    end

    test "domain-specific attributes are nil when not provided" do
      {:ok, building} = Nbn.create_exchange_building(%{
        id: "EX-MEL-003",
        name: "Bare Exchange"
      })

      assert building.nli == nil
      assert building.access_type == nil
    end
  end
end
