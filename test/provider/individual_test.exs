# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.IndividualTest do
  @moduledoc false
  use ExUnit.Case, async: true
  @moduletag :provider_only

  alias Diffo.Provider.Individual

  setup do
    AshNeo4j.Sandbox.checkout()
    on_exit(&AshNeo4j.Sandbox.rollback/0)
  end

  describe "build" do
    test "creates an Individual with the full individual attribute set" do
      assert {:ok, indiv} =
               Ash.create(
                 Individual,
                 %{
                   id: "IND-CREATE-001",
                   name: "Jane Q. Doe",
                   given_name: "Jane",
                   family_name: "Doe",
                   middle_name: "Q.",
                   title: "Dr",
                   gender: "female",
                   nationality: "AU"
                 },
                 action: :build,
                 domain: Diffo.Provider
               )

      assert indiv.id == "IND-CREATE-001"
      assert indiv.type == :Individual
      assert indiv.given_name == "Jane"
      assert indiv.family_name == "Doe"
      assert indiv.middle_name == "Q."
      assert indiv.title == "Dr"
      assert indiv.gender == "female"
      assert indiv.nationality == "AU"
    end

    test "type is set automatically to :Individual" do
      assert {:ok, indiv} =
               Ash.create(
                 Individual,
                 %{id: "IND-CREATE-002", name: "Type Auto"},
                 action: :build,
                 domain: Diffo.Provider
               )

      assert indiv.type == :Individual
    end

    test "all individual fields are permissive (nillable)" do
      assert {:ok, indiv} =
               Ash.create(
                 Individual,
                 %{id: "IND-CREATE-003", name: "Minimal"},
                 action: :build,
                 domain: Diffo.Provider
               )

      assert is_nil(indiv.given_name)
      assert is_nil(indiv.family_name)
      assert is_nil(indiv.nationality)
    end
  end

  describe "read" do
    test "loads a created Individual by id" do
      Ash.create!(
        Individual,
        %{
          id: "IND-READ-001",
          name: "Read Test",
          given_name: "Read",
          family_name: "Test"
        },
        action: :build,
        domain: Diffo.Provider
      )

      assert {:ok, loaded} =
               Ash.get(Individual, "IND-READ-001", domain: Diffo.Provider)

      assert loaded.given_name == "Read"
      assert loaded.family_name == "Test"
      assert loaded.type == :Individual
    end
  end

  describe "define" do
    test "updates individual-specific fields via :define action" do
      indiv =
        Ash.create!(
          Individual,
          %{
            id: "IND-UPDATE-001",
            name: "Original",
            given_name: "Old"
          },
          action: :build,
          domain: Diffo.Provider
        )

      assert {:ok, updated} =
               Ash.update(indiv, %{given_name: "New", title: "Pr"},
                 action: :define,
                 domain: Diffo.Provider
               )

      assert updated.given_name == "New"
      assert updated.title == "Pr"
    end
  end

  describe "TMF wire shape" do
    test "encodes as JSON with TMF camelCase + @type" do
      indiv =
        Ash.create!(
          Individual,
          %{
            id: "IND-JSON-001",
            name: "Jane Doe",
            given_name: "Jane",
            family_name: "Doe",
            middle_name: "Q.",
            title: "Dr",
            gender: "female",
            nationality: "AU"
          },
          action: :build,
          domain: Diffo.Provider
        )

      json = Jason.encode!(indiv) |> Jason.decode!()

      assert json["@type"] == "Individual"
      assert json["id"] == "IND-JSON-001"
      assert json["name"] == "Jane Doe"
      assert json["givenName"] == "Jane"
      assert json["familyName"] == "Doe"
      assert json["middleName"] == "Q."
      assert json["title"] == "Dr"
      assert json["gender"] == "female"
      assert json["nationality"] == "AU"
    end

    test "compact removes nil fields from JSON output" do
      indiv =
        Ash.create!(
          Individual,
          %{id: "IND-JSON-002", name: "Compact"},
          action: :build,
          domain: Diffo.Provider
        )

      json = Jason.encode!(indiv) |> Jason.decode!()

      refute Map.has_key?(json, "givenName")
      refute Map.has_key?(json, "familyName")
      refute Map.has_key?(json, "nationality")
    end
  end

  describe "cross-world projection (the cascade pattern)" do
    test "AshNeo4j.worlds/1 resolves an Individual node to its concrete leaf" do
      indiv =
        Ash.create!(
          Individual,
          %{id: "IND-WORLDS-001", name: "Worlds"},
          action: :build,
          domain: Diffo.Provider
        )

      [{domain, resource} | _] = AshNeo4j.worlds(indiv)

      assert domain == Diffo.Provider
      assert resource == Diffo.Provider.Individual
    end
  end
end
