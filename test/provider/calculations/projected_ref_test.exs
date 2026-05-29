# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Calculations.ProjectedRefTest do
  @moduledoc false
  use ExUnit.Case, async: true
  @moduletag :provider_only

  alias Diffo.Provider.Calculations.ProjectedRef

  setup do
    AshNeo4j.Sandbox.checkout()
    on_exit(&AshNeo4j.Sandbox.rollback/0)
  end

  describe "nil id_field" do
    test "returns nil for nil id (legitimate absence, not Unknown)" do
      record = %Diffo.Provider.PlaceRef{place_id: nil}

      assert [nil] =
               ProjectedRef.calculate(
                 [record],
                 [id_field: :place_id, reader: Diffo.Provider.Place],
                 nil
               )
    end
  end

  describe "concrete projection" do
    test "projects an existing target to a concrete struct" do
      place =
        Diffo.Provider.create_place!(:GeographicSite, %{
          id: "PR-PROJECTED-001",
          name: "Test Projected Place"})

      record = %Diffo.Provider.PlaceRef{place_id: place.id}

      assert [%Diffo.Provider.GeographicSite{id: "PR-PROJECTED-001"}] =
               ProjectedRef.calculate(
                 [record],
                 [id_field: :place_id, reader: Diffo.Provider.Place],
                 nil
               )
    end

    test "projects multiple records in one batch" do
      place_a =
        Diffo.Provider.create_place!(:GeographicSite, %{
          id: "PR-PROJECTED-002",
          name: "A"})

      place_b =
        Diffo.Provider.create_place!(:GeographicSite, %{
          id: "PR-PROJECTED-003",
          name: "B"})

      records = [
        %Diffo.Provider.PlaceRef{place_id: place_a.id},
        %Diffo.Provider.PlaceRef{place_id: place_b.id},
        %Diffo.Provider.PlaceRef{place_id: nil}
      ]

      results =
        ProjectedRef.calculate(
          records,
          [id_field: :place_id, reader: Diffo.Provider.Place],
          nil
        )

      assert [
               %Diffo.Provider.GeographicSite{id: "PR-PROJECTED-002"},
               %Diffo.Provider.GeographicSite{id: "PR-PROJECTED-003"},
               nil
             ] = results
    end
  end

  describe "no_target — target id not in graph" do
    test "emits Unknown with reason :no_target and the calling world stamped" do
      record = %Diffo.Provider.PlaceRef{place_id: "DOES-NOT-EXIST-001"}

      assert [
               %Diffo.Unknown{
                 world: Diffo.Provider.PlaceRef,
                 reason: :no_target,
                 context: %{
                   id_field: :place_id,
                   target_id: "DOES-NOT-EXIST-001",
                   reader: Diffo.Provider.Place
                 }
               }
             ] =
               ProjectedRef.calculate(
                 [record],
                 [id_field: :place_id, reader: Diffo.Provider.Place],
                 nil
               )
    end
  end

  describe "missing required opts" do
    test "raises if id_field opt is missing" do
      assert_raise KeyError, fn ->
        ProjectedRef.calculate(
          [%Diffo.Provider.PlaceRef{}],
          [reader: Diffo.Provider.Place],
          nil
        )
      end
    end

    test "raises if reader opt is missing" do
      assert_raise KeyError, fn ->
        ProjectedRef.calculate(
          [%Diffo.Provider.PlaceRef{}],
          [id_field: :place_id],
          nil
        )
      end
    end
  end
end
