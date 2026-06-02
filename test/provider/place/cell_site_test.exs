# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Test.Place.CellSiteTest do
  @moduledoc """
  Proves the graph-native spatial **expression calculations** on a GeographicLocation leaf
  evaluate against the AshNeo4j sandbox — `distance_m` and `signal_strength`, both built on
  AshNeo4j's `st_distance_in_meters`. Backs the `use_diffo_place_geo` livebook.
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

  defp build_tower(attrs \\ %{}) do
    Nbn.build_cell_site!(
      Map.merge(
        %{
          id: "CELL-SYD-1",
          name: "Sydney CBD Tower",
          location: @tower_point,
          technology: :FixedWireless,
          transmit_power: 40.0
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

  describe "signal_strength — power flux density from EIRP and distance" do
    test "computes transmit_power / (4·π·d²) at the :at point" do
      tower = build_tower() |> Ash.load!([signal_strength: %{at: @town_hall}], domain: Nbn)

      # S = 40 W / (4π · 513²) ≈ 1.21e-5 W/m²
      expected = 40.0 / (4 * :math.pi() * 513.0 * 513.0)
      assert_in_delta tower.signal_strength, expected, 1.0e-7
    end

    test "halving transmit power halves the signal strength at the same point" do
      full = build_tower() |> Ash.load!([signal_strength: %{at: @town_hall}], domain: Nbn)

      half =
        build_tower(%{id: "CELL-SYD-2", transmit_power: 20.0})
        |> Ash.load!([signal_strength: %{at: @town_hall}], domain: Nbn)

      assert_in_delta half.signal_strength, full.signal_strength / 2, 1.0e-9
    end
  end

  describe "both calculations loaded together" do
    test "distance_m and signal_strength load in one pass" do
      tower =
        build_tower()
        |> Ash.load!([distance_m: %{at: @town_hall}, signal_strength: %{at: @town_hall}],
          domain: Nbn
        )

      assert is_float(tower.distance_m)
      assert is_float(tower.signal_strength)
    end
  end
end
