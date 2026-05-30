# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Extension.AssignerTest do
  @moduledoc false
  use ExUnit.Case, async: true
  @moduletag :domain_extended
  alias Diffo.Provider.Assigner
  alias Diffo.Provider.Specification
  alias Diffo.Provider.Characteristic
  alias Diffo.Provider.Assignment

  alias Diffo.Test.Parties
  alias Diffo.Test.Servo
  alias Diffo.Test.Instance.CardInstance

  setup do
    AshNeo4j.Sandbox.checkout()
    on_exit(&AshNeo4j.Sandbox.rollback/0)
  end

  # Issue #168 — broadened lifecycle policy. Service-side now covers the full
  # committed lifecycle (excludes :initial, :cancelled, :terminated); resource
  # side now allows :installing in addition to :operating.
  describe "assignable_state?/1 (#168)" do
    test "resource: :operating is permitted" do
      assert :ok = Assigner.assignable_state?(%{type: :resource, resource_state: :operating})
    end

    test "resource: :installing is permitted" do
      assert :ok = Assigner.assignable_state?(%{type: :resource, resource_state: :installing})
    end

    test "resource: :planning is rejected" do
      assert {:error, msg} =
               Assigner.assignable_state?(%{type: :resource, resource_state: :planning})

      assert msg =~ ":planning"
    end

    test "resource: :retiring is rejected" do
      assert {:error, _} =
               Assigner.assignable_state?(%{type: :resource, resource_state: :retiring})
    end

    test "service: committed lifecycle states are permitted" do
      for state <- [:feasibilityChecked, :reserved, :inactive, :active, :suspended] do
        assert :ok = Assigner.assignable_state?(%{type: :service, state: state}),
               "expected state #{inspect(state)} to be assignable"
      end
    end

    test "service: :initial is rejected" do
      assert {:error, msg} =
               Assigner.assignable_state?(%{type: :service, state: :initial})

      assert msg =~ ":initial"
    end

    test "service: terminal states are rejected" do
      for state <- [:cancelled, :terminated] do
        assert {:error, _} = Assigner.assignable_state?(%{type: :service, state: state}),
               "expected state #{inspect(state)} to be rejected"
      end
    end
  end

  describe "build card" do
    @tag :card
    test "create a card" do
      {:ok, card} = Servo.build_card(%{})

      assert is_struct(card, CardInstance)

      refute is_nil(card.specification_id)
      assert is_struct(card.specification, Specification)

      assert AshNeo4j.Neo4jHelper.nodes_relate_how?(
               :Instance,
               %{uuid: card.id},
               :Specification,
               %{uuid: card.specification_id},
               :SPECIFIED_BY,
               :outgoing
             )

      # both :card and :ports are now typed (BaseCharacteristic), not in dynamic characteristics
      assert is_list(card.characteristics)
      assert length(card.characteristics) == 0

      Enum.each(card.characteristics, fn characteristic ->
        assert is_struct(characteristic, Characteristic)

        assert AshNeo4j.Neo4jHelper.nodes_relate_how?(
                 :Instance,
                 %{uuid: card.id},
                 :Characteristic,
                 %{uuid: characteristic.id},
                 :HAS,
                 :outgoing
               )
      end)

      encoding = Jason.encode!(card) |> Diffo.Util.summarise_dates()

      assert encoding ==
               ~s({\"id\":\"#{card.id}",\"href\":\"resourceInventoryManagement/v4/resource/#{card.id}",\"category\":\"Network Resource\",\"description\":\"A Card Resource Instance\",\"resourceSpecification\":{\"id\":\"cd29956f-6c68-44cc-bf54-705eb8d2f754\",\"href\":\"resourceCatalogManagement/v4/resourceSpecification/cd29956f-6c68-44cc-bf54-705eb8d2f754\",\"name\":\"card\",\"version\":\"v1.0.0\"},\"resourceCharacteristic\":[{\"name\":\"card\",\"value\":{}},{\"name\":\"ports\",\"value\":{\"first\":1,\"last\":1,\"algorithm\":\"lowest\"}}]})
    end

    test "define card" do
      {:ok, card} = Servo.build_card(%{})

      updates = [
        card: [family: :ISAM, model: "EBLT48", technology: :adsl2Plus],
        ports: [first: 1, last: 48, assignable_type: "ADSL2+"]
      ]

      {:ok, card} = Servo.define_card(card, %{characteristic_value_updates: updates})

      {:ok, card_value} =
        Diffo.Test.Characteristic.CardCharacteristic
        |> Ash.Query.new()
        |> Ash.Query.filter_input(instance_id: card.id)
        |> Ash.read_one()

      assert card_value.family == :ISAM
      assert card_value.model == "EBLT48"
      assert card_value.technology == :adsl2Plus

      encoding = Jason.encode!(card) |> Diffo.Util.summarise_dates()

      assert encoding ==
               ~s({\"id\":\"#{card.id}",\"href\":\"resourceInventoryManagement/v4/resource/#{card.id}",\"category\":\"Network Resource\",\"description\":\"A Card Resource Instance\",\"resourceSpecification\":{\"id\":\"cd29956f-6c68-44cc-bf54-705eb8d2f754\",\"href\":\"resourceCatalogManagement/v4/resourceSpecification/cd29956f-6c68-44cc-bf54-705eb8d2f754\",\"name\":\"card\",\"version\":\"v1.0.0\"},\"resourceCharacteristic\":[{\"name\":\"card\",\"value\":{\"family\":\"ISAM\",\"model\":\"EBLT48\",\"technology\":\"adsl2Plus\"}},{\"name\":\"ports\",\"value\":{\"first\":1,\"last\":48,\"type\":\"ADSL2+\",\"algorithm\":\"lowest\"}}]})
    end

    test "auto assign port to resource" do
      {:ok, assignee} = Parties.build_shelf_with_installer()

      {:ok, card} = Servo.build_card(%{})

      updates = [
        card: [family: :ISAM, model: "EBLT48", technology: :adsl2Plus],
        ports: [first: 1, last: 48, assignable_type: "ADSL2+"]
      ]

      {:ok, card} = Servo.define_card(card, %{characteristic_value_updates: updates})
      {:ok, card} = Servo.lifecycle_card(card, %{resource_state: :operating})

      {:ok, card} =
        Servo.assign_port(card, %{
          assignment: %Assignment{assignee_id: assignee.id, operation: :auto_assign}
        })

      assert length(card.assignments) == 1

      encoding = Jason.encode!(card) |> Diffo.Util.summarise_dates()

      assert encoding ==
               ~s({\"id\":\"#{card.id}",\"href\":\"resourceInventoryManagement/v4/resource/#{card.id}",\"category\":\"Network Resource\",\"description\":\"A Card Resource Instance\",\"resourceSpecification\":{\"id\":\"cd29956f-6c68-44cc-bf54-705eb8d2f754\",\"href\":\"resourceCatalogManagement/v4/resourceSpecification/cd29956f-6c68-44cc-bf54-705eb8d2f754\",\"name\":\"card\",\"version\":\"v1.0.0\"},\"lifecycleState\":\"operating\",\"resourceRelationship\":[{\"type\":\"assignedTo\",\"resource\":{\"id\":\"#{assignee.id}\",\"href\":\"resourceInventoryManagement/v4/resource/#{assignee.id}\"},\"resourceRelationshipCharacteristic\":[{\"name\":\"port\",\"value\":1}]}],\"resourceCharacteristic\":[{\"name\":\"card\",\"value\":{\"family\":\"ISAM\",\"model\":\"EBLT48\",\"technology\":\"adsl2Plus\"}},{\"name\":\"ports\",\"value\":{\"first\":1,\"last\":48,\"type\":\"ADSL2+\",\"algorithm\":\"lowest\"}}]})
    end

    test "auto assign two ports to same resource" do
      {:ok, assignee} = Parties.build_shelf_with_installer()

      {:ok, card} = Servo.build_card(%{})

      updates = [
        card: [family: :ISAM, model: "EBLT48", technology: :adsl2Plus],
        ports: [first: 1, last: 48, assignable_type: "ADSL2+"]
      ]

      {:ok, card} = Servo.define_card(card, %{characteristic_value_updates: updates})
      {:ok, card} = Servo.lifecycle_card(card, %{resource_state: :operating})

      {:ok, card} =
        Servo.assign_port(card, %{
          assignment: %Assignment{assignee_id: assignee.id, operation: :auto_assign}
        })

      {:ok, card} =
        Servo.assign_port(card, %{
          assignment: %Assignment{assignee_id: assignee.id, operation: :auto_assign}
        })

      assert length(card.assignments) == 2

      encoding = Jason.encode!(card) |> Diffo.Util.summarise_dates()

      assert encoding ==
               ~s({\"id\":\"#{card.id}",\"href\":\"resourceInventoryManagement/v4/resource/#{card.id}",\"category\":\"Network Resource\",\"description\":\"A Card Resource Instance\",\"resourceSpecification\":{\"id\":\"cd29956f-6c68-44cc-bf54-705eb8d2f754\",\"href\":\"resourceCatalogManagement/v4/resourceSpecification/cd29956f-6c68-44cc-bf54-705eb8d2f754\",\"name\":\"card\",\"version\":\"v1.0.0\"},\"lifecycleState\":\"operating\",\"resourceRelationship\":[{\"type\":\"assignedTo\",\"resource\":{\"id\":\"#{assignee.id}\",\"href\":\"resourceInventoryManagement/v4/resource/#{assignee.id}\"},\"resourceRelationshipCharacteristic\":[{\"name\":\"port\",\"value\":1}]},{\"type\":\"assignedTo\",\"resource\":{\"id\":\"#{assignee.id}\",\"href\":\"resourceInventoryManagement/v4/resource/#{assignee.id}\"},\"resourceRelationshipCharacteristic\":[{\"name\":\"port\",\"value\":2}]}],\"resourceCharacteristic\":[{\"name\":\"card\",\"value\":{\"family\":\"ISAM\",\"model\":\"EBLT48\",\"technology\":\"adsl2Plus\"}},{\"name\":\"ports\",\"value\":{\"first\":1,\"last\":48,\"type\":\"ADSL2+\",\"algorithm\":\"lowest\"}}]})
    end

    test "specific assignment rejects duplicate request" do
      {:ok, assignee} = Parties.build_shelf_with_installer()

      {:ok, card} = Servo.build_card(%{})

      updates = [
        card: [family: :ISAM, model: "EBLT48", technology: :adsl2Plus],
        ports: [first: 1, last: 48, assignable_type: "ADSL2+"]
      ]

      {:ok, card} = Servo.define_card(card, %{characteristic_value_updates: updates})
      {:ok, card} = Servo.lifecycle_card(card, %{resource_state: :operating})

      {:ok, card} =
        Servo.assign_port(card, %{
          assignment: %Assignment{id: 5, assignee_id: assignee.id, operation: :assign}
        })

      {:error, _error} =
        Servo.assign_port(card, %{
          assignment: %Assignment{id: 5, assignee_id: assignee.id, operation: :assign}
        })

      assert length(card.assignments) == 1

      encoding = Jason.encode!(card) |> Diffo.Util.summarise_dates()

      assert encoding ==
               ~s({\"id\":\"#{card.id}",\"href\":\"resourceInventoryManagement/v4/resource/#{card.id}",\"category\":\"Network Resource\",\"description\":\"A Card Resource Instance\",\"resourceSpecification\":{\"id\":\"cd29956f-6c68-44cc-bf54-705eb8d2f754\",\"href\":\"resourceCatalogManagement/v4/resourceSpecification/cd29956f-6c68-44cc-bf54-705eb8d2f754\",\"name\":\"card\",\"version\":\"v1.0.0\"},\"lifecycleState\":\"operating\",\"resourceRelationship\":[{\"type\":\"assignedTo\",\"resource\":{\"id\":\"#{assignee.id}\",\"href\":\"resourceInventoryManagement/v4/resource/#{assignee.id}\"},\"resourceRelationshipCharacteristic\":[{\"name\":\"port\",\"value\":5}]}],\"resourceCharacteristic\":[{\"name\":\"card\",\"value\":{\"family\":\"ISAM\",\"model\":\"EBLT48\",\"technology\":\"adsl2Plus\"}},{\"name\":\"ports\",\"value\":{\"first\":1,\"last\":48,\"type\":\"ADSL2+\",\"algorithm\":\"lowest\"}}]})
    end

    test "unassign an auto-assigned port from a resource" do
      {:ok, assignee} = Parties.build_shelf_with_installer()

      {:ok, card} = Servo.build_card(%{})

      updates = [
        card: [family: :ISAM, model: "EBLT48", technology: :adsl2Plus],
        ports: [first: 1, last: 48, assignable_type: "ADSL2+"]
      ]

      {:ok, card} = Servo.define_card(card, %{characteristic_value_updates: updates})
      {:ok, card} = Servo.lifecycle_card(card, %{resource_state: :operating})

      {:ok, card} =
        Servo.assign_port(card, %{
          assignment: %Assignment{assignee_id: assignee.id, operation: :auto_assign}
        })

      assert length(card.assignments) == 1

      assigned_port = hd(card.assignments).value

      {:ok, card} =
        Servo.assign_port(card, %{
          assignment: %Assignment{
            id: assigned_port,
            assignee_id: assignee.id,
            operation: :unassign
          }
        })

      assert length(card.assignments) == 0

      encoding = Jason.encode!(card) |> Diffo.Util.summarise_dates()

      assert encoding ==
               ~s({\"id\":\"#{card.id}",\"href\":\"resourceInventoryManagement/v4/resource/#{card.id}",\"category\":\"Network Resource\",\"description\":\"A Card Resource Instance\",\"resourceSpecification\":{\"id\":\"cd29956f-6c68-44cc-bf54-705eb8d2f754\",\"href\":\"resourceCatalogManagement/v4/resourceSpecification/cd29956f-6c68-44cc-bf54-705eb8d2f754\",\"name\":\"card\",\"version\":\"v1.0.0\"},\"lifecycleState\":\"operating\",\"resourceCharacteristic\":[{\"name\":\"card\",\"value\":{\"family\":\"ISAM\",\"model\":\"EBLT48\",\"technology\":\"adsl2Plus\"}},{\"name\":\"ports\",\"value\":{\"first\":1,\"last\":48,\"type\":\"ADSL2+\",\"algorithm\":\"lowest\"}}]})
    end

    test "auto assign port to resource in :installing state (#168)" do
      {:ok, assignee} = Parties.build_shelf_with_installer()

      {:ok, card} = Servo.build_card(%{})

      updates = [
        card: [family: :ISAM, model: "EBLT48", technology: :adsl2Plus],
        ports: [first: 1, last: 48, assignable_type: "ADSL2+"]
      ]

      {:ok, card} = Servo.define_card(card, %{characteristic_value_updates: updates})
      {:ok, card} = Servo.lifecycle_card(card, %{resource_state: :installing})

      {:ok, card} =
        Servo.assign_port(card, %{
          assignment: %Assignment{assignee_id: assignee.id, operation: :auto_assign}
        })

      assert length(card.assignments) == 1
    end

    test "assign rejected while resource is in :planning state (#168)" do
      {:ok, assignee} = Parties.build_shelf_with_installer()

      {:ok, card} = Servo.build_card(%{})

      updates = [
        card: [family: :ISAM, model: "EBLT48", technology: :adsl2Plus],
        ports: [first: 1, last: 48, assignable_type: "ADSL2+"]
      ]

      {:ok, card} = Servo.define_card(card, %{characteristic_value_updates: updates})
      {:ok, card} = Servo.lifecycle_card(card, %{resource_state: :planning})

      assert {:error, _} =
               Servo.assign_port(card, %{
                 assignment: %Assignment{assignee_id: assignee.id, operation: :auto_assign}
               })
    end
  end
end
