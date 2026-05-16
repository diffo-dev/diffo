# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Extension.AssignerTest do
  @moduledoc false
  use ExUnit.Case, async: true
  alias Diffo.Provider.Specification
  alias Diffo.Provider.Characteristic
  alias Diffo.Provider.Assignment

  alias Diffo.Test.Parties
  alias Diffo.Test.Servo
  alias Diffo.Test.Instance.Card

  setup do
    AshNeo4j.Sandbox.checkout()
    on_exit(&AshNeo4j.Sandbox.rollback/0)
  end

  describe "build card" do
    @tag :card
    test "create a card" do
      {:ok, card} = Servo.build_card(%{})

      assert is_struct(card, Card)

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
               ~s({\"id\":\"#{card.id}",\"href\":\"resourceInventoryManagement/v4/resource/#{card.id}",\"category\":\"Network Resource\",\"description\":\"A Card Resource Instance\",\"resourceSpecification\":{\"id\":\"cd29956f-6c68-44cc-bf54-705eb8d2f754\",\"href\":\"resourceCatalogManagement/v4/resourceSpecification/cd29956f-6c68-44cc-bf54-705eb8d2f754\",\"name\":\"card\",\"version\":\"v1.0.0\"}})
    end

    test "define card" do
      {:ok, card} = Servo.build_card(%{})

      updates = [
        card: [family: :ISAM, model: "EBLT48", technology: :adsl2Plus],
        ports: [first: 1, last: 48, assignable_type: "ADSL2+"]
      ]

      {:ok, card} = Servo.define_card(card, %{characteristic_value_updates: updates})

      {:ok, card_value} =
        Diffo.Test.Characteristic.Card
        |> Ash.Query.new()
        |> Ash.Query.filter_input(instance_id: card.id)
        |> Ash.read_one()

      assert card_value.family == :ISAM
      assert card_value.model == "EBLT48"
      assert card_value.technology == :adsl2Plus

      encoding = Jason.encode!(card) |> Diffo.Util.summarise_dates()

      assert encoding ==
               ~s({\"id\":\"#{card.id}",\"href\":\"resourceInventoryManagement/v4/resource/#{card.id}",\"category\":\"Network Resource\",\"description\":\"A Card Resource Instance\",\"resourceSpecification\":{\"id\":\"cd29956f-6c68-44cc-bf54-705eb8d2f754\",\"href\":\"resourceCatalogManagement/v4/resourceSpecification/cd29956f-6c68-44cc-bf54-705eb8d2f754\",\"name\":\"card\",\"version\":\"v1.0.0\"}})
    end

    test "auto assign port to resource" do
      {:ok, assignee} = Parties.build_shelf_with_installer()

      {:ok, card} = Servo.build_card(%{})

      updates = [
        card: [family: :ISAM, model: "EBLT48", technology: :adsl2Plus],
        ports: [first: 1, last: 48, assignable_type: "ADSL2+"]
      ]

      {:ok, card} = Servo.define_card(card, %{characteristic_value_updates: updates})

      {:ok, card} =
        Servo.assign_port(card, %{
          assignment: %Assignment{assignee_id: assignee.id, operation: :auto_assign}
        })

      assigned_rels = Enum.filter(card.forward_relationships, fn rel -> rel.type == :assignedTo end)
      assert length(assigned_rels) == 1

      encoding = Jason.encode!(card) |> Diffo.Util.summarise_dates()

      assert encoding ==
               ~s({\"id\":\"#{card.id}",\"href\":\"resourceInventoryManagement/v4/resource/#{card.id}",\"category\":\"Network Resource\",\"description\":\"A Card Resource Instance\",\"resourceSpecification\":{\"id\":\"cd29956f-6c68-44cc-bf54-705eb8d2f754\",\"href\":\"resourceCatalogManagement/v4/resourceSpecification/cd29956f-6c68-44cc-bf54-705eb8d2f754\",\"name\":\"card\",\"version\":\"v1.0.0\"},\"resourceRelationship\":[{\"type\":\"assignedTo\",\"resource\":{\"id\":\"#{assignee.id}\",\"href\":\"resourceInventoryManagement/v4/resource/#{assignee.id}\"},\"resourceRelationshipCharacteristic\":[{\"name\":\"port\",\"value\":1}]}]})
    end

    test "auto assign two ports to same resource" do
      {:ok, assignee} = Parties.build_shelf_with_installer()

      {:ok, card} = Servo.build_card(%{})

      updates = [
        card: [family: :ISAM, model: "EBLT48", technology: :adsl2Plus],
        ports: [first: 1, last: 48, assignable_type: "ADSL2+"]
      ]

      {:ok, card} = Servo.define_card(card, %{characteristic_value_updates: updates})

      {:ok, card} =
        Servo.assign_port(card, %{
          assignment: %Assignment{assignee_id: assignee.id, operation: :auto_assign}
        })

      {:ok, card} =
        Servo.assign_port(card, %{
          assignment: %Assignment{assignee_id: assignee.id, operation: :auto_assign}
        })

      assigned_rels = Enum.filter(card.forward_relationships, fn rel -> rel.type == :assignedTo end)
      assert length(assigned_rels) == 2

      encoding = Jason.encode!(card) |> Diffo.Util.summarise_dates()

      assert encoding ==
               ~s({\"id\":\"#{card.id}",\"href\":\"resourceInventoryManagement/v4/resource/#{card.id}",\"category\":\"Network Resource\",\"description\":\"A Card Resource Instance\",\"resourceSpecification\":{\"id\":\"cd29956f-6c68-44cc-bf54-705eb8d2f754\",\"href\":\"resourceCatalogManagement/v4/resourceSpecification/cd29956f-6c68-44cc-bf54-705eb8d2f754\",\"name\":\"card\",\"version\":\"v1.0.0\"},\"resourceRelationship\":[{\"type\":\"assignedTo\",\"resource\":{\"id\":\"#{assignee.id}\",\"href\":\"resourceInventoryManagement/v4/resource/#{assignee.id}\"},\"resourceRelationshipCharacteristic\":[{\"name\":\"port\",\"value\":1}]},{\"type\":\"assignedTo\",\"resource\":{\"id\":\"#{assignee.id}\",\"href\":\"resourceInventoryManagement/v4/resource/#{assignee.id}\"},\"resourceRelationshipCharacteristic\":[{\"name\":\"port\",\"value\":2}]}]})
    end

    test "specific assignment rejects duplicate request" do
      {:ok, assignee} = Parties.build_shelf_with_installer()

      {:ok, card} = Servo.build_card(%{})

      updates = [
        card: [family: :ISAM, model: "EBLT48", technology: :adsl2Plus],
        ports: [first: 1, last: 48, assignable_type: "ADSL2+"]
      ]

      {:ok, card} = Servo.define_card(card, %{characteristic_value_updates: updates})

      {:ok, card} =
        Servo.assign_port(card, %{
          assignment: %Assignment{id: 5, assignee_id: assignee.id, operation: :assign}
        })

      {:error, _error} =
        Servo.assign_port(card, %{
          assignment: %Assignment{id: 5, assignee_id: assignee.id, operation: :assign}
        })

      assigned_rels = Enum.filter(card.forward_relationships, fn rel -> rel.type == :assignedTo end)
      assert length(assigned_rels) == 1

      encoding = Jason.encode!(card) |> Diffo.Util.summarise_dates()

      assert encoding ==
               ~s({\"id\":\"#{card.id}",\"href\":\"resourceInventoryManagement/v4/resource/#{card.id}",\"category\":\"Network Resource\",\"description\":\"A Card Resource Instance\",\"resourceSpecification\":{\"id\":\"cd29956f-6c68-44cc-bf54-705eb8d2f754\",\"href\":\"resourceCatalogManagement/v4/resourceSpecification/cd29956f-6c68-44cc-bf54-705eb8d2f754\",\"name\":\"card\",\"version\":\"v1.0.0\"},\"resourceRelationship\":[{\"type\":\"assignedTo\",\"resource\":{\"id\":\"#{assignee.id}\",\"href\":\"resourceInventoryManagement/v4/resource/#{assignee.id}\"},\"resourceRelationshipCharacteristic\":[{\"name\":\"port\",\"value\":5}]}]})
    end

    test "unassign an auto-assigned port from a resource" do
      {:ok, assignee} = Parties.build_shelf_with_installer()

      {:ok, card} = Servo.build_card(%{})

      updates = [
        card: [family: :ISAM, model: "EBLT48", technology: :adsl2Plus],
        ports: [first: 1, last: 48, assignable_type: "ADSL2+"]
      ]

      {:ok, card} = Servo.define_card(card, %{characteristic_value_updates: updates})

      {:ok, card} =
        Servo.assign_port(card, %{
          assignment: %Assignment{assignee_id: assignee.id, operation: :auto_assign}
        })

      assigned_rels = Enum.filter(card.forward_relationships, fn rel -> rel.type == :assignedTo end)
      assert length(assigned_rels) == 1

      assigned_port =
        Enum.find(card.forward_relationships, fn rel -> rel.type == :assignedTo end)
        |> Map.get(:assigned)

      {:ok, card} =
        Servo.assign_port(card, %{
          assignment: %Assignment{
            id: assigned_port,
            assignee_id: assignee.id,
            operation: :unassign
          }
        })

      assigned_rels = Enum.filter(card.forward_relationships, fn rel -> rel.type == :assignedTo end)
      assert length(assigned_rels) == 0

      encoding = Jason.encode!(card) |> Diffo.Util.summarise_dates()

      assert encoding ==
               ~s({\"id\":\"#{card.id}",\"href\":\"resourceInventoryManagement/v4/resource/#{card.id}",\"category\":\"Network Resource\",\"description\":\"A Card Resource Instance\",\"resourceSpecification\":{\"id\":\"cd29956f-6c68-44cc-bf54-705eb8d2f754\",\"href\":\"resourceCatalogManagement/v4/resourceSpecification/cd29956f-6c68-44cc-bf54-705eb8d2f754\",\"name\":\"card\",\"version\":\"v1.0.0\"}})
    end
  end
end
