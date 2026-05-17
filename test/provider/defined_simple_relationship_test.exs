# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.DefinedSimpleRelationshipTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias Diffo.Type.NameValuePrimitive
  alias Diffo.Type.Primitive

  setup do
    AshNeo4j.Sandbox.checkout()
    on_exit(&AshNeo4j.Sandbox.rollback/0)
  end

  defp build_instances do
    spec_a = Diffo.Provider.create_specification!(%{name: "accessEvc"})
    spec_b = Diffo.Provider.create_specification!(%{name: "aggregationEvc"})
    source = Diffo.Provider.create_instance!(%{specified_by: spec_a.id, name: "access1"})
    target = Diffo.Provider.create_instance!(%{specified_by: spec_b.id, name: "agg1"})
    {source, target}
  end

  describe "DefinedSimpleRelationship create" do
    test "creates a relationship with no characteristic" do
      {source, target} = build_instances()

      rel =
        Diffo.Provider.create_defined_simple_relationship!(%{
          type: :assignedTo,
          source_id: source.id,
          target_id: target.id
        })

      assert rel.type == :assignedTo
      assert rel.source_id == source.id
      assert rel.target_id == target.id
      assert rel.characteristic == nil
    end

    test "creates a relationship with an integer characteristic" do
      {source, target} = build_instances()

      rel =
        Diffo.Provider.create_defined_simple_relationship!(%{
          type: :assignedTo,
          source_id: source.id,
          target_id: target.id,
          characteristic: %NameValuePrimitive{
            name: :slot,
            value: Primitive.wrap("integer", 7)
          }
        })

      assert rel.characteristic.name == :slot
      assert Diffo.Unwrap.unwrap(rel.characteristic.value) == 7
    end

    test "creates a relationship with a string characteristic" do
      {source, target} = build_instances()

      rel =
        Diffo.Provider.create_defined_simple_relationship!(%{
          type: :definedBy,
          source_id: source.id,
          target_id: target.id,
          characteristic: %NameValuePrimitive{
            name: :bandwidth,
            value: Primitive.wrap("string", "1000Mbps")
          }
        })

      assert rel.characteristic.name == :bandwidth
      assert Diffo.Unwrap.unwrap(rel.characteristic.value) == "1000Mbps"
    end

    test "characteristic is persisted and reloaded correctly" do
      {source, target} = build_instances()

      created =
        Diffo.Provider.create_defined_simple_relationship!(%{
          type: :assignedTo,
          source_id: source.id,
          target_id: target.id,
          characteristic: %NameValuePrimitive{
            name: :slot,
            value: Primitive.wrap("integer", 42)
          }
        })

      reloaded = Diffo.Provider.get_defined_simple_relationship_by_id!(created.id)

      assert reloaded.characteristic.name == :slot
      assert Diffo.Unwrap.unwrap(reloaded.characteristic.value) == 42
    end

    test "target_href and target_type are populated" do
      {source, target} = build_instances()

      rel =
        Diffo.Provider.create_defined_simple_relationship!(%{
          type: :assignedTo,
          source_id: source.id,
          target_id: target.id
        })

      assert rel.target_type == :service
      assert is_binary(rel.target_href)
    end
  end

  describe "DefinedSimpleRelationship read" do
    test "get by id returns the relationship" do
      {source, target} = build_instances()

      created =
        Diffo.Provider.create_defined_simple_relationship!(%{
          type: :assignedTo,
          source_id: source.id,
          target_id: target.id
        })

      fetched = Diffo.Provider.get_defined_simple_relationship_by_id!(created.id)
      assert fetched.id == created.id
      assert fetched.type == :assignedTo
    end
  end

  describe "DefinedSimpleRelationship destroy" do
    test "destroys the relationship" do
      {source, target} = build_instances()

      rel =
        Diffo.Provider.create_defined_simple_relationship!(%{
          type: :assignedTo,
          source_id: source.id,
          target_id: target.id
        })

      Diffo.Provider.delete_defined_simple_relationship!(rel)

      assert_raise Ash.Error.Invalid, fn ->
        Diffo.Provider.get_defined_simple_relationship_by_id!(rel.id)
      end
    end
  end

  describe "NameValuePrimitive TypedStruct" do
    test "new!/1 constructs with a Primitive value" do
      char = NameValuePrimitive.new!(name: :slot, value: Primitive.wrap("integer", 7))
      assert char.name == :slot
      assert Diffo.Unwrap.unwrap(char.value) == 7
    end

    test "new!/1 raises when name is nil" do
      assert_raise Ash.Error.Invalid, fn ->
        NameValuePrimitive.new!(name: nil, value: Primitive.wrap("string", "x"))
      end
    end

    test "Jason encoding produces name then unwrapped value" do
      char = NameValuePrimitive.new!(name: :slot, value: Primitive.wrap("integer", 7))
      json = Jason.encode!(char)
      assert json == ~s({"name":"slot","value":7})
    end
  end
end
