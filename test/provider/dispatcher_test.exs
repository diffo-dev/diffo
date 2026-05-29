# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.DispatcherTest do
  @moduledoc """
  Tests for the Place dispatcher API on `Diffo.Provider`.

  Covers the two patterns from #185:

    * **Type-atom dispatcher** — `create_place!/2` routes on TMF type atom to
      the concrete subtype's `:build` action. `update_place!/2` and
      `delete_place!/1` route on the record's struct module.
    * **Inline read projection** — `get_place_by_id!/1`, `list_places!/0`,
      `find_places_by_*` load via `Provider.Place` then project to the
      outermost concrete world via `AshNeo4j.worlds/1`.
  """
  use ExUnit.Case, async: true
  @moduletag :provider_only

  setup do
    AshNeo4j.Sandbox.checkout()
    on_exit(&AshNeo4j.Sandbox.rollback/0)
  end

  describe "create_place!/2 — type-atom dispatch" do
    test "creates a GeographicAddress" do
      address =
        Diffo.Provider.create_place!(:GeographicAddress, %{
          id: "DISP-ADDR-001",
          name: "Dispatch Address",
          street_name: "George Street",
          country: "AU"
        })

      assert %Diffo.Provider.GeographicAddress{
               id: "DISP-ADDR-001",
               type: :GeographicAddress,
               street_name: "George Street",
               country: "AU"
             } = address
    end

    test "creates a GeographicSite" do
      site =
        Diffo.Provider.create_place!(:GeographicSite, %{
          id: "DISP-SITE-001",
          name: "Dispatch Site",
          site_type: :exchange
        })

      assert %Diffo.Provider.GeographicSite{
               id: "DISP-SITE-001",
               type: :GeographicSite,
               site_type: :exchange
             } = site
    end

    test "creates a GeographicLocation" do
      location =
        Diffo.Provider.create_place!(:GeographicLocation, %{
          id: "DISP-LOC-001",
          name: "Dispatch Location",
          location: %Geo.Point{coordinates: {151.0, -33.0}, srid: 4326}
        })

      assert %Diffo.Provider.GeographicLocation{
               id: "DISP-LOC-001",
               type: :GeographicLocation
             } = location

      assert %Geo.Point{coordinates: {151.0, -33.0}} = location.location
    end

    test "raises ArgumentError for unknown TMF types" do
      assert_raise ArgumentError, ~r/unknown TMF Place type: :LunarBase/, fn ->
        Diffo.Provider.create_place!(:LunarBase, %{id: "X", name: "Y"})
      end
    end
  end

  describe "update_place!/2 — struct dispatch" do
    test "updates a GeographicAddress via its :define action" do
      address =
        Diffo.Provider.create_place!(:GeographicAddress, %{
          id: "DISP-UPD-001",
          name: "Update Test",
          postcode: "2000"
        })

      updated = Diffo.Provider.update_place!(address, %{postcode: "3000"})

      assert updated.postcode == "3000"
    end

    test "updates a GeographicSite via its :define action" do
      site =
        Diffo.Provider.create_place!(:GeographicSite, %{
          id: "DISP-UPD-002",
          name: "Update Site",
          site_code: "OLD-01"
        })

      updated = Diffo.Provider.update_place!(site, %{site_code: "NEW-02"})

      assert updated.site_code == "NEW-02"
    end
  end

  describe "delete_place!/1" do
    test "deletes a GeographicAddress" do
      address =
        Diffo.Provider.create_place!(:GeographicAddress, %{
          id: "DISP-DEL-001",
          name: "Delete Me"
        })

      assert :ok = Diffo.Provider.delete_place!(address)
      assert_raise Ash.Error.Invalid, fn -> Diffo.Provider.get_place_by_id!("DISP-DEL-001") end
    end
  end

  describe "get_place_by_id!/1 — inline projection" do
    test "returns the concrete subtype struct for a GeographicSite" do
      Diffo.Provider.create_place!(:GeographicSite, %{
        id: "DISP-PROJ-001",
        name: "Projected Site",
        site_type: :office
      })

      result = Diffo.Provider.get_place_by_id!("DISP-PROJ-001")

      assert %Diffo.Provider.GeographicSite{
               id: "DISP-PROJ-001",
               site_type: :office
             } = result
    end

    test "returns the concrete subtype struct for a GeographicAddress" do
      Diffo.Provider.create_place!(:GeographicAddress, %{
        id: "DISP-PROJ-002",
        name: "Projected Address",
        country: "AU"
      })

      result = Diffo.Provider.get_place_by_id!("DISP-PROJ-002")

      assert %Diffo.Provider.GeographicAddress{
               id: "DISP-PROJ-002",
               country: "AU"
             } = result
    end
  end

  describe "list_places!/0 — projection across mixed subtypes" do
    test "returns each Place projected to its concrete subtype" do
      Diffo.Provider.create_place!(:GeographicAddress, %{
        id: "LIST-ADDR-001",
        name: "Listed Address"
      })

      Diffo.Provider.create_place!(:GeographicSite, %{
        id: "LIST-SITE-001",
        name: "Listed Site"
      })

      places = Diffo.Provider.list_places!()

      ids = Enum.map(places, & &1.id) |> Enum.sort()
      assert "LIST-ADDR-001" in ids
      assert "LIST-SITE-001" in ids

      address = Enum.find(places, &(&1.id == "LIST-ADDR-001"))
      site = Enum.find(places, &(&1.id == "LIST-SITE-001"))

      assert is_struct(address, Diffo.Provider.GeographicAddress)
      assert is_struct(site, Diffo.Provider.GeographicSite)
    end
  end
end
