defmodule Diffo.Access.CableTest do
  @moduledoc false
  use ExUnit.Case
  alias Diffo.Provider.Specification
  alias Diffo.Provider.Characteristic
  alias Diffo.Access
  alias Diffo.Access.Cable
  alias Diffo.Access.Assignment
  alias Diffo.Access.IntegerUnit
  alias Diffo.Test.Characteristics

  setup_all do
    AshNeo4j.BoltxHelper.start()
  end

  setup do
    on_exit(fn ->
      AshNeo4j.Neo4jHelper.delete_all()
    end)
  end

  describe "build cable" do
    test "create a cable" do
      {:ok, cable} = Access.build_cable(%{})

      # check the instance is a Cable
      assert is_struct(cable, Cable)

      # check specification resource enrichment and node relationship
      refute is_nil(cable.specification_id)
      assert is_struct(cable.specification, Specification)

      assert AshNeo4j.Neo4jHelper.nodes_relate_how?(
               :Instance,
               %{uuid: cable.id},
               :Specification,
               %{uuid: cable.specification_id},
               :SPECIFIED_BY,
               :outgoing
             )

      # check characteristic resource enrichment and node relationships
      assert is_list(cable.characteristics)
      assert length(cable.characteristics) == 2

      Enum.each(cable.characteristics, fn characteristic ->
        assert is_struct(characteristic, Characteristic)

        assert AshNeo4j.Neo4jHelper.nodes_relate_how?(
                 :Instance,
                 %{uuid: cable.id},
                 :Characteristic,
                 %{uuid: characteristic.id},
                 :HAS,
                 :outgoing
               )
      end)

      encoding = Jason.encode!(cable) |> Diffo.Util.summarise_dates()

      assert encoding ==
               ~s({\"id\":\"#{cable.id}",\"href\":\"resourceInventoryManagement/v4/resource/cable/#{cable.id}",\"category\":\"Network Resource\",\"resourceSpecification\":{\"id\":\"ce0a567a-6abb-4862-9e33-851fd79fa595\",\"href\":\"resourceCatalogManagement/v4/resourceSpecification/ce0a567a-6abb-4862-9e33-851fd79fa595\",\"name\":\"cable\",\"version\":\"v1.0.0\"},\"resourceCharacteristic\":[{\"name\":\"cable\",\"value\":{}},{\"name\":\"pairs\",\"value\":{\"first\":0,\"last\":0,\"free\":0,\"algorithm\":\"lowest\"}}]})
    end

    test "define cable" do
      {:ok, cable} = Access.build_cable(%{})

      updates = [
        cable: [pairs: 60, length: %IntegerUnit{amount: 600, unit: :m}, technology: :PIUT],
        pairs: [first: 1, last: 60, free: 60, type: "copper"]
      ]

      {:ok, cable} = Access.define_cable(cable, %{characteristic_value_updates: updates})

      encoding = Jason.encode!(cable) |> Diffo.Util.summarise_dates()

      assert encoding ==
               ~s({\"id\":\"#{cable.id}",\"href\":\"resourceInventoryManagement/v4/resource/cable/#{cable.id}",\"category\":\"Network Resource\",\"resourceSpecification\":{\"id\":\"ce0a567a-6abb-4862-9e33-851fd79fa595\",\"href\":\"resourceCatalogManagement/v4/resourceSpecification/ce0a567a-6abb-4862-9e33-851fd79fa595\",\"name\":\"cable\",\"version\":\"v1.0.0\"},\"resourceCharacteristic\":[{\"name\":\"cable\",\"value\":{\"pairs\":60,\"length\":{\"amount\":600,\"unit\":\"m\"},\"technology\":\"PIUT\"}},{\"name\":\"pairs\",\"value\":{\"first\":1,\"last\":60,\"free\":60,\"type\":\"copper\",\"algorithm\":\"lowest\"}}]})
    end

    test "auto assign pair to service" do
      {:ok, assignee} = Access.qualify_dsl()

      {:ok, cable} = Access.build_cable(%{})

      updates = [
        cable: [pairs: 60, length: %IntegerUnit{amount: 600, unit: :m}, technology: :PIUT],
        pairs: [first: 1, last: 60, free: 60, type: "copper"]
      ]

      {:ok, cable} = Access.define_cable(cable, %{characteristic_value_updates: updates})

      {:ok, cable} =
        Access.assign_pair(cable, %{
          assignment: %Assignment{assignee_id: assignee.id, operation: :auto_assign}
        })

      Characteristics.check_values([pairs: [free: 59]], cable)

      encoding = Jason.encode!(cable) |> Diffo.Util.summarise_dates()

      assert encoding ==
               ~s({\"id\":\"#{cable.id}",\"href\":\"resourceInventoryManagement/v4/resource/cable/#{cable.id}",\"category\":\"Network Resource\",\"resourceSpecification\":{\"id\":\"ce0a567a-6abb-4862-9e33-851fd79fa595\",\"href\":\"resourceCatalogManagement/v4/resourceSpecification/ce0a567a-6abb-4862-9e33-851fd79fa595\",\"name\":\"cable\",\"version\":\"v1.0.0\"},\"serviceRelationship\":[{\"type\":\"assignedTo\",\"service\":{\"id\":\"#{assignee.id}\",\"href\":\"serviceInventoryManagement/v4/service/dslAccess/#{assignee.id}\"},\"serviceRelationshipCharacteristic\":[{\"name\":\"pair\",\"value\":1}]}],\"resourceCharacteristic\":[{\"name\":\"cable\",\"value\":{\"pairs\":60,\"length\":{\"amount\":600,\"unit\":\"m\"},\"technology\":\"PIUT\"}},{\"name\":\"pairs\",\"value\":{\"first\":1,\"last\":60,\"free\":59,\"type\":\"copper\",\"algorithm\":\"lowest\"}}]})
    end

    test "auto assign two pairs to same service" do
      {:ok, assignee} = Access.qualify_dsl()

      {:ok, cable} = Access.build_cable(%{})

      updates = [
        cable: [pairs: 60, length: %IntegerUnit{amount: 600, unit: :m}, technology: :PIUT],
        pairs: [first: 1, last: 60, free: 60, type: "copper"]
      ]

      {:ok, cable} = Access.define_cable(cable, %{characteristic_value_updates: updates})

      {:ok, cable} =
        Access.assign_pair(cable, %{
          assignment: %Assignment{assignee_id: assignee.id, operation: :auto_assign}
        })

      {:ok, cable} =
        Access.assign_pair(cable, %{
          assignment: %Assignment{assignee_id: assignee.id, operation: :auto_assign}
        })

      Characteristics.check_values([pairs: [free: 58]], cable)

      encoding = Jason.encode!(cable) |> Diffo.Util.summarise_dates()

      assert encoding ==
               ~s({\"id\":\"#{cable.id}",\"href\":\"resourceInventoryManagement/v4/resource/cable/#{cable.id}",\"category\":\"Network Resource\",\"resourceSpecification\":{\"id\":\"ce0a567a-6abb-4862-9e33-851fd79fa595\",\"href\":\"resourceCatalogManagement/v4/resourceSpecification/ce0a567a-6abb-4862-9e33-851fd79fa595\",\"name\":\"cable\",\"version\":\"v1.0.0\"},\"serviceRelationship\":[{\"type\":\"assignedTo\",\"service\":{\"id\":\"#{assignee.id}\",\"href\":\"serviceInventoryManagement/v4/service/dslAccess/#{assignee.id}\"},\"serviceRelationshipCharacteristic\":[{\"name\":\"pair\",\"value\":1}]},{\"type\":\"assignedTo\",\"service\":{\"id\":\"#{assignee.id}\",\"href\":\"serviceInventoryManagement/v4/service/dslAccess/#{assignee.id}\"},\"serviceRelationshipCharacteristic\":[{\"name\":\"pair\",\"value\":2}]}],\"resourceCharacteristic\":[{\"name\":\"cable\",\"value\":{\"pairs\":60,\"length\":{\"amount\":600,\"unit\":\"m\"},\"technology\":\"PIUT\"}},{\"name\":\"pairs\",\"value\":{\"first\":1,\"last\":60,\"free\":58,\"type\":\"copper\",\"algorithm\":\"lowest\"}}]})
    end

    test "specific assignment rejects duplicate request" do
      {:ok, assignee} = Access.qualify_dsl()

      {:ok, cable} = Access.build_cable(%{})

      updates = [
        cable: [pairs: 60, length: %IntegerUnit{amount: 600, unit: :m}, technology: :PIUT],
        pairs: [first: 1, last: 60, free: 60, type: "copper"]
      ]

      {:ok, cable} = Access.define_cable(cable, %{characteristic_value_updates: updates})

      {:ok, cable} =
        Access.assign_pair(cable, %{
          assignment: %Assignment{id: 5, assignee_id: assignee.id, operation: :assign}
        })

      {:error, _error} =
        Access.assign_pair(cable, %{
          assignment: %Assignment{id: 5, assignee_id: assignee.id, operation: :assign}
        })

      Characteristics.check_values([pairs: [free: 59]], cable)

      encoding = Jason.encode!(cable) |> Diffo.Util.summarise_dates()

      assert encoding ==
               ~s({\"id\":\"#{cable.id}",\"href\":\"resourceInventoryManagement/v4/resource/cable/#{cable.id}",\"category\":\"Network Resource\",\"resourceSpecification\":{\"id\":\"ce0a567a-6abb-4862-9e33-851fd79fa595\",\"href\":\"resourceCatalogManagement/v4/resourceSpecification/ce0a567a-6abb-4862-9e33-851fd79fa595\",\"name\":\"cable\",\"version\":\"v1.0.0\"},\"serviceRelationship\":[{\"type\":\"assignedTo\",\"service\":{\"id\":\"#{assignee.id}\",\"href\":\"serviceInventoryManagement/v4/service/dslAccess/#{assignee.id}\"},\"serviceRelationshipCharacteristic\":[{\"name\":\"pair\",\"value\":5}]}],\"resourceCharacteristic\":[{\"name\":\"cable\",\"value\":{\"pairs\":60,\"length\":{\"amount\":600,\"unit\":\"m\"},\"technology\":\"PIUT\"}},{\"name\":\"pairs\",\"value\":{\"first\":1,\"last\":60,\"free\":59,\"type\":\"copper\",\"algorithm\":\"lowest\"}}]})
    end
  end
end
