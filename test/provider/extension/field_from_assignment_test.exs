# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Extension.FieldFromAssignmentTest do
  @moduledoc false
  use ExUnit.Case, async: true
  @moduletag :domain_extended

  alias Diffo.Provider.Assignment
  alias Diffo.Test.Servo

  setup do
    AshNeo4j.Sandbox.checkout()
    on_exit(&AshNeo4j.Sandbox.rollback/0)
  end

  defp setup_card do
    updates = [
      card: [family: :ISAM, model: "EBLT48", technology: :adsl2Plus],
      ports: [first: 1, last: 48, assignable_type: "ADSL2+"]
    ]

    {:ok, card} = Servo.build_card(%{})
    {:ok, card} = Servo.define_card(card, %{characteristic_value_updates: updates})
    {:ok, card} = Servo.lifecycle_card(card, %{lifecycle_state: :installed})
    card
  end

  describe "FieldFromAssignment — aliased" do
    test "returns field value from the aliased assignment record" do
      card = setup_card()
      {:ok, service} = Servo.build_access_service(%{})

      {:ok, _card} =
        Servo.assign_port(card, %{
          assignment: %Assignment{
            assignee_id: service.id,
            operation: :auto_assign,
            alias: :primary
          }
        })

      service = Ash.load!(service, [:assigned_port], domain: Servo)

      assert length(service.assigned_port) == 1
      assert hd(service.assigned_port) == 1
    end

    test "returns empty list when no assignment exists" do
      {:ok, service} = Servo.build_access_service(%{})

      service = Ash.load!(service, [:assigned_port], domain: Servo)

      assert service.assigned_port == []
    end

    test "alias filters to only the matching assignment record" do
      card_a = setup_card()
      card_b = setup_card()
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

      service = Ash.load!(service, [:assigned_port], domain: Servo)

      assert length(service.assigned_port) == 1
    end
  end

  describe "FieldFromAssignment — unaliased (all assignments)" do
    test "returns field values from all assignment records" do
      card_a = setup_card()
      card_b = setup_card()
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

      service = Ash.load!(service, [:all_assignment_values], domain: Servo)

      assert length(service.all_assignment_values) == 2
    end

    test "returns empty list when no assignments exist" do
      {:ok, service} = Servo.build_access_service(%{})

      service = Ash.load!(service, [:all_assignment_values], domain: Servo)

      assert service.all_assignment_values == []
    end
  end
end
