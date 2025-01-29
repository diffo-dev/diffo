defmodule Diffo.Provider.Relationship_Test do
  @moduledoc false
  use ExUnit.Case
  use Diffo.DataCase, async: true

  describe "Diffo.Provider prepare Relationships" do
    test "check there are no relationships" do
      assert Diffo.Provider.list_relationships!() == []
    end
  end

  describe "Diffo.Provider create Relationships" do
    test "create a mutual peer service relationship" do
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

    test "create a service - resource relationship" do
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

  describe "Diffo.Provider read Relationships" do
    #todo find all relationships, find all related resources/services, find by forward/reverse relationship type, find forward by alias
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
