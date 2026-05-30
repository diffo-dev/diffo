# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Extension.FieldViaAssignedRelationshipTest do
  @moduledoc false
  use ExUnit.Case, async: true
  @moduletag :domain_extended

  alias Diffo.Provider.Assignment
  alias Diffo.Test.Servo

  setup do
    AshNeo4j.Sandbox.checkout()
    on_exit(&AshNeo4j.Sandbox.rollback/0)
  end

  defp setup_card(name) do
    updates = [
      card: [family: :ISAM, model: "EBLT48", technology: :adsl2Plus],
      ports: [first: 1, last: 48, assignable_type: "ADSL2+"]
    ]

    {:ok, card} = Servo.build_card(%{name: name})
    {:ok, card} = Servo.define_card(card, %{characteristic_value_updates: updates})
    {:ok, card} = Servo.lifecycle_card(card, %{lifecycle_state: :installed})
    card
  end

  describe "FieldViaAssignedRelationship — aliased via" do
    test "returns field from source instance reached via alias" do
      card = setup_card("cvc-01")
      {:ok, service} = Servo.build_access_service(%{})

      {:ok, _card} =
        Servo.assign_port(card, %{
          assignment: %Assignment{
            assignee_id: service.id,
            operation: :auto_assign,
            alias: :primary
          }
        })

      service = Ash.load!(service, [:assigner_name], domain: Servo)

      assert service.assigner_name == ["cvc-01"]
    end

    test "returns empty list when no assignment exists" do
      {:ok, service} = Servo.build_access_service(%{})

      service = Ash.load!(service, [:assigner_name], domain: Servo)

      assert service.assigner_name == []
    end

    test "alias filters to only the matching source" do
      card_a = setup_card("cvc-01")
      card_b = setup_card("cvc-02")
      {:ok, service} = Servo.build_access_service(%{})

      {:ok, _card_a} =
        Servo.assign_port(card_a, %{
          assignment: %Assignment{
            assignee_id: service.id,
            operation: :auto_assign,
            alias: :primary
          }
        })

      {:ok, _card_b} =
        Servo.assign_port(card_b, %{
          assignment: %Assignment{
            assignee_id: service.id,
            operation: :auto_assign,
            alias: :secondary
          }
        })

      service = Ash.load!(service, [:assigner_name], domain: Servo)

      assert service.assigner_name == ["cvc-01"]
    end
  end

  describe "FieldViaAssignedRelationship — unaliased (all assigners)" do
    test "returns fields from all source instances regardless of alias" do
      card_a = setup_card("cvc-01")
      card_b = setup_card("cvc-02")
      {:ok, service} = Servo.build_access_service(%{})

      {:ok, _card_a} =
        Servo.assign_port(card_a, %{
          assignment: %Assignment{
            assignee_id: service.id,
            operation: :auto_assign,
            alias: :primary
          }
        })

      {:ok, _card_b} =
        Servo.assign_port(card_b, %{
          assignment: %Assignment{
            assignee_id: service.id,
            operation: :auto_assign,
            alias: :secondary
          }
        })

      service = Ash.load!(service, [:assigner_names], domain: Servo)

      assert Enum.sort(service.assigner_names) == ["cvc-01", "cvc-02"]
    end

    test "returns empty list when no assignments exist" do
      {:ok, service} = Servo.build_access_service(%{})

      service = Ash.load!(service, [:assigner_names], domain: Servo)

      assert service.assigner_names == []
    end
  end
end
