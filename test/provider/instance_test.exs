defmodule Diffo.Provider.Instance_Test do
  @moduledoc false
  use ExUnit.Case
  require Ash.Query

  test "create a service instance - success" do
    {:ok, specification} = Diffo.Provider.create_specification(%{name: "fibreAccess", description: "Fibre Access Service", category: "connectivity"})
    {:ok, instance} = Diffo.Provider.create_instance(%{specification_id: specification.id})
    assert Diffo.Uuid.uuid4?(instance.id) == true
    assert instance.type == :service
    #assert instance.service_state == :initial
    #assert instance.service_operating_status == :pending
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

  test "cancel an initial service instance - success" do
    {:ok, specification} = Diffo.Provider.create_specification(%{name: "initialCancel"})
    {:ok, instance} = Diffo.Provider.create_instance(%{specification_id: specification.id})
    {:ok, updated_instance} = instance |> Diffo.Provider.cancel_instance()
    assert updated_instance.service_state == :cancelled
    assert updated_instance.service_operating_status == :pending
  end

  test "activate an initial service instance - success" do
    {:ok, specification} = Diffo.Provider.create_specification(%{name: "initialActive"})
    {:ok, instance} = Diffo.Provider.create_instance(%{specification_id: specification.id})
    {:ok, updated_instance} = instance |> Diffo.Provider.activate_instance()
    assert updated_instance.service_state == :active
    assert updated_instance.service_operating_status == :starting
  end

  test "terminate an active service instance - success" do
    {:ok, specification} = Diffo.Provider.create_specification(%{name: "activeTerminate"})
    {:ok, instance} = Diffo.Provider.create_instance(%{specification_id: specification.id})
    {:ok, updated_instance} = instance |> Diffo.Provider.activate_instance!() |> Diffo.Provider.terminate_instance()
    assert updated_instance.service_state == :terminated
    assert updated_instance.service_operating_status == :stopping
  end

  test "transition an active service instance running - success" do
    {:ok, specification} = Diffo.Provider.create_specification(%{name: "activeRunning"})
    {:ok, instance} = Diffo.Provider.create_instance(%{specification_id: specification.id})
    {:ok, updated_instance} = instance |> Diffo.Provider.activate_instance!()
      |> Diffo.Provider.transition_instance(%{service_operating_status: :running})
    assert updated_instance.service_state == :active
    assert updated_instance.service_operating_status == :running
  end

  test "transition an active service instance suspended - success" do
    {:ok, specification} = Diffo.Provider.create_specification(%{name: "activeSuspended"})
    {:ok, instance} = Diffo.Provider.create_instance(%{specification_id: specification.id})
    {:ok, updated_instance} = instance |> Diffo.Provider.activate_instance!()
      |> Diffo.Provider.transition_instance(%{service_state: :suspended, service_operating_status: :limited})
    assert updated_instance.service_state == :suspended
    assert updated_instance.service_operating_status == :limited
  end

  test "transition an initial service terminated - failure" do
    {:ok, specification} = Diffo.Provider.create_specification(%{name: "initialTerminated"})
    {:ok, instance} = Diffo.Provider.create_instance(%{specification_id: specification.id})
    assert instance.service_state == :initial
    {:error, _error} = instance |> Diffo.Provider.transition_instance(%{service_state: :terminated})
  end

  test "update a service instance name - success" do
    {:ok, specification} = Diffo.Provider.create_specification(%{name: "wifiAccess"})
    {:ok, instance} = Diffo.Provider.create_instance(%{specification_id: specification.id})
    {:ok, updated_instance} = instance |> Diffo.Provider.name_instance(%{name: "Westfield Doncaster L2.E16"})
    assert updated_instance.name == "Westfield Doncaster L2.E16"
  end

  test "list instances by specification id" do
    {:ok, specification} = Diffo.Provider.create_specification(%{name: "firewall"})
    {:ok, _i1} = Diffo.Provider.create_instance(%{specification_id: specification.id})
    {:ok, _i2} = Diffo.Provider.create_instance(%{specification_id: specification.id})
    {:ok, _i3} = Diffo.Provider.create_instance(%{specification_id: specification.id})
    {:ok, instances} = Diffo.Provider.list_instances_by_specification_id(specification.id)
    assert length(instances) == 3
  end

  test "find instances by name" do
    {:ok, specification} = Diffo.Provider.create_specification(%{name: "intrusionMonitor"})
    {:ok, _i1} = Diffo.Provider.create_instance(%{specification_id: specification.id, name: "Westfield Doncaster L1.M1"})
    {:ok, _i2} = Diffo.Provider.create_instance(%{specification_id: specification.id, name: "Westfield Doncaster L2.M3"})
    {:ok, _i3} = Diffo.Provider.create_instance(%{specification_id: specification.id, name: "Westfield Doncaster L2.M4"})
    {:ok, instances} = Diffo.Provider.find_instances_by_name("Westfield Doncaster L2.M")
    assert length(instances) == 2
  end
end
