# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.GeographicAddressTest do
  @moduledoc false
  use ExUnit.Case, async: true
  @moduletag :provider_only

  alias Diffo.Provider.GeographicAddress

  setup do
    AshNeo4j.Sandbox.checkout()
    on_exit(&AshNeo4j.Sandbox.rollback/0)
  end

  describe "build" do
    test "creates a GeographicAddress with the full address attribute set" do
      assert {:ok, address} =
               Ash.create(
                 GeographicAddress,
                 %{
                   id: "ADDR-CREATE-001",
                   name: "Sydney HQ",
                   street_name: "George Street",
                   street_nr: "1",
                   locality: "Sydney",
                   state_or_province: "NSW",
                   country: "AU",
                   postcode: "2000"
                 },
                 action: :build,
                 domain: Diffo.Provider
               )

      assert address.id == "ADDR-CREATE-001"
      assert address.type == :GeographicAddress
      assert address.street_name == "George Street"
      assert address.street_nr == "1"
      assert address.locality == "Sydney"
      assert address.state_or_province == "NSW"
      assert address.country == "AU"
      assert address.postcode == "2000"
    end

    test "type is set automatically to :GeographicAddress" do
      assert {:ok, address} =
               Ash.create(
                 GeographicAddress,
                 %{id: "ADDR-CREATE-002", name: "Type Auto"},
                 action: :build,
                 domain: Diffo.Provider
               )

      assert address.type == :GeographicAddress
    end

    test "all address fields are permissive (nillable)" do
      assert {:ok, address} =
               Ash.create(
                 GeographicAddress,
                 %{id: "ADDR-CREATE-003", name: "Minimal"},
                 action: :build,
                 domain: Diffo.Provider
               )

      assert is_nil(address.street_name)
      assert is_nil(address.country)
    end
  end

  describe "read" do
    test "loads a created GeographicAddress by id" do
      Ash.create!(
        GeographicAddress,
        %{
          id: "ADDR-READ-001",
          name: "Read Test",
          street_name: "Pitt Street",
          country: "AU"
        },
        action: :build,
        domain: Diffo.Provider
      )

      assert {:ok, loaded} =
               Ash.get(GeographicAddress, "ADDR-READ-001", domain: Diffo.Provider)

      assert loaded.street_name == "Pitt Street"
      assert loaded.country == "AU"
      assert loaded.type == :GeographicAddress
    end
  end

  describe "define" do
    test "updates address-specific fields via :define action" do
      address =
        Ash.create!(
          GeographicAddress,
          %{
            id: "ADDR-UPDATE-001",
            name: "Original",
            postcode: "2000"
          },
          action: :build,
          domain: Diffo.Provider
        )

      assert {:ok, updated} =
               Ash.update(address, %{postcode: "3000", locality: "Melbourne"},
                 action: :define,
                 domain: Diffo.Provider
               )

      assert updated.postcode == "3000"
      assert updated.locality == "Melbourne"
    end
  end

  describe "TMF wire shape" do
    test "encodes as JSON with TMF camelCase + @type" do
      address =
        Ash.create!(
          GeographicAddress,
          %{
            id: "ADDR-JSON-001",
            name: "JSON Test",
            street_name: "Collins Street",
            street_nr: "100",
            state_or_province: "VIC",
            country: "AU",
            postcode: "3000"
          },
          action: :build,
          domain: Diffo.Provider
        )

      json = Jason.encode!(address) |> Jason.decode!()

      assert json["@type"] == "GeographicAddress"
      assert json["id"] == "ADDR-JSON-001"
      assert json["name"] == "JSON Test"
      assert json["streetName"] == "Collins Street"
      assert json["streetNr"] == "100"
      assert json["stateOrProvince"] == "VIC"
      assert json["country"] == "AU"
      assert json["postcode"] == "3000"
    end

    test "compact removes nil fields from JSON output" do
      address =
        Ash.create!(
          GeographicAddress,
          %{id: "ADDR-JSON-002", name: "Compact Test", country: "AU"},
          action: :build,
          domain: Diffo.Provider
        )

      json = Jason.encode!(address) |> Jason.decode!()

      refute Map.has_key?(json, "streetName")
      refute Map.has_key?(json, "postcode")
      refute Map.has_key?(json, "locality")
      assert json["country"] == "AU"
    end
  end

  describe "cross-world projection (the cascade pattern)" do
    test "AshNeo4j.worlds/1 resolves a GeographicAddress node to its concrete leaf" do
      address =
        Ash.create!(
          GeographicAddress,
          %{id: "ADDR-WORLDS-001", name: "Worlds Test"},
          action: :build,
          domain: Diffo.Provider
        )

      [{domain, resource} | _] = AshNeo4j.worlds(address)

      assert domain == Diffo.Provider
      assert resource == Diffo.Provider.GeographicAddress
    end
  end
end
