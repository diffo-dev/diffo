defmodule Diffo.Provider.Instance_Test do
  @moduledoc false
  use ExUnit.Case
  use Diffo.DataCase, async: true

  describe "Diffo.Provider prepare Instances!" do
    test "check there are no instances" do
      assert Diffo.Provider.list_instances!() == []
    end
  end

  describe "Diffo.Provider read Instances!" do

    test "find instances by specification id" do
      specification = Diffo.Provider.create_specification!(%{name: "firewall"})
      Diffo.Provider.create_instance!(%{specification_id: specification.id})
      Diffo.Provider.create_instance!(%{specification_id: specification.id})
      Diffo.Provider.create_instance!(%{specification_id: specification.id})
      instances = Diffo.Provider.find_instances_by_specification_id!(specification.id)
      assert length(instances) == 3
    end

    test "find instances by name" do
      specification = Diffo.Provider.create_specification!(%{name: "intrusionMonitor"})
      Diffo.Provider.create_instance!(%{specification_id: specification.id, name: "Westfield Doncaster L1.M1"})
      Diffo.Provider.create_instance!(%{specification_id: specification.id, name: "Westfield Doncaster L2.M3"})
      Diffo.Provider.create_instance!(%{specification_id: specification.id, name: "Westfield Doncaster L2.M4"})
      instances = Diffo.Provider.find_instances_by_name!("Westfield Doncaster L2.M")
      assert length(instances) == 2
    end
  end

  describe "Diffo.Provider create Instances" do

    test "create a service instance - success" do
      specification = Diffo.Provider.create_specification!(%{name: "fibreAccess", description: "Fibre Access Service", category: "connectivity"})
      instance = Diffo.Provider.create_instance!(%{specification_id: specification.id})
      assert Diffo.Uuid.uuid4?(instance.id) == true
      assert instance.type == :service
      assert instance.service_state == :initial
      assert instance.service_operating_status == :unknown
      loaded_instance = Diffo.Provider.get_instance_by_id!(instance.id, load: [:href, :category, :description, :specification])
      assert loaded_instance.category == "connectivity"
      assert loaded_instance.description == "Fibre Access Service"
      assert loaded_instance.href == "serviceInventoryManagement/v4/service/fibreAccess/#{instance.id}"
      assert loaded_instance.specification.id == specification.id
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
      specification = Diffo.Provider.create_specification!(%{name: "hfcAccess", description: "HFC Access Service", category: "connectivity"})
      {:error, _specification} = Diffo.Provider.create_instance(%{specification_id: specification.id, type: :serviceSpecification})
    end

    # TODO this test is failing
    # test "create a service instance - failure - type mismatch with specification" do
    #   {:ok, specification} = Diffo.Provider.create_specification(%{name: "radioAccess", description: "Radio Access Service", category: "connectivity"})
    #   {:error, _specification} = Diffo.Provider.create_instance(%{specification_id: specification.id, type: :service})
    # end

  end

  describe "Diffo.Provider update Instances" do
    test "cancel an initial service instance - success" do
      transition_map = Diffo.Provider.Service.default_service_state_transition_map
      specification = Diffo.Provider.create_specification!(%{name: "initialCancel"})
        |> Diffo.Provider.set_specification_service_state_transition_map!(%{service_state_transition_map: transition_map})
      instance = Diffo.Provider.create_instance!(%{specification_id: specification.id})
      updated_instance = instance |> Diffo.Provider.cancel_instance!()
      assert updated_instance.service_state == :cancelled
      assert updated_instance.service_operating_status == :pending
    end

    test "activate an initial service instance - success" do
      transition_map = Diffo.Provider.Service.default_service_state_transition_map
      specification = Diffo.Provider.create_specification!(%{name: "initialActive"})
        |> Diffo.Provider.set_specification_service_state_transition_map!(%{service_state_transition_map: transition_map})
      updated_instance = Diffo.Provider.create_instance!(%{specification_id: specification.id})
        |> Diffo.Provider.activate_instance!()
      assert updated_instance.service_state == :active
      assert updated_instance.service_operating_status == :starting
    end

    test "terminate an active service instance - success" do
      transition_map = Diffo.Provider.Service.default_service_state_transition_map
      specification = Diffo.Provider.create_specification!(%{name: "activeTerminate"})
        |> Diffo.Provider.set_specification_service_state_transition_map!(%{service_state_transition_map: transition_map})
      updated_instance = Diffo.Provider.create_instance!(%{specification_id: specification.id})
        |> Diffo.Provider.activate_instance!() |> Diffo.Provider.terminate_instance!()
      assert updated_instance.service_state == :terminated
      assert updated_instance.service_operating_status == :stopping
    end

    test "transition an active service instance running - success" do
      transition_map = Diffo.Provider.Service.default_service_state_transition_map
      specification = Diffo.Provider.create_specification!(%{name: "activeRunning"})
        |> Diffo.Provider.set_specification_service_state_transition_map!(%{service_state_transition_map: transition_map})
      updated_instance = Diffo.Provider.create_instance!(%{specification_id: specification.id})
        |> Diffo.Provider.activate_instance!()
        |> Diffo.Provider.transition_instance!(%{service_operating_status: :running})
      assert updated_instance.service_state == :active
      assert updated_instance.service_operating_status == :running
    end

    # TODO this test is failing as when validator is called on transition_instance the new service_state isn't seen by the validator
    test "transition an active service instance suspended - success" do
      transition_map = Diffo.Provider.Service.default_service_state_transition_map
      specification = Diffo.Provider.create_specification!(%{name: "activeSuspended"})
        |> Diffo.Provider.set_specification_service_state_transition_map!(%{service_state_transition_map: transition_map})
      updated_instance = Diffo.Provider.create_instance!(%{specification_id: specification.id})
        |> Diffo.Provider.activate_instance!()
        |> Diffo.Provider.transition_instance!(%{service_state: :suspended, service_operating_status: :limited})
      assert updated_instance.service_state == :suspended
      assert updated_instance.service_operating_status == :limited
    end

    test "transition an initial service terminated - failure" do
      transition_map = Diffo.Provider.Service.default_service_state_transition_map
      specification = Diffo.Provider.create_specification!(%{name: "initialTerminated"})
        |> Diffo.Provider.set_specification_service_state_transition_map!(%{service_state_transition_map: transition_map})
      instance = Diffo.Provider.create_instance!(%{specification_id: specification.id})
      assert instance.service_state == :initial
      {:error, _error} = instance |> Diffo.Provider.transition_instance(%{service_state: :terminated})
    end

    test "update a service instance name - success" do
      specification = Diffo.Provider.create_specification!(%{name: "wifiAccess"})
      updated_instance = Diffo.Provider.create_instance!(%{specification_id: specification.id})
        |> Diffo.Provider.name_instance!(%{name: "Westfield Doncaster L2.E16"})
      assert updated_instance.name == "Westfield Doncaster L2.E16"
    end
  end

  describe "Diffo.Provider cleanup Instances" do
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
