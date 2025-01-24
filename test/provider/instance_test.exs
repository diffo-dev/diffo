defmodule Diffo.Provider.Instance_Test do
  @moduledoc false
  use ExUnit.Case
  require Ash.Query

  test "create a service instance - success" do
    {:ok, specification} = Diffo.Provider.create_specification(%{name: "fibreAccess", description: "Fibre Access Service", category: "connectivity"})
    {:ok, instance} = Diffo.Provider.create_instance(%{specification_id: specification.id})
    assert Diffo.Uuid.uuid4?(instance.id) == true
    assert instance.type == :service
    {:ok, loaded_instance} = Diffo.Provider.get_instance_by_id(instance.id, load: [:href, :category, :description, :specified_instance_type])
    assert loaded_instance.category == "connectivity"
    assert loaded_instance.description == "Fibre Access Service"
    assert loaded_instance.href == "serviceInventoryManagement/v4/service/fibreAccess/#{instance.id}"
    #assert loaded_instance.specified_instance.type == :service
  end

  #TODO fix this test, it is failing as specified_instance_type calculation is not loaded when create validation occurs
  #test "create a resource instance - success" do
  # {:ok, specification} = Diffo.Provider.create_specification(%{name: "copperPath", description: "Copper Path Resource", category: "physical", type: :resourceSpecification})
  #  {:ok, instance} = Diffo.Provider.create_instance(%{specification_id: specification.id, type: :resource})
  #  assert Diffo.Uuid.uuid4?(instance.id) == true
  #  assert instance.type == :resource
  #  {:ok, loaded_instance} = Diffo.Provider.get_instance_by_id(instance.id, load: [:href, :category, :description])
  #  assert loaded_instance.category == "physical"
  #  assert loaded_instance.description == "Copper Path Resource"
  #  assert loaded_instance.href == "resourceInventoryManagement/v4/resource/copperPath/#{instance.id}"
  #  assert loaded_instance.specified_instance.type == :resource
  #end

  test "create a service instance - failure - specification_id invalid" do
    {:error, _specification} = Diffo.Provider.create_instance(%{specification_id: UUID.uuid4()})
  end

  test "create a service instance - failure - type not correct" do
    {:ok, specification} = Diffo.Provider.create_specification(%{name: "hfcAccess", description: "HFC Access Service", category: "connectivity"})
    {:error, _specification} = Diffo.Provider.create_instance(%{specification_id: specification.id, type: :serviceSpecification})
  end

 # TODO this test is failing
 # test "create a service instance - failure - type mismatch with specification" do
 #   {:ok, specification} = Diffo.Provider.create_specification(%{name: "radioAccess", description: "Radio Access Service", category: "connectivity"})
 #   {:error, _specification} = Diffo.Provider.create_instance(%{specification_id: specification.id, type: :service})
 # end
end
