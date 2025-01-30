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
      Diffo.Provider.create_relationship!(%{type: :refersTo, reverse_type: :refersTo, source_id: evpl1.id, target_id: evpl2.id})
      Diffo.Provider.create_relationship!(%{type: :refersTo, reverse_type: :refersTo, source_id: evpl1.id, target_id: evpl3.id})
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
      Diffo.Provider.create_relationship!(%{type: :connectedTo, reverse_type: :connectedFrom, source_id: cable1.id, target_id: cable2.id})
      Diffo.Provider.create_relationship!(%{type: :connectedTo, reverse_type: :connectedFrom, source_id: cable2.id, target_id: cable3.id})
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
      source = Diffo.Provider.create_instance!(%{specification_id: specification.id, name: "evpl1"})
      target = Diffo.Provider.create_instance!(%{specification_id: specification.id, name: "evpl2"})
      relationship = Diffo.Provider.create_relationship!(%{type: :refersTo, reverse_type: :refersTo, source_id: source.id, target_id: target.id})
      loaded_relationship = Diffo.Provider.get_relationship_by_id!(relationship.id, load: [:source_type, :target_type, :source_href, :target_href])
      assert loaded_relationship.source_type == :service
      assert loaded_relationship.target_type == :service
      assert loaded_relationship.source_href == "serviceInventoryManagement/v4/service/accessEvc/#{source.id}"
      assert loaded_relationship.target_href == "serviceInventoryManagement/v4/service/accessEvc/#{target.id}"
    end

    test "create a mutual connects resource relationship - success" do
      resource_specification = Diffo.Provider.create_specification!(%{name: "cable", type: :resourceSpecification})
      source_instance = Diffo.Provider.create_instance!(%{specification_id: resource_specification.id, type: :resource})
      target_instance = Diffo.Provider.create_instance!(%{specification_id: resource_specification.id, type: :resource})
      relationship = Diffo.Provider.create_relationship!(%{type: :connectedTo, reverse_type: :connectedFrom, source_id: source_instance.id, target_id: target_instance.id})
      loaded_relationship = Diffo.Provider.get_relationship_by_id!(relationship.id, load: [:source_type, :target_type, :source_href, :target_href])
      assert loaded_relationship.source_type == :resource
      assert loaded_relationship.target_type == :resource
      assert loaded_relationship.source_href == "resourceInventoryManagement/v4/resource/cable/#{source_instance.id}"
      assert loaded_relationship.target_href == "resourceInventoryManagement/v4/resource/cable/#{target_instance.id}"
    end

    test "create a service - resource relationship - success" do
      service_specification = Diffo.Provider.create_specification!(%{name: "adslAccess"})
      resource_specification = Diffo.Provider.create_specification!(%{name: "can", type: :resourceSpecification})
      service_instance = Diffo.Provider.create_instance!(%{specification_id: service_specification.id})
      resource_instance = Diffo.Provider.create_instance!(%{specification_id: resource_specification.id, type: :resource})
      relationship = Diffo.Provider.create_relationship!(%{type: :isAssigned, reverse_type: :assignedTo, source_id: service_instance.id, target_id: resource_instance.id})
      loaded_relationship = Diffo.Provider.get_relationship_by_id!(relationship.id, load: [:source_type, :target_type, :source_href, :target_href])
      assert loaded_relationship.source_type == :service
      assert loaded_relationship.target_type == :resource
      assert loaded_relationship.source_href == "serviceInventoryManagement/v4/service/adslAccess/#{service_instance.id}"
      assert loaded_relationship.target_href == "resourceInventoryManagement/v4/resource/can/#{resource_instance.id}"
    end

  end

  describe "Diffo.Provider updated Relationships" do
    # create a 'reverse' partial resource assignment to a resource, usedBy, then add 'forward relationship' uses
    test "add forward relationship - success" do
      parent_specification = Diffo.Provider.create_specification!(%{name: "can", type: :resourceSpecification})
      child_specification = Diffo.Provider.create_specification!(%{name: "dslamLineCard", type: :resourceSpecification})
      parent_instance = Diffo.Provider.create_instance!(%{specification_id: parent_specification.id, type: :resource})
      child_instance = Diffo.Provider.create_instance!(%{specification_id: child_specification.id, type: :resource})
      relationship = Diffo.Provider.create_relationship!(%{reverse_type: :usedBy, source_id: parent_instance.id, target_id: child_instance.id})
      updated_relationship = relationship |> Diffo.Provider.update_relationship!(%{type: :uses, alias: :port})
      assert updated_relationship.type == :uses
      assert updated_relationship.reverse_type == :usedBy
      assert updated_relationship.alias == :port
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
