defmodule Diffo.Access.CardTest do
  @moduledoc false
  use ExUnit.Case
  alias Diffo.Provider.Specification
  alias Diffo.Provider.Characteristic
  alias Diffo.Access
  alias Diffo.Access.Card
  alias Diffo.Access.Assignment
  alias Diffo.Test.Characteristics

  setup_all do
    AshNeo4j.BoltxHelper.start()
  end

  setup do
    on_exit(fn ->
      AshNeo4j.Neo4jHelper.delete_all()
    end)
  end

  describe "build card" do
    test "create a card" do
      {:ok, card} = Access.build_card(%{})

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
               ~s({\"id\":\"#{card.id}",\"href\":\"resourceInventoryManagement/v4/resource/card/#{card.id}",\"category\":\"Network Resource\",\"resourceSpecification\":{\"id\":\"ca29956f-6c68-44cc-bf54-705eb8d2f754\",\"href\":\"resourceCatalogManagement/v4/resourceSpecification/ca29956f-6c68-44cc-bf54-705eb8d2f754\",\"name\":\"card\",\"version\":\"v1.0.0\"},\"resourceCharacteristic\":[{\"name\":\"card\",\"value\":{}},{\"name\":\"ports\",\"value\":{\"first\":0,\"last\":0,\"free\":0,\"algorithm\":\"lowest\"}}]})
    end

    test "define card" do
      {:ok, card} = Access.build_card(%{})

      updates = [
        card: [family: :ISAM, model: "EBLT48", technology: :adsl2Plus],
        ports: [first: 1, last: 48, free: 48, type: "ADSL2+"]
      ]

      {:ok, card} = Access.define_card(card, %{characteristic_value_updates: updates})

      encoding = Jason.encode!(card) |> Diffo.Util.summarise_dates()

      assert encoding ==
               ~s({\"id\":\"#{card.id}",\"href\":\"resourceInventoryManagement/v4/resource/card/#{card.id}",\"category\":\"Network Resource\",\"resourceSpecification\":{\"id\":\"ca29956f-6c68-44cc-bf54-705eb8d2f754\",\"href\":\"resourceCatalogManagement/v4/resourceSpecification/ca29956f-6c68-44cc-bf54-705eb8d2f754\",\"name\":\"card\",\"version\":\"v1.0.0\"},\"resourceCharacteristic\":[{\"name\":\"card\",\"value\":{\"family\":\"ISAM\",\"model\":\"EBLT48\",\"technology\":\"adsl2Plus\"}},{\"name\":\"ports\",\"value\":{\"first\":1,\"last\":48,\"free\":48,\"type\":\"ADSL2+\",\"algorithm\":\"lowest\"}}]})
    end

    test "auto assign port to service" do
      {:ok, assignee} = Access.qualify_dsl()

      {:ok, card} = Access.build_card(%{})

      updates = [
        card: [family: :ISAM, model: "EBLT48", technology: :adsl2Plus],
        ports: [first: 1, last: 48, free: 48, type: "ADSL2+"]
      ]

      {:ok, card} = Access.define_card(card, %{characteristic_value_updates: updates})

      {:ok, card} =
        Access.assign_port(card, %{
          assignment: %Assignment{assignee_id: assignee.id, operation: :auto_assign}
        })

      Characteristics.check_values([ports: [free: 47]], card)

      encoding = Jason.encode!(card) |> Diffo.Util.summarise_dates()

      assert encoding ==
               ~s({\"id\":\"#{card.id}",\"href\":\"resourceInventoryManagement/v4/resource/card/#{card.id}",\"category\":\"Network Resource\",\"resourceSpecification\":{\"id\":\"ca29956f-6c68-44cc-bf54-705eb8d2f754\",\"href\":\"resourceCatalogManagement/v4/resourceSpecification/ca29956f-6c68-44cc-bf54-705eb8d2f754\",\"name\":\"card\",\"version\":\"v1.0.0\"},\"serviceRelationship\":[{\"type\":\"assignedTo\",\"service\":{\"id\":\"#{assignee.id}\",\"href\":\"serviceInventoryManagement/v4/service/dslAccess/#{assignee.id}\"},\"serviceRelationshipCharacteristic\":[{\"name\":\"port\",\"value\":1}]}],\"resourceCharacteristic\":[{\"name\":\"card\",\"value\":{\"family\":\"ISAM\",\"model\":\"EBLT48\",\"technology\":\"adsl2Plus\"}},{\"name\":\"ports\",\"value\":{\"first\":1,\"last\":48,\"free\":47,\"type\":\"ADSL2+\",\"algorithm\":\"lowest\"}}]})
    end

    test "auto assign two ports to same service" do
      {:ok, assignee} = Access.qualify_dsl()

      {:ok, card} = Access.build_card(%{})

      updates = [
        card: [family: :ISAM, model: "EBLT48", technology: :adsl2Plus],
        ports: [first: 1, last: 48, free: 48, type: "ADSL2+"]
      ]

      {:ok, card} = Access.define_card(card, %{characteristic_value_updates: updates})

      {:ok, card} =
        Access.assign_port(card, %{
          assignment: %Assignment{assignee_id: assignee.id, operation: :auto_assign}
        })

      {:ok, card} =
        Access.assign_port(card, %{
          assignment: %Assignment{assignee_id: assignee.id, operation: :auto_assign}
        })

      Characteristics.check_values([ports: [free: 46]], card)

      encoding = Jason.encode!(card) |> Diffo.Util.summarise_dates()

      assert encoding ==
               ~s({\"id\":\"#{card.id}",\"href\":\"resourceInventoryManagement/v4/resource/card/#{card.id}",\"category\":\"Network Resource\",\"resourceSpecification\":{\"id\":\"ca29956f-6c68-44cc-bf54-705eb8d2f754\",\"href\":\"resourceCatalogManagement/v4/resourceSpecification/ca29956f-6c68-44cc-bf54-705eb8d2f754\",\"name\":\"card\",\"version\":\"v1.0.0\"},\"serviceRelationship\":[{\"type\":\"assignedTo\",\"service\":{\"id\":\"#{assignee.id}\",\"href\":\"serviceInventoryManagement/v4/service/dslAccess/#{assignee.id}\"},\"serviceRelationshipCharacteristic\":[{\"name\":\"port\",\"value\":1}]},{\"type\":\"assignedTo\",\"service\":{\"id\":\"#{assignee.id}\",\"href\":\"serviceInventoryManagement/v4/service/dslAccess/#{assignee.id}\"},\"serviceRelationshipCharacteristic\":[{\"name\":\"port\",\"value\":2}]}],\"resourceCharacteristic\":[{\"name\":\"card\",\"value\":{\"family\":\"ISAM\",\"model\":\"EBLT48\",\"technology\":\"adsl2Plus\"}},{\"name\":\"ports\",\"value\":{\"first\":1,\"last\":48,\"free\":46,\"type\":\"ADSL2+\",\"algorithm\":\"lowest\"}}]})
    end

    test "specific assignment rejects duplicate request" do
      {:ok, assignee} = Access.qualify_dsl()

      {:ok, card} = Access.build_card(%{})

      updates = [
        card: [family: :ISAM, model: "EBLT48", technology: :adsl2Plus],
        ports: [first: 1, last: 48, free: 48, type: "ADSL2+"]
      ]

      {:ok, card} = Access.define_card(card, %{characteristic_value_updates: updates})

      {:ok, card} =
        Access.assign_port(card, %{
          assignment: %Assignment{id: 5, assignee_id: assignee.id, operation: :assign}
        })

      {:error, _error} =
        Access.assign_port(card, %{
          assignment: %Assignment{id: 5, assignee_id: assignee.id, operation: :assign}
        })

      Characteristics.check_values([ports: [free: 47]], card)

      encoding = Jason.encode!(card) |> Diffo.Util.summarise_dates()

      assert encoding ==
               ~s({\"id\":\"#{card.id}",\"href\":\"resourceInventoryManagement/v4/resource/card/#{card.id}",\"category\":\"Network Resource\",\"resourceSpecification\":{\"id\":\"ca29956f-6c68-44cc-bf54-705eb8d2f754\",\"href\":\"resourceCatalogManagement/v4/resourceSpecification/ca29956f-6c68-44cc-bf54-705eb8d2f754\",\"name\":\"card\",\"version\":\"v1.0.0\"},\"serviceRelationship\":[{\"type\":\"assignedTo\",\"service\":{\"id\":\"#{assignee.id}\",\"href\":\"serviceInventoryManagement/v4/service/dslAccess/#{assignee.id}\"},\"serviceRelationshipCharacteristic\":[{\"name\":\"port\",\"value\":5}]}],\"resourceCharacteristic\":[{\"name\":\"card\",\"value\":{\"family\":\"ISAM\",\"model\":\"EBLT48\",\"technology\":\"adsl2Plus\"}},{\"name\":\"ports\",\"value\":{\"first\":1,\"last\":48,\"free\":47,\"type\":\"ADSL2+\",\"algorithm\":\"lowest\"}}]})
    end
  end
end
