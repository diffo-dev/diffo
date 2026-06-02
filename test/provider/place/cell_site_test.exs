# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Test.Place.CellSiteTest do
  @moduledoc """
  Proves the spatial + link-budget calculations on a GeographicLocation leaf evaluate
  against the AshNeo4j sandbox: `distance_m` (a graph-native `st_distance_in_meters`
  expression) and the free-space `path_loss_db` / `rssi_dbm` link budget. Backs the
  `use_diffo_place_geo` livebook.
  """
  use ExUnit.Case, async: true
  @moduletag :domain_extended

  alias Diffo.Test.Nbn

  setup do
    AshNeo4j.Sandbox.checkout()
    on_exit(&AshNeo4j.Sandbox.rollback/0)
  end

  # Sydney CBD tower; Town Hall is ~513 m south-west.
  @tower_point %Geo.Point{coordinates: {151.2093, -33.8688}, srid: 4326}
  @town_hall %Geo.Point{coordinates: {151.2073, -33.8731}, srid: 4326}
  @frequency_mhz 3500.0

  defp build_tower(attrs \\ %{}) do
    Nbn.build_cell_site!(
      Map.merge(
        %{
          id: "CELL-SYD-1",
          name: "Sydney CBD Tower",
          location: @tower_point,
          technology: :FixedWireless,
          eirp_dbm: 60.0,
          frequency_mhz: @frequency_mhz
        },
        attrs
      )
    )
  end

  describe "distance_m — st_distance_in_meters expression" do
    test "computes the geodesic distance to the :at point" do
      tower = build_tower() |> Ash.load!([distance_m: %{at: @town_hall}], domain: Nbn)

      # ~513 m on Neo4j's WGS-84 model — assert within a metre.
      assert_in_delta tower.distance_m, 513.0, 1.0
    end

    test "distance to its own location is zero" do
      tower = build_tower() |> Ash.load!([distance_m: %{at: @tower_point}], domain: Nbn)
      assert_in_delta tower.distance_m, 0.0, 0.001
    end
  end

  describe "path_loss_db / rssi_dbm — free-space link budget" do
    test "free-space path loss matches Friis at the :at point" do
      tower =
        build_tower()
        |> Ash.load!([distance_m: %{at: @town_hall}, path_loss_db: %{at: @town_hall}],
          domain: Nbn
        )

      expected = 20 * :math.log10(tower.distance_m) + 20 * :math.log10(@frequency_mhz) - 27.55
      assert_in_delta tower.path_loss_db, expected, 0.2
    end

    test "rssi is eirp minus path loss (isotropic Rx)" do
      tower =
        build_tower()
        |> Ash.load!([path_loss_db: %{at: @town_hall}, rssi_dbm: %{at: @town_hall}], domain: Nbn)

      assert_in_delta tower.rssi_dbm, 60.0 - tower.path_loss_db, 0.2
    end

    test "+6 dB EIRP lifts RSSI by 6 dB at the same point" do
      base = build_tower() |> Ash.load!([rssi_dbm: %{at: @town_hall}], domain: Nbn)

      hotter =
        build_tower(%{id: "CELL-SYD-2", eirp_dbm: 66.0})
        |> Ash.load!([rssi_dbm: %{at: @town_hall}], domain: Nbn)

      assert_in_delta hotter.rssi_dbm, base.rssi_dbm + 6.0, 0.2
    end
  end

  describe "all calculations loaded together" do
    test "distance_m, path_loss_db and rssi_dbm load in one pass" do
      tower =
        build_tower()
        |> Ash.load!(
          [
            distance_m: %{at: @town_hall},
            path_loss_db: %{at: @town_hall},
            rssi_dbm: %{at: @town_hall}
          ],
          domain: Nbn
        )

      assert is_float(tower.distance_m)
      assert is_float(tower.path_loss_db)
      assert is_float(tower.rssi_dbm)
    end
  end

  describe "cross-world projection" do
    test "worlds/1 projects the CellSite node back to its concrete leaf" do
      # Node labels are [Nbn, CellSite, Place, Provider] — no GeographicLocation label
      # (subtype identity is the module + :type property); the :Provider label comes from
      # Nbn composing Diffo.Provider.DomainFragment. worlds/1 recovers the concrete
      # (domain, resource) by label-subset match.
      tower = build_tower()
      assert {Nbn, Diffo.Test.Place.CellSite} in AshNeo4j.worlds(tower)
    end

    test "Diffo.Provider.get_place_by_id! projects across domains via the :Provider label" do
      # The provider-side reader MATCHes [:Provider, :Place]; the :Provider label (from the
      # domain fragment) is what lets it find and project a leaf in another domain.
      tower = build_tower()

      assert %Diffo.Test.Place.CellSite{type: :GeographicLocation} =
               Diffo.Provider.get_place_by_id!(tower.id)
    end
  end
end
