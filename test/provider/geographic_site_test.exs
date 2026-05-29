# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.GeographicSiteTest do
  @moduledoc false
  use ExUnit.Case, async: true
  @moduletag :provider_only

  alias Diffo.Provider.GeographicAddress
  alias Diffo.Provider.GeographicSite

  setup do
    AshNeo4j.Sandbox.checkout()
    on_exit(&AshNeo4j.Sandbox.rollback/0)
  end

  describe "build" do
    test "creates a GeographicSite with site fields" do
      assert {:ok, site} =
               Ash.create(
                 GeographicSite,
                 %{
                   id: "SITE-CREATE-001",
                   name: "Sydney CBD Exchange",
                   site_type: :exchange,
                   site_code: "SYD-CBD-01"
                 },
                 action: :build,
                 domain: Diffo.Provider
               )

      assert site.id == "SITE-CREATE-001"
      assert site.type == :GeographicSite
      assert site.site_type == :exchange
      assert site.site_code == "SYD-CBD-01"
    end

    test "type is set automatically to :GeographicSite" do
      assert {:ok, site} =
               Ash.create(
                 GeographicSite,
                 %{id: "SITE-CREATE-002", name: "Type Auto"},
                 action: :build,
                 domain: Diffo.Provider
               )

      assert site.type == :GeographicSite
    end
  end

  describe "TMF wire shape" do
    test "encodes as JSON with TMF camelCase + @type" do
      site =
        Ash.create!(
          GeographicSite,
          %{
            id: "SITE-JSON-001",
            name: "JSON Site",
            site_type: :branch,
            site_code: "BR-100"
          },
          action: :build,
          domain: Diffo.Provider
        )

      json = Jason.encode!(site) |> Jason.decode!()

      assert json["@type"] == "GeographicSite"
      assert json["id"] == "SITE-JSON-001"
      assert json["name"] == "JSON Site"
      assert json["siteType"] == "branch"
      assert json["siteCode"] == "BR-100"
    end
  end

  describe "projected :address calculation" do
    test "returns nil when address_id is nil" do
      site =
        Ash.create!(
          GeographicSite,
          %{id: "SITE-ADDR-001", name: "No Address"},
          action: :build,
          domain: Diffo.Provider
        )

      site = Ash.load!(site, [:address], domain: Diffo.Provider)

      assert is_nil(site.address)
    end

    test "projects a Provider.GeographicAddress when address_id points at one" do
      address =
        Ash.create!(
          GeographicAddress,
          %{
            id: "ADDR-FOR-SITE-001",
            name: "Site Address",
            street_name: "George Street",
            street_nr: "1",
            country: "AU"
          },
          action: :build,
          domain: Diffo.Provider
        )

      site =
        Ash.create!(
          GeographicSite,
          %{
            id: "SITE-ADDR-002",
            name: "Sited at George Street",
            site_type: :office,
            address_id: address.id
          },
          action: :build,
          domain: Diffo.Provider
        )

      site = Ash.load!(site, [:address], domain: Diffo.Provider)

      assert %GeographicAddress{
               id: "ADDR-FOR-SITE-001",
               street_name: "George Street",
               street_nr: "1",
               country: "AU"
             } = site.address
    end

    test "emits %Diffo.Unknown{reason: :no_target} when address_id points nowhere" do
      site =
        Ash.create!(
          GeographicSite,
          %{
            id: "SITE-ADDR-003",
            name: "Pointing nowhere",
            address_id: "DOES-NOT-EXIST"
          },
          action: :build,
          domain: Diffo.Provider
        )

      site = Ash.load!(site, [:address], domain: Diffo.Provider)

      assert %Diffo.Unknown{
               world: Diffo.Provider.GeographicSite,
               reason: :no_target,
               context: %{
                 id_field: :address_id,
                 target_id: "DOES-NOT-EXIST",
                 reader: Diffo.Provider.Place
               }
             } = site.address
    end
  end

  describe "cross-world projection (the cascade pattern)" do
    test "AshNeo4j.worlds/1 resolves a GeographicSite node to its concrete leaf" do
      site =
        Ash.create!(
          GeographicSite,
          %{id: "SITE-WORLDS-001", name: "Worlds Test"},
          action: :build,
          domain: Diffo.Provider
        )

      [{domain, resource} | _] = AshNeo4j.worlds(site)

      assert domain == Diffo.Provider
      assert resource == Diffo.Provider.GeographicSite
    end
  end
end
