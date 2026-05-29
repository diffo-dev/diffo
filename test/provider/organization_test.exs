# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.OrganizationTest do
  @moduledoc false
  use ExUnit.Case, async: true
  @moduletag :provider_only

  alias Diffo.Provider.Organization

  setup do
    AshNeo4j.Sandbox.checkout()
    on_exit(&AshNeo4j.Sandbox.rollback/0)
  end

  describe "build" do
    test "creates an Organization with the full organization attribute set" do
      assert {:ok, org} =
               Ash.create(
                 Organization,
                 %{
                   id: "ORG-CREATE-001",
                   name: "Acme Pty Ltd",
                   trading_name: "Acme",
                   name_type: "Pty Ltd",
                   organization_type: "company",
                   is_legal_entity: true,
                   is_head_office: true
                 },
                 action: :build,
                 domain: Diffo.Provider
               )

      assert org.id == "ORG-CREATE-001"
      assert org.type == :Organization
      assert org.trading_name == "Acme"
      assert org.name_type == "Pty Ltd"
      assert org.organization_type == "company"
      assert org.is_legal_entity == true
      assert org.is_head_office == true
    end

    test "type is set automatically to :Organization" do
      assert {:ok, org} =
               Ash.create(
                 Organization,
                 %{id: "ORG-CREATE-002", name: "Type Auto"},
                 action: :build,
                 domain: Diffo.Provider
               )

      assert org.type == :Organization
    end

    test "all organization fields are permissive (nillable)" do
      assert {:ok, org} =
               Ash.create(
                 Organization,
                 %{id: "ORG-CREATE-003", name: "Minimal"},
                 action: :build,
                 domain: Diffo.Provider
               )

      assert is_nil(org.trading_name)
      assert is_nil(org.organization_type)
      assert is_nil(org.is_legal_entity)
    end
  end

  describe "read" do
    test "loads a created Organization by id" do
      Ash.create!(
        Organization,
        %{
          id: "ORG-READ-001",
          name: "Read Test",
          trading_name: "ReadCo",
          organization_type: "company"
        },
        action: :build,
        domain: Diffo.Provider
      )

      assert {:ok, loaded} =
               Ash.get(Organization, "ORG-READ-001", domain: Diffo.Provider)

      assert loaded.trading_name == "ReadCo"
      assert loaded.organization_type == "company"
      assert loaded.type == :Organization
    end
  end

  describe "define" do
    test "updates organization-specific fields via :define action" do
      org =
        Ash.create!(
          Organization,
          %{
            id: "ORG-UPDATE-001",
            name: "Original",
            trading_name: "Old"
          },
          action: :build,
          domain: Diffo.Provider
        )

      assert {:ok, updated} =
               Ash.update(org, %{trading_name: "New", organization_type: "department"},
                 action: :define,
                 domain: Diffo.Provider
               )

      assert updated.trading_name == "New"
      assert updated.organization_type == "department"
    end
  end

  describe "TMF wire shape" do
    test "encodes as JSON with TMF camelCase + @type" do
      org =
        Ash.create!(
          Organization,
          %{
            id: "ORG-JSON-001",
            name: "JSON Co",
            trading_name: "JSONCo",
            name_type: "Pty Ltd",
            organization_type: "company",
            is_legal_entity: true,
            is_head_office: false
          },
          action: :build,
          domain: Diffo.Provider
        )

      json = Jason.encode!(org) |> Jason.decode!()

      assert json["@type"] == "Organization"
      assert json["id"] == "ORG-JSON-001"
      assert json["name"] == "JSON Co"
      assert json["tradingName"] == "JSONCo"
      assert json["nameType"] == "Pty Ltd"
      assert json["organizationType"] == "company"
      assert json["isLegalEntity"] == true
      assert json["isHeadOffice"] == false
    end

    test "compact removes nil fields from JSON output" do
      org =
        Ash.create!(
          Organization,
          %{id: "ORG-JSON-002", name: "Compact"},
          action: :build,
          domain: Diffo.Provider
        )

      json = Jason.encode!(org) |> Jason.decode!()

      refute Map.has_key?(json, "tradingName")
      refute Map.has_key?(json, "organizationType")
      refute Map.has_key?(json, "isLegalEntity")
    end
  end

  describe "cross-world projection (the cascade pattern)" do
    test "AshNeo4j.worlds/1 resolves an Organization node to its concrete leaf" do
      org =
        Ash.create!(
          Organization,
          %{id: "ORG-WORLDS-001", name: "Worlds"},
          action: :build,
          domain: Diffo.Provider
        )

      [{domain, resource} | _] = AshNeo4j.worlds(org)

      assert domain == Diffo.Provider
      assert resource == Diffo.Provider.Organization
    end
  end
end
