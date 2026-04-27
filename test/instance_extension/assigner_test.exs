# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.InstanceExtension.AssignerTest do
  @moduledoc false
  use ExUnit.Case
  alias Diffo.Provider.Specification
  alias Diffo.Provider.Characteristic
  alias Diffo.Provider.Assignment

  alias Diffo.Test.Characteristics
  alias Diffo.Test.Parties
  alias Diffo.Test.Servo
  alias Diffo.Test.Card

  setup_all do
    AshNeo4j.BoltyHelper.start()
  end

  setup do
    on_exit(fn ->
      AshNeo4j.Neo4jHelper.delete_all()
    end)
  end

  describe "build card" do
    @tag :card
    test "create a card" do
      {:ok, card} = Servo.build_card(%{})

      # check the instance is a Card
      assert is_struct(card, Card)

      # check specification resource enrichment and node relationship
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

      # check characteristic resource enrichment and node relationships
      assert is_list(card.characteristics)
      assert length(card.characteristics) == 2

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
               ~s({\"id\":\"#{card.id}",\"href\":\"resourceInventoryManagement/v4/resource/#{card.id}",\"category\":\"Network Resource\",\"resourceSpecification\":{\"id\":\"cd29956f-6c68-44cc-bf54-705eb8d2f754\",\"href\":\"resourceCatalogManagement/v4/resourceSpecification/cd29956f-6c68-44cc-bf54-705eb8d2f754\",\"name\":\"card\",\"version\":\"v1.0.0\"},\"resourceCharacteristic\":[{\"name\":\"card\",\"value\":{}},{\"name\":\"ports\",\"value\":{\"first\":1,\"last\":1,\"free\":1,\"algorithm\":\"lowest\"}}]})
    end

    test "define card" do
      {:ok, card} = Servo.build_card(%{})

      updates = [
        card: [family: :ISAM, model: "EBLT48", technology: :adsl2Plus],
        ports: [first: 1, last: 48, free: 48, assignable_type: "ADSL2+"]
      ]

      {:ok, card} = Servo.define_card(card, %{characteristic_value_updates: updates})

      encoding = Jason.encode!(card) |> Diffo.Util.summarise_dates()

      assert encoding ==
               ~s({\"id\":\"#{card.id}",\"href\":\"resourceInventoryManagement/v4/resource/#{card.id}",\"category\":\"Network Resource\",\"resourceSpecification\":{\"id\":\"cd29956f-6c68-44cc-bf54-705eb8d2f754\",\"href\":\"resourceCatalogManagement/v4/resourceSpecification/cd29956f-6c68-44cc-bf54-705eb8d2f754\",\"name\":\"card\",\"version\":\"v1.0.0\"},\"resourceCharacteristic\":[{\"name\":\"card\",\"value\":{\"family\":\"ISAM\",\"model\":\"EBLT48\",\"technology\":\"adsl2Plus\"}},{\"name\":\"ports\",\"value\":{\"first\":1,\"last\":48,\"free\":48,\"type\":\"ADSL2+\",\"algorithm\":\"lowest\"}}]})
    end

    test "auto assign port to resource" do
      {:ok, assignee} = Parties.build_shelf_with_installer()

      {:ok, card} = Servo.build_card(%{})

      updates = [
        card: [family: :ISAM, model: "EBLT48", technology: :adsl2Plus],
        ports: [first: 1, last: 48, free: 48, assignable_type: "ADSL2+"]
      ]

      {:ok, card} = Servo.define_card(card, %{characteristic_value_updates: updates})

      {:ok, card} =
        Servo.assign_port(card, %{
          assignment: %Assignment{assignee_id: assignee.id, operation: :auto_assign}
        })

      Characteristics.check_values([ports: [free: 47]], card)

      encoding = Jason.encode!(card) |> Diffo.Util.summarise_dates()

      assert encoding ==
               ~s({\"id\":\"#{card.id}",\"href\":\"resourceInventoryManagement/v4/resource/#{card.id}",\"category\":\"Network Resource\",\"resourceSpecification\":{\"id\":\"cd29956f-6c68-44cc-bf54-705eb8d2f754\",\"href\":\"resourceCatalogManagement/v4/resourceSpecification/cd29956f-6c68-44cc-bf54-705eb8d2f754\",\"name\":\"card\",\"version\":\"v1.0.0\"},\"resourceRelationship\":[{\"type\":\"assignedTo\",\"resource\":{\"id\":\"#{assignee.id}\",\"href\":\"resourceInventoryManagement/v4/resource/#{assignee.id}\"},\"resourceRelationshipCharacteristic\":[{\"name\":\"port\",\"value\":1}]}],\"resourceCharacteristic\":[{\"name\":\"card\",\"value\":{\"family\":\"ISAM\",\"model\":\"EBLT48\",\"technology\":\"adsl2Plus\"}},{\"name\":\"ports\",\"value\":{\"first\":1,\"last\":48,\"free\":47,\"type\":\"ADSL2+\",\"algorithm\":\"lowest\"}}]})
    end

    test "auto assign two ports to same resource" do
      {:ok, assignee} = Parties.build_shelf_with_installer()

      {:ok, card} = Servo.build_card(%{})

      updates = [
        card: [family: :ISAM, model: "EBLT48", technology: :adsl2Plus],
        ports: [first: 1, last: 48, free: 48, assignable_type: "ADSL2+"]
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

      Characteristics.check_values([ports: [free: 46]], card)

      encoding = Jason.encode!(card) |> Diffo.Util.summarise_dates()

      assert encoding ==
               ~s({\"id\":\"#{card.id}",\"href\":\"resourceInventoryManagement/v4/resource/#{card.id}",\"category\":\"Network Resource\",\"resourceSpecification\":{\"id\":\"cd29956f-6c68-44cc-bf54-705eb8d2f754\",\"href\":\"resourceCatalogManagement/v4/resourceSpecification/cd29956f-6c68-44cc-bf54-705eb8d2f754\",\"name\":\"card\",\"version\":\"v1.0.0\"},\"resourceRelationship\":[{\"type\":\"assignedTo\",\"resource\":{\"id\":\"#{assignee.id}\",\"href\":\"resourceInventoryManagement/v4/resource/#{assignee.id}\"},\"resourceRelationshipCharacteristic\":[{\"name\":\"port\",\"value\":1}]},{\"type\":\"assignedTo\",\"resource\":{\"id\":\"#{assignee.id}\",\"href\":\"resourceInventoryManagement/v4/resource/#{assignee.id}\"},\"resourceRelationshipCharacteristic\":[{\"name\":\"port\",\"value\":2}]}],\"resourceCharacteristic\":[{\"name\":\"card\",\"value\":{\"family\":\"ISAM\",\"model\":\"EBLT48\",\"technology\":\"adsl2Plus\"}},{\"name\":\"ports\",\"value\":{\"first\":1,\"last\":48,\"free\":46,\"type\":\"ADSL2+\",\"algorithm\":\"lowest\"}}]})
    end

    test "specific assignment rejects duplicate request" do
      {:ok, assignee} = Parties.build_shelf_with_installer()

      {:ok, card} = Servo.build_card(%{})

      updates = [
        card: [family: :ISAM, model: "EBLT48", technology: :adsl2Plus],
        ports: [first: 1, last: 48, free: 48, assignable_type: "ADSL2+"]
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

      Characteristics.check_values([ports: [free: 47]], card)

      encoding = Jason.encode!(card) |> Diffo.Util.summarise_dates()

      assert encoding ==
               ~s({\"id\":\"#{card.id}",\"href\":\"resourceInventoryManagement/v4/resource/#{card.id}",\"category\":\"Network Resource\",\"resourceSpecification\":{\"id\":\"cd29956f-6c68-44cc-bf54-705eb8d2f754\",\"href\":\"resourceCatalogManagement/v4/resourceSpecification/cd29956f-6c68-44cc-bf54-705eb8d2f754\",\"name\":\"card\",\"version\":\"v1.0.0\"},\"resourceRelationship\":[{\"type\":\"assignedTo\",\"resource\":{\"id\":\"#{assignee.id}\",\"href\":\"resourceInventoryManagement/v4/resource/#{assignee.id}\"},\"resourceRelationshipCharacteristic\":[{\"name\":\"port\",\"value\":5}]}],\"resourceCharacteristic\":[{\"name\":\"card\",\"value\":{\"family\":\"ISAM\",\"model\":\"EBLT48\",\"technology\":\"adsl2Plus\"}},{\"name\":\"ports\",\"value\":{\"first\":1,\"last\":48,\"free\":47,\"type\":\"ADSL2+\",\"algorithm\":\"lowest\"}}]})
    end

    test "unassign an auto-assigned port from a resource" do
      {:ok, assignee} = Parties.build_shelf_with_installer()

      {:ok, card} = Servo.build_card(%{})

      updates = [
        card: [family: :ISAM, model: "EBLT48", technology: :adsl2Plus],
        ports: [first: 1, last: 48, free: 48, assignable_type: "ADSL2+"]
      ]

      {:ok, card} = Servo.define_card(card, %{characteristic_value_updates: updates})

      {:ok, card} =
        Servo.assign_port(card, %{
          assignment: %Assignment{assignee_id: assignee.id, operation: :auto_assign}
        })

      Characteristics.check_values([ports: [free: 47]], card)

      assigned_port =
        Enum.find(card.forward_relationships, fn rel -> rel.type == :assignedTo end)
        |> Map.get(:characteristics)
        |> Enum.find(fn char -> char.name == :port end)
        |> Map.get(:value)
        |> Diffo.Unwrap.unwrap()

      {:ok, card} =
        Servo.assign_port(card, %{
          assignment: %Assignment{
            id: assigned_port,
            assignee_id: assignee.id,
            operation: :unassign
          }
        })

      Characteristics.check_values([ports: [free: 48]], card)

      encoding = Jason.encode!(card) |> Diffo.Util.summarise_dates()

      assert encoding ==
               ~s({\"id\":\"#{card.id}",\"href\":\"resourceInventoryManagement/v4/resource/#{card.id}",\"category\":\"Network Resource\",\"resourceSpecification\":{\"id\":\"cd29956f-6c68-44cc-bf54-705eb8d2f754\",\"href\":\"resourceCatalogManagement/v4/resourceSpecification/cd29956f-6c68-44cc-bf54-705eb8d2f754\",\"name\":\"card\",\"version\":\"v1.0.0\"},\"resourceCharacteristic\":[{\"name\":\"card\",\"value\":{\"family\":\"ISAM\",\"model\":\"EBLT48\",\"technology\":\"adsl2Plus\"}},{\"name\":\"ports\",\"value\":{\"first\":1,\"last\":48,\"free\":48,\"type\":\"ADSL2+\",\"algorithm\":\"lowest\"}}]})
    end
  end
end
