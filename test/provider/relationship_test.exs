defmodule Diffo.Provider.Relationship_Test do
  @moduledoc false
  use ExUnit.Case
  use Diffo.DataCase, async: true


  describe "Diffo.Provider prepare Relationships" do
    test "check there are no relationships" do
      assert Diffo.Provider.list_relationships!() == []
    end
  end

  describe "Diffo.Provider read Relationships" do
    test "list service relationships from - success" do
      specification = Diffo.Provider.create_specification!(%{name: "accessEvc"})
      evpl1 = Diffo.Provider.create_instance!(%{specification_id: specification.id, name: "evpl1"})
      evpl2 = Diffo.Provider.create_instance!(%{specification_id: specification.id, name: "evpl2"})
      evpl3 = Diffo.Provider.create_instance!(%{specification_id: specification.id, name: "evpl3"})
      Diffo.Provider.create_relationship!(%{type: :refersTo, source_id: evpl1.id, target_id: evpl2.id})
      Diffo.Provider.create_relationship!(%{type: :refersTo, source_id: evpl2.id, target_id: evpl1.id})
      Diffo.Provider.create_relationship!(%{type: :refersTo, source_id: evpl1.id, target_id: evpl3.id})
      Diffo.Provider.create_relationship!(%{type: :refersTo, source_id: evpl3.id, target_id: evpl1.id})
      service_relationships_from_evpl1 = Diffo.Provider.list_service_relationships_from!(evpl1.id)
      assert length(service_relationships_from_evpl1) == 2
      service_relationships_from_evpl2 = Diffo.Provider.list_service_relationships_from!(evpl2.id)
      assert length(service_relationships_from_evpl2) == 1
      service_relationships_from_evpl3 = Diffo.Provider.list_service_relationships_from!(evpl3.id)
      assert length(service_relationships_from_evpl3) == 1
      # but there should be no resource relationships
      assert Diffo.Provider.list_resource_relationships_from!(evpl1.id) == []
      assert Diffo.Provider.list_resource_relationships_from!(evpl2.id) == []
    end

    test "list resource relationships from - success" do
      specification = Diffo.Provider.create_specification!(%{name: "cable", type: :resourceSpecification})
      cable1 = Diffo.Provider.create_instance!(%{specification_id: specification.id, name: "cable1", type: :resource})
      cable2 = Diffo.Provider.create_instance!(%{specification_id: specification.id, name: "cable2", type: :resource})
      cable3 = Diffo.Provider.create_instance!(%{specification_id: specification.id, name: "cable3", type: :resource})
      Diffo.Provider.create_relationship!(%{type: :connectedTo, source_id: cable1.id, target_id: cable2.id})
      Diffo.Provider.create_relationship!(%{type: :connectedFrom, source_id: cable2.id, target_id: cable1.id})
      Diffo.Provider.create_relationship!(%{type: :connectedTo, source_id: cable2.id, target_id: cable3.id})
      Diffo.Provider.create_relationship!(%{type: :connectedFrom, source_id: cable3.id, target_id: cable2.id})
      resource_relationships_from_cable1 = Diffo.Provider.list_resource_relationships_from!(cable1.id)
      assert length(resource_relationships_from_cable1) == 1
      resource_relationships_from_cable2 = Diffo.Provider.list_resource_relationships_from!(cable2.id)
      assert length(resource_relationships_from_cable2) == 2
      resource_relationships_from_cable3 = Diffo.Provider.list_resource_relationships_from!(cable3.id)
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
      evpl1 = Diffo.Provider.create_instance!(%{specification_id: specification.id, name: "evpl1"})
      evpl2 = Diffo.Provider.create_instance!(%{specification_id: specification.id, name: "evpl2"})
      relationship1 = Diffo.Provider.create_relationship!(%{type: :refersTo, source_id: evpl1.id, target_id: evpl2.id})
      relationship2 = Diffo.Provider.create_relationship!(%{type: :refersTo, source_id: evpl2.id, target_id: evpl1.id})
      loaded_relationship1 = Diffo.Provider.get_relationship_by_id!(relationship1.id, load: [:source_type, :target_type, :source_href, :target_href])
      assert loaded_relationship1.source_type == :service
      assert loaded_relationship1.target_type == :service
      assert loaded_relationship1.source_href == "serviceInventoryManagement/v4/service/accessEvc/#{evpl1.id}"
      assert loaded_relationship1.target_href == "serviceInventoryManagement/v4/service/accessEvc/#{evpl2.id}"
      loaded_relationship2 = Diffo.Provider.get_relationship_by_id!(relationship2.id, load: [:source_type, :target_type, :source_href, :target_href])
      assert loaded_relationship2.source_type == :service
      assert loaded_relationship2.target_type == :service
      assert loaded_relationship2.source_href == "serviceInventoryManagement/v4/service/accessEvc/#{evpl2.id}"
      assert loaded_relationship2.target_href == "serviceInventoryManagement/v4/service/accessEvc/#{evpl1.id}"
    end

    test "create a mutual connects resource relationship - success" do
      resource_specification = Diffo.Provider.create_specification!(%{name: "cable", type: :resourceSpecification})
      cable1 = Diffo.Provider.create_instance!(%{specification_id: resource_specification.id, type: :resource})
      cable2 = Diffo.Provider.create_instance!(%{specification_id: resource_specification.id, type: :resource})
      relationship1 = Diffo.Provider.create_relationship!(%{type: :connectedTo, source_id: cable1.id, target_id: cable2.id})
      relationship2 = Diffo.Provider.create_relationship!(%{type: :connectedFrom, source_id: cable2.id, target_id: cable1.id})
      loaded_relationship1 = Diffo.Provider.get_relationship_by_id!(relationship1.id, load: [:source_type, :target_type, :source_href, :target_href])
      assert loaded_relationship1.source_type == :resource
      assert loaded_relationship1.target_type == :resource
      assert loaded_relationship1.source_href == "resourceInventoryManagement/v4/resource/cable/#{cable1.id}"
      assert loaded_relationship1.target_href == "resourceInventoryManagement/v4/resource/cable/#{cable2.id}"
      loaded_relationship2 = Diffo.Provider.get_relationship_by_id!(relationship2.id, load: [:source_type, :target_type, :source_href, :target_href])
      assert loaded_relationship2.source_type == :resource
      assert loaded_relationship2.target_type == :resource
      assert loaded_relationship2.source_href == "resourceInventoryManagement/v4/resource/cable/#{cable2.id}"
      assert loaded_relationship2.target_href == "resourceInventoryManagement/v4/resource/cable/#{cable1.id}"
    end

    test "create a service - resource relationship - success" do
      service_specification = Diffo.Provider.create_specification!(%{name: "adslAccess"})
      resource_specification = Diffo.Provider.create_specification!(%{name: "can", type: :resourceSpecification})
      service_instance = Diffo.Provider.create_instance!(%{specification_id: service_specification.id})
      resource_instance = Diffo.Provider.create_instance!(%{specification_id: resource_specification.id, type: :resource})
      relationship = Diffo.Provider.create_relationship!(%{type: :isAssigned, source_id: service_instance.id, target_id: resource_instance.id})
      loaded_relationship = Diffo.Provider.get_relationship_by_id!(relationship.id, load: [:source_type, :target_type, :source_href, :target_href])
      assert loaded_relationship.source_type == :service
      assert loaded_relationship.target_type == :resource
      assert loaded_relationship.source_href == "serviceInventoryManagement/v4/service/adslAccess/#{service_instance.id}"
      assert loaded_relationship.target_href == "resourceInventoryManagement/v4/resource/can/#{resource_instance.id}"
    end

  end

  describe "Diffo.Provider updated Relationships" do
    test "add alias - success" do
      parent_specification = Diffo.Provider.create_specification!(%{name: "can", type: :resourceSpecification})
      child_specification = Diffo.Provider.create_specification!(%{name: "dslamLineCard", type: :resourceSpecification})
      parent_instance = Diffo.Provider.create_instance!(%{specification_id: parent_specification.id, type: :resource})
      child_instance = Diffo.Provider.create_instance!(%{specification_id: child_specification.id, type: :resource})
      relationship = Diffo.Provider.create_relationship!(%{type: :usedBy, source_id: child_instance.id, target_id: parent_instance.id})
      updated_relationship = relationship |> Diffo.Provider.update_relationship!(%{alias: :lineCard})
      assert updated_relationship.type == :usedBy
      assert updated_relationship.alias == :lineCard
    end
  end

  describe "Diffo.Provider encode Relationships" do
    test "encode service instance serviceRelationship json - success" do
      parent_specification = Diffo.Provider.create_specification!(%{name: "siteConnection"})
      child_specification = Diffo.Provider.create_specification!(%{name: "device"})
      parent_instance = Diffo.Provider.create_instance!(%{specification_id: parent_specification.id})
      child_instance = Diffo.Provider.create_instance!(%{specification_id: child_specification.id})
      relationship = Diffo.Provider.create_relationship!(%{type: :bestows, source_id: parent_instance.id, target_id: child_instance.id})
      _characteristic = Diffo.Provider.create_characteristic!(%{relationship_id: relationship.id, name: :role, value: :gateway, type: :relationship})
      parent_service_relationships = Diffo.Provider.list_service_relationships_from!(parent_instance.id, load: [:target_type, :target_href, :characteristic])
      encoding = Jason.encode!(parent_service_relationships)
      assert String.starts_with?(encoding, "[{")
      assert String.contains?(encoding, ~s(\"type\":\"bestows\"))
      assert String.contains?(encoding, ~s(\"service\":{))
      assert String.contains?(encoding, ~s(\"id\":\"#{child_instance.id}\"))
      assert String.contains?(encoding, ~s(\"href\":\"serviceInventoryManagement/v4/service/device/#{child_instance.id}\"))
      assert String.contains?(encoding, ~s(\"serviceRelationshipCharacteristic\":[{))
      assert String.contains?(encoding, ~s(\"name\":\"role\"))
      assert String.contains?(encoding, ~s(\"value\":\"gateway\"))
      assert String.contains?(encoding, "\}]")
      assert String.ends_with?(encoding, "}]")
    end

    test "encode service instance resourceRelationship json - success" do
      service_specification = Diffo.Provider.create_specification!(%{name: "adslAccess"})
      resource_specification = Diffo.Provider.create_specification!(%{name: "can", type: :resourceSpecification})
      service_instance = Diffo.Provider.create_instance!(%{specification_id: service_specification.id})
      resource_instance = Diffo.Provider.create_instance!(%{specification_id: resource_specification.id, type: :resource})
      relationship = Diffo.Provider.create_relationship!(%{type: :isAssigned, source_id: service_instance.id, target_id: resource_instance.id})
      _characteristic = Diffo.Provider.create_characteristic!(%{relationship_id: relationship.id, name: :role, value: :primary, type: :relationship})
      parent_resource_relationships = Diffo.Provider.list_resource_relationships_from!(service_instance.id, load: [:target_type, :target_href, :characteristic])
      encoding = Jason.encode!(parent_resource_relationships)
      assert String.starts_with?(encoding, "[{")
      assert String.contains?(encoding, ~s(\"type\":\"isAssigned\"))
      assert String.contains?(encoding, ~s(\"resource\":{))
      assert String.contains?(encoding, ~s(\"id\":\"#{resource_instance.id}\"))
      assert String.contains?(encoding, ~s(\"href\":\"resourceInventoryManagement/v4/resource/can/#{resource_instance.id}\"))
      assert String.contains?(encoding, ~s(\"resourceRelationshipCharacteristic\":[{))
      assert String.contains?(encoding, ~s(\"name\":\"role\"))
      assert String.contains?(encoding, ~s(\"value\":\"primary\"))
      assert String.contains?(encoding, "\}]")
      assert String.ends_with?(encoding, "}]")
    end

    test "encode resource instance serviceRelationship json - success" do
      service_specification = Diffo.Provider.create_specification!(%{name: "adslAccess"})
      resource_specification = Diffo.Provider.create_specification!(%{name: "can", type: :resourceSpecification})
      service_instance = Diffo.Provider.create_instance!(%{specification_id: service_specification.id})
      resource_instance = Diffo.Provider.create_instance!(%{specification_id: resource_specification.id, type: :resource})
      _relationship = Diffo.Provider.create_relationship!(%{type: :assignedTo, source_id: resource_instance.id, target_id: service_instance.id})
      child_service_relationships = Diffo.Provider.list_service_relationships_from!(resource_instance.id, load: [:target_type, :target_href, :characteristic])
      encoding = Jason.encode!(child_service_relationships)
      assert String.starts_with?(encoding, "[{")
      assert String.contains?(encoding, ~s(\"type\":\"assignedTo\"))
      assert String.contains?(encoding, ~s(\"service\":{))
      assert String.contains?(encoding, ~s(\"id\":\"#{service_instance.id}\"))
      assert String.contains?(encoding, ~s(\"href\":\"serviceInventoryManagement/v4/service/adslAccess/#{service_instance.id}\"))
      assert String.ends_with?(encoding, "}]")
    end
  end

  describe "Diffo.Provider cleanup Relationships" do
    test "ensure there are no relationships" do
      for relationship <- Diffo.Provider.list_relationships!() do
        Diffo.Provider.delete_relationship!(%{id: relationship.id})
      end
      assert Diffo.Provider.list_relationships!() == []
    end

    test "ensure there are no instances" do
      for instance <- Diffo.Provider.list_instances!() do
        Diffo.Provider.delete_instance!(%{id: instance.id})
      end
      assert Diffo.Provider.list_instances!() == []
    end

    test "ensure there are no specifications" do
      for specification <- Diffo.Provider.list_specifications!() do
        Diffo.Provider.delete_specification!(%{id: specification.id})
      end
      assert Diffo.Provider.list_specifications!() == []
    end
  end
end
