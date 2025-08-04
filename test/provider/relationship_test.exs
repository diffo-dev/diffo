defmodule Diffo.Provider.RelationshipTest do
  @moduledoc false
  use ExUnit.Case

  setup_all do
    AshNeo4j.BoltxHelper.start()
  end

  setup do
    on_exit(fn ->
      AshNeo4j.Neo4jHelper.delete_all()
    end)
  end

  describe "Diffo.Provider read Relationships" do
    test "list relationships - success" do
      access_specification = Diffo.Provider.create_specification!(%{name: "access"})
      aggregation_specification = Diffo.Provider.create_specification!(%{name: "aggregation"})
      edge_specification = Diffo.Provider.create_specification!(%{name: "edge"})
      access_instance = Diffo.Provider.create_instance!(%{specified_by: access_specification.id})

      aggregation_instance =
        Diffo.Provider.create_instance!(%{specified_by: aggregation_specification.id})

      edge_instance = Diffo.Provider.create_instance!(%{specified_by: edge_specification.id})

      Diffo.Provider.create_relationship!(%{
        alias: :aggregation_peer,
        type: :refersTo,
        source_id: access_instance.id,
        target_id: aggregation_instance.id
      })

      Diffo.Provider.create_relationship!(%{
        alias: :access_peer,
        type: :refersTo,
        source_id: aggregation_instance.id,
        target_id: access_instance.id
      })

      Diffo.Provider.create_relationship!(%{
        alias: :edge_peer,
        type: :refersTo,
        source_id: aggregation_instance.id,
        target_id: edge_instance.id
      })

      Diffo.Provider.create_relationship!(%{
        alias: :aggregation_peer,
        type: :refersTo,
        source_id: edge_instance.id,
        target_id: aggregation_instance.id
      })

      relationships = Diffo.Provider.list_relationships!()
      assert length(relationships) == 4
      # should be sorted by alias then type
      assert Map.get(List.first(relationships), :alias) == :access_peer
      assert Map.get(List.last(relationships), :alias) == :edge_peer
    end

    test "list service relationships from - success" do
      specification = Diffo.Provider.create_specification!(%{name: "accessEvc"})
      evpl1 = Diffo.Provider.create_instance!(%{specified_by: specification.id, name: "evpl1"})
      evpl2 = Diffo.Provider.create_instance!(%{specified_by: specification.id, name: "evpl2"})
      evpl3 = Diffo.Provider.create_instance!(%{specified_by: specification.id, name: "evpl3"})

      Diffo.Provider.create_relationship!(%{
        type: :refersTo,
        source_id: evpl1.id,
        target_id: evpl2.id
      })

      Diffo.Provider.create_relationship!(%{
        type: :refersTo,
        source_id: evpl2.id,
        target_id: evpl1.id
      })

      Diffo.Provider.create_relationship!(%{
        type: :refersTo,
        source_id: evpl1.id,
        target_id: evpl3.id
      })

      Diffo.Provider.create_relationship!(%{
        type: :refersTo,
        source_id: evpl3.id,
        target_id: evpl1.id
      })

      service_relationships_from_evpl1 = Diffo.Provider.list_service_relationships_from!(evpl1.id)
      assert length(service_relationships_from_evpl1) == 2
      # TODO check sorted by href
      service_relationships_from_evpl2 = Diffo.Provider.list_service_relationships_from!(evpl2.id)
      assert length(service_relationships_from_evpl2) == 1
      service_relationships_from_evpl3 = Diffo.Provider.list_service_relationships_from!(evpl3.id)
      assert length(service_relationships_from_evpl3) == 1
      # but there should be no resource relationships
      assert Diffo.Provider.list_resource_relationships_from!(evpl1.id) == []
      assert Diffo.Provider.list_resource_relationships_from!(evpl2.id) == []
    end

    test "list resource relationships from - success" do
      specification =
        Diffo.Provider.create_specification!(%{name: "cable", type: :resourceSpecification})

      cable1 =
        Diffo.Provider.create_instance!(%{
          specified_by: specification.id,
          name: "cable1",
          type: :resource
        })

      cable2 =
        Diffo.Provider.create_instance!(%{
          specified_by: specification.id,
          name: "cable2",
          type: :resource
        })

      cable3 =
        Diffo.Provider.create_instance!(%{
          specified_by: specification.id,
          name: "cable3",
          type: :resource
        })

      Diffo.Provider.create_relationship!(%{
        type: :connectedTo,
        source_id: cable1.id,
        target_id: cable2.id
      })

      Diffo.Provider.create_relationship!(%{
        type: :connectedFrom,
        source_id: cable2.id,
        target_id: cable1.id
      })

      Diffo.Provider.create_relationship!(%{
        type: :connectedTo,
        source_id: cable2.id,
        target_id: cable3.id
      })

      Diffo.Provider.create_relationship!(%{
        type: :connectedFrom,
        source_id: cable3.id,
        target_id: cable2.id
      })

      resource_relationships_from_cable1 =
        Diffo.Provider.list_resource_relationships_from!(cable1.id)

      assert length(resource_relationships_from_cable1) == 1

      resource_relationships_from_cable2 =
        Diffo.Provider.list_resource_relationships_from!(cable2.id)

      assert length(resource_relationships_from_cable2) == 2
      # TODO check sorted by href
      resource_relationships_from_cable3 =
        Diffo.Provider.list_resource_relationships_from!(cable3.id)

      assert length(resource_relationships_from_cable3) == 1
      # but there should be no service relationships
      assert Diffo.Provider.list_service_relationships_from!(cable1.id) == []
      assert Diffo.Provider.list_service_relationships_from!(cable2.id) == []
      assert Diffo.Provider.list_service_relationships_from!(cable3.id) == []
    end
  end

  describe "Diffo.Provider create Relationships" do
    test "create a mutual peer service relationship - success" do
      specification = Diffo.Provider.create_specification!(%{name: "accessEvc"})
      evpl1 = Diffo.Provider.create_instance!(%{specified_by: specification.id, name: "evpl1"})
      evpl2 = Diffo.Provider.create_instance!(%{specified_by: specification.id, name: "evpl2"})

      relationship1 =
        Diffo.Provider.create_relationship!(%{
          type: :refersTo,
          source_id: evpl1.id,
          target_id: evpl2.id
        })

      relationship2 =
        Diffo.Provider.create_relationship!(%{
          type: :refersTo,
          source_id: evpl2.id,
          target_id: evpl1.id
        })

      loaded_relationship1 = relationship1 |> Ash.load!([:source, :target])

      assert loaded_relationship1.source_id == evpl1.id
      assert loaded_relationship1.target_id == evpl2.id
      assert is_struct(loaded_relationship1.source, Diffo.Provider.Instance)
      assert is_struct(loaded_relationship1.target, Diffo.Provider.Instance)

      assert relationship2.source_id == evpl2.id
      assert relationship2.target_id == evpl1.id
      assert is_struct(relationship2.source, Diffo.Provider.Instance)
      assert is_struct(relationship2.target, Diffo.Provider.Instance)
    end

    test "create a mutual connects resource relationship - success" do
      resource_specification =
        Diffo.Provider.create_specification!(%{name: "cable", type: :resourceSpecification})

      cable1 =
        Diffo.Provider.create_instance!(%{
          specified_by: resource_specification.id,
          type: :resource
        })

      cable2 =
        Diffo.Provider.create_instance!(%{
          specified_by: resource_specification.id,
          type: :resource
        })

      relationship1 =
        Diffo.Provider.create_relationship!(%{
          type: :connectedTo,
          source_id: cable1.id,
          target_id: cable2.id
        })

      relationship2 =
        Diffo.Provider.create_relationship!(%{
          type: :connectedFrom,
          source_id: cable2.id,
          target_id: cable1.id
        })

      loaded_relationship1 = relationship1 |> Ash.load!([:source, :target])

      assert relationship1.source_id == cable1.id
      assert relationship1.target_id == cable2.id
      assert is_struct(relationship1.source, Diffo.Provider.Instance)
      assert is_struct(relationship1.target, Diffo.Provider.Instance)

      assert relationship2.source_id == cable2.id
      assert relationship2.target_id == cable1.id
      assert is_struct(relationship2.source, Diffo.Provider.Instance)
      assert is_struct(relationship2.target, Diffo.Provider.Instance)
    end

    test "create a service - resource relationship - success" do
      service_specification = Diffo.Provider.create_specification!(%{name: "adslAccess"})

      resource_specification =
        Diffo.Provider.create_specification!(%{name: "can", type: :resourceSpecification})

      service_instance =
        Diffo.Provider.create_instance!(%{specified_by: service_specification.id})

      resource_instance =
        Diffo.Provider.create_instance!(%{
          specified_by: resource_specification.id,
          type: :resource
        })

      relationship =
        Diffo.Provider.create_relationship!(%{
          type: :isAssigned,
          source_id: service_instance.id,
          target_id: resource_instance.id
        })

      assert relationship.source_id == service_instance.id
      assert relationship.target_id == resource_instance.id
      assert is_struct(relationship.source, Diffo.Provider.Instance)
      assert is_struct(relationship.target, Diffo.Provider.Instance)
    end

    test "create relationship with characteristics - success" do
      specification = Diffo.Provider.create_specification!(%{name: "evc"})

      first_instance =
        Diffo.Provider.create_instance!(%{specified_by: specification.id, name: "first"})

      second_instance =
        Diffo.Provider.create_instance!(%{specified_by: specification.id, name: "second"})

      first_characteristic =
        Diffo.Provider.create_characteristic!(%{
          name: :role,
          value: "worker",
          type: :relationship
        })

      second_characteristic =
        Diffo.Provider.create_characteristic!(%{
          name: :type,
          value: :evpl,
          type: :relationship
        })

      Diffo.Provider.create_relationship!(%{
        type: :uses,
        source_id: first_instance.id,
        target_id: second_instance.id,
        characteristics: [first_characteristic.id, second_characteristic.id]
      })
    end

    test "create duplicate characteristic on same relationship - failure" do
      specification = Diffo.Provider.create_specification!(%{name: "evc"})

      first_instance =
        Diffo.Provider.create_instance!(%{specified_by: specification.id, name: "first"})

      second_instance =
        Diffo.Provider.create_instance!(%{specified_by: specification.id, name: "second"})

      first_characteristic =
        Diffo.Provider.create_characteristic!(%{
          name: :role,
          value: "worker",
          type: :relationship
        })

      second_characteristic =
        Diffo.Provider.create_characteristic!(%{
          name: :role,
          value: "protect",
          type: :relationship
        })

      {:error, _} =
        Diffo.Provider.create_relationship(%{
          type: :uses,
          source_id: first_instance.id,
          target_id: second_instance.id,
          characteristics: [first_characteristic.id, second_characteristic.id]
        })
    end
  end

  describe "Diffo.Provider updated Relationships" do
    test "add alias - success" do
      parent_specification =
        Diffo.Provider.create_specification!(%{name: "can", type: :resourceSpecification})

      child_specification =
        Diffo.Provider.create_specification!(%{
          name: "dslamLineCard",
          type: :resourceSpecification
        })

      parent_instance =
        Diffo.Provider.create_instance!(%{specified_by: parent_specification.id, type: :resource})

      child_instance =
        Diffo.Provider.create_instance!(%{specified_by: child_specification.id, type: :resource})

      relationship =
        Diffo.Provider.create_relationship!(%{
          type: :usedBy,
          source_id: child_instance.id,
          target_id: parent_instance.id
        })

      updated_relationship =
        relationship |> Diffo.Provider.update_relationship!(%{alias: :lineCard})

      assert updated_relationship.type == :usedBy
      assert updated_relationship.alias == :lineCard
    end

    test "add alias - failure - resource cannot have supporting service" do
      parent_specification =
        Diffo.Provider.create_specification!(%{name: "can", type: :resourceSpecification})

      child_specification = Diffo.Provider.create_specification!(%{name: "adslAccess"})

      parent_instance =
        Diffo.Provider.create_instance!(%{specified_by: parent_specification.id, type: :resource})

      child_instance = Diffo.Provider.create_instance!(%{specified_by: child_specification.id})

      relationship =
        Diffo.Provider.create_relationship(%{
          type: :bestows,
          source_id: parent_instance.id,
          target_id: child_instance.id
        })

      {:error, _error} = relationship |> Diffo.Provider.update_relationship(%{alias: :access})
    end
  end

  describe "Diffo.Provider encode Relationships" do
    test "encode service instance serviceRelationship json - success" do
      parent_specification = Diffo.Provider.create_specification!(%{name: "siteConnection"})
      child_specification = Diffo.Provider.create_specification!(%{name: "device"})
      parent_instance = Diffo.Provider.create_instance!(%{specified_by: parent_specification.id})
      child_instance = Diffo.Provider.create_instance!(%{specified_by: child_specification.id})

      characteristic =
        Diffo.Provider.create_characteristic!(%{
          name: :role,
          value: :gateway,
          type: :relationship
        })

      relationship =
        Diffo.Provider.create_relationship!(%{
          type: :bestows,
          source_id: parent_instance.id,
          target_id: child_instance.id,
          characteristics: [characteristic.id]
        })

      relationship |> Ash.reload!()

      relationships =
        Diffo.Provider.list_service_relationships_from!(parent_instance.id)

      loaded_relationships = Enum.into(relationships, [], &Ash.reload!(&1))

      encoding = Jason.encode!(loaded_relationships)

      assert encoding ==
               ~s([{\"type\":\"bestows\",\"service\":{\"id\":\"#{child_instance.id}\",\"href\":\"serviceInventoryManagement/v4/service/device/#{child_instance.id}\"},\"serviceRelationshipCharacteristic\":[{\"name\":\"role\",\"value\":\"gateway\"}]}])
    end

    test "encode service instance resourceRelationship json - success" do
      service_specification = Diffo.Provider.create_specification!(%{name: "adslAccess"})

      resource_specification =
        Diffo.Provider.create_specification!(%{name: "can", type: :resourceSpecification})

      service_instance =
        Diffo.Provider.create_instance!(%{specified_by: service_specification.id})

      resource_instance =
        Diffo.Provider.create_instance!(%{
          specified_by: resource_specification.id,
          type: :resource
        })

      characteristic =
        Diffo.Provider.create_characteristic!(%{
          name: :role,
          value: :primary,
          type: :relationship
        })

      relationship =
        Diffo.Provider.create_relationship!(%{
          type: :isAssigned,
          source_id: service_instance.id,
          target_id: resource_instance.id,
          characteristics: [characteristic.id]
        })

      _read_relationship = Diffo.Provider.get_relationship_by_id!(relationship.id)

      relationships =
        Diffo.Provider.list_resource_relationships_from!(service_instance.id)

      loaded_relationships = Enum.into(relationships, [], &Ash.reload!(&1))

      encoding = Jason.encode!(loaded_relationships)

      assert encoding ==
               ~s([{\"type\":\"isAssigned\",\"resource\":{\"id\":\"#{resource_instance.id}\",\"href\":\"resourceInventoryManagement/v4/resource/can/#{resource_instance.id}\"},\"resourceRelationshipCharacteristic\":[{\"name\":\"role\",\"value\":\"primary\"}]}])
    end

    test "encode resource instance serviceRelationship json - success" do
      service_specification = Diffo.Provider.create_specification!(%{name: "adslAccess"})

      resource_specification =
        Diffo.Provider.create_specification!(%{name: "can", type: :resourceSpecification})

      service_instance =
        Diffo.Provider.create_instance!(%{specified_by: service_specification.id})

      resource_instance =
        Diffo.Provider.create_instance!(%{
          specified_by: resource_specification.id,
          type: :resource
        })

      _relationship =
        Diffo.Provider.create_relationship!(%{
          type: :assignedTo,
          source_id: resource_instance.id,
          target_id: service_instance.id
        })

      relationships =
        Diffo.Provider.list_service_relationships_from!(resource_instance.id)

      loaded_relationships = Enum.into(relationships, [], &Ash.reload!(&1))

      encoding = Jason.encode!(loaded_relationships)

      assert encoding ==
               ~s([{\"type\":\"assignedTo\",\"service\":{\"id\":\"#{service_instance.id}\",\"href\":\"serviceInventoryManagement/v4/service/adslAccess/#{service_instance.id}\"}}])
    end
  end

  describe "Diffo.Provider outstanding Relationships" do
    use Outstand

    test "resolve expected relationships" do
      service_specification = Diffo.Provider.create_specification!(%{name: "adslAccess"})

      resource_specification =
        Diffo.Provider.create_specification!(%{name: "can", type: :resourceSpecification})

      service_instance =
        Diffo.Provider.create_instance!(%{specified_by: service_specification.id})

      resource_instance =
        Diffo.Provider.create_instance!(%{
          specified_by: resource_specification.id,
          type: :resource
        })

      assigned_to_relationship =
        Diffo.Provider.create_relationship!(%{
          type: :assignedTo,
          source_id: resource_instance.id,
          target_id: service_instance.id
        })

      is_assigned_relationship =
        Diffo.Provider.create_relationship!(%{
          type: :isAssigned,
          source_id: service_instance.id,
          target_id: resource_instance.id
        })

      expected_assigned_to_relationship = %Diffo.Provider.Relationship{
        type: :assignedTo,
        target: Diffo.Provider.Reference.reference(service_instance),
        characteristics: nil
      }

      expected_is_assigned_relationship = %Diffo.Provider.Relationship{
        type: :isAssigned,
        target: Diffo.Provider.Reference.reference(resource_instance),
        characteristics: nil
      }

      refute expected_is_assigned_relationship --- is_assigned_relationship
      refute expected_assigned_to_relationship --- assigned_to_relationship
    end
  end

  describe "Diffo.Provider delete Relationships" do
    test "delete relationship with related instance - success" do
      parent_specification = Diffo.Provider.create_specification!(%{name: "siteConnection"})
      child_specification = Diffo.Provider.create_specification!(%{name: "device"})
      parent_instance = Diffo.Provider.create_instance!(%{specified_by: parent_specification.id})
      child_instance = Diffo.Provider.create_instance!(%{specified_by: child_specification.id})

      relationship =
        Diffo.Provider.create_relationship!(%{
          type: :bestows,
          source_id: parent_instance.id,
          target_id: child_instance.id
        })

      :ok = Diffo.Provider.delete_relationship(relationship)
      {:error, _error} = Diffo.Provider.get_relationship_by_id(relationship.id)
    end

    test "delete relationship with related instance - failure, related characteristic" do
      parent_specification = Diffo.Provider.create_specification!(%{name: "siteConnection"})
      child_specification = Diffo.Provider.create_specification!(%{name: "device"})
      parent_instance = Diffo.Provider.create_instance!(%{specified_by: parent_specification.id})
      child_instance = Diffo.Provider.create_instance!(%{specified_by: child_specification.id})

      characteristic =
        Diffo.Provider.create_characteristic!(%{
          name: :role,
          value: :gateway,
          type: :relationship
        })

      relationship =
        Diffo.Provider.create_relationship!(%{
          type: :bestows,
          source_id: parent_instance.id,
          target_id: child_instance.id,
          characteristics: [characteristic.id]
        })

      {:error, error} = Diffo.Provider.delete_relationship(relationship)
      assert is_struct(error, Ash.Error.Invalid)

      # now unrelate the relationship characteristic and we should be able to delete the relationship
      # now unrelate the feature from the instance
      Diffo.Provider.unrelate_relationship_characteristics!(relationship, %{
        characteristics: [characteristic.id]
      })

      :ok = Diffo.Provider.delete_relationship(relationship)
      {:error, _error} = Diffo.Provider.get_relationship_by_id(relationship.id)
    end
  end
end
