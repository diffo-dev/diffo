defmodule Diffo.Provider.CharacteristicTest do
  @moduledoc false
  use ExUnit.Case

  describe "Diffo.Provider read Characteristics" do
    test "list characteristics - success" do
      specification = Diffo.Provider.create_specification!(%{name: "broadband"})
      instance = Diffo.Provider.create_instance!(%{specification_id: specification.id})
      Diffo.Provider.create_characteristic!(%{instance_id: instance.id, name: :port, value: "_not_null", type: :instance})
      Diffo.Provider.create_characteristic!(%{instance_id: instance.id, name: :circuit, value: "_not_null", type: :instance})
      feature = Diffo.Provider.create_feature!(%{instance_id: instance.id, name: :restriction})
      Diffo.Provider.create_characteristic!(%{feature_id: feature.id, name: :type, value: :fraudHeavy, type: :feature})
      Diffo.Provider.create_characteristic!(%{feature_id: feature.id, name: :expiry, value: "20250131", type: :feature})
      characteristics = Diffo.Provider.list_characteristics!()
      assert length(characteristics) == 4
      # should be sorted by name
      assert List.first(characteristics).name == :circuit
      assert List.last(characteristics).name == :type
    end

    test "list feature characteristics - success" do
      specification = Diffo.Provider.create_specification!(%{name: "broadband"})
      instance = Diffo.Provider.create_instance!(%{specification_id: specification.id})
      feature = Diffo.Provider.create_feature!(%{instance_id: instance.id, name: :restriction})
      Diffo.Provider.create_characteristic!(%{feature_id: feature.id, name: :type, value: :fraudHeavy, type: :feature})
      Diffo.Provider.create_characteristic!(%{feature_id: feature.id, name: :expiry, value: "20250131", type: :feature})
      feature_characteristics = Diffo.Provider.list_characteristics_by_related_id!(feature.id, :feature)
      assert length(feature_characteristics) == 2
      # should be sorted
      assert List.first(feature_characteristics).name == :expiry
      assert List.last(feature_characteristics).name == :type
    end

    test "list instance characteristics - success" do
      specification = Diffo.Provider.create_specification!(%{name: "broadband"})
      instance = Diffo.Provider.create_instance!(%{specification_id: specification.id})
      Diffo.Provider.create_characteristic!(%{instance_id: instance.id, name: :port, value: "_not_null", type: :instance})
      Diffo.Provider.create_characteristic!(%{instance_id: instance.id, name: :circuit, value: "_not_null", type: :instance})
      instance_characteristics = Diffo.Provider.list_characteristics_by_related_id!(instance.id, :instance)
      assert length(instance_characteristics) == 2
    end

    test "list relationship characteristics - success" do
      broadband_specification = Diffo.Provider.create_specification!(%{name: "broadband"})
      dnsRecord_specification = Diffo.Provider.create_specification!(%{name: "dnsRecord", type: :resourceSpecification})
      broadband_instance = Diffo.Provider.create_instance!(%{specification_id: broadband_specification.id})
      dnsRecord_instance = Diffo.Provider.create_instance!(%{specification_id: dnsRecord_specification.id, type: :resource})
      relationship = Diffo.Provider.create_relationship!(%{type: :dependency_on, source_id: broadband_instance.id, target_id: dnsRecord_instance.id})
      Diffo.Provider.create_characteristic!(%{relationship_id: relationship.id, name: :static, value: "true", type: :relationship})
      Diffo.Provider.create_characteristic!(%{relationship_id: relationship.id, name: :publish, value: "true", type: :relationship})
      forward_characteristics = Diffo.Provider.list_characteristics_by_related_id!(relationship.id, :relationship)
      assert length(forward_characteristics) == 2
    end
  end

  describe "Diffo.Provider create Characteristics" do
    test "create reverse relationship characteristic value - success" do
      parent_specification = Diffo.Provider.create_specification!(%{name: "can", type: :resourceSpecification})
      child_specification = Diffo.Provider.create_specification!(%{name: "dslamLineCard", type: :resourceSpecification})
      parent_instance = Diffo.Provider.create_instance!(%{specification_id: parent_specification.id, type: :resource})
      child_instance = Diffo.Provider.create_instance!(%{specification_id: child_specification.id, type: :resource})
      relationship = Diffo.Provider.create_relationship!(%{type: :usedBy, source_id: child_instance.id, target_id: parent_instance.id})
      characteristic = Diffo.Provider.create_characteristic!(%{name: :port, value: "port13", relationship_id: relationship.id, type: :relationship})
      assert characteristic.name == :port
      assert characteristic.value == "port13"
    end

    test "create forward and reverse characteristic with same name on same relationship - success" do
      specification = Diffo.Provider.create_specification!(%{name: "evc"})
      first_instance = Diffo.Provider.create_instance!(%{specification_id: specification.id, name: "first"})
      second_instance = Diffo.Provider.create_instance!(%{specification_id: specification.id, name: "second"})
      forward_relationship = Diffo.Provider.create_relationship!(%{type: :uses, source_id: first_instance.id, target_id: second_instance.id})
      reverse_relationship = Diffo.Provider.create_relationship!(%{type: :usedBy, source_id: second_instance.id, target_id: first_instance.id})
      _forward_characteristic = Diffo.Provider.create_characteristic!(%{name: :role, value: "worker", relationship_id: forward_relationship.id, type: :relationship})
      _reverse_characteristic = Diffo.Provider.create_characteristic!(%{name: :role, value: "protect", relationship_id: reverse_relationship.id, type: :relationship})
      assert length(Diffo.Provider.list_characteristics_by_related_id!(forward_relationship.id, :relationship)) == 1
      assert length(Diffo.Provider.list_characteristics_by_related_id!(reverse_relationship.id, :relationship)) == 1
    end

    test "create duplicate characteristic on same feature - failure" do
      specification = Diffo.Provider.create_specification!(%{name: "evc"})
      instance = Diffo.Provider.create_instance!(%{specification_id: specification.id})
      feature = Diffo.Provider.create_feature!(%{instance_id: instance.id, name: :restriction})
      _first_characteristic = Diffo.Provider.create_characteristic!(%{feature_id: feature.id, name: :type, value: :fraudHeavy, type: :feature})
      {:error, _error} = Diffo.Provider.create_characteristic(%{feature_id: feature.id, name: :type, value: :fraudHeavy, type: :feature})
    end

    test "create duplicate characteristic on same instance - failure" do
      specification = Diffo.Provider.create_specification!(%{name: "evc"})
      instance = Diffo.Provider.create_instance!(%{specification_id: specification.id})
      _first_characteristic = Diffo.Provider.create_characteristic!(%{name: :port, value: "_not_null", instance_id: instance.id, type: :instance})
      {:error, _error} = Diffo.Provider.create_characteristic(%{name: :port, value: "_not_null", instance_id: instance.id, type: :instance})
    end

    test "create duplicate characteristic on same relationship - failure" do
      specification = Diffo.Provider.create_specification!(%{name: "evc"})
      first_instance = Diffo.Provider.create_instance!(%{specification_id: specification.id, name: "first"})
      second_instance = Diffo.Provider.create_instance!(%{specification_id: specification.id, name: "second"})
      relationship = Diffo.Provider.create_relationship!(%{type: :uses, source_id: first_instance.id, target_id: second_instance.id})
      _first_characteristic = Diffo.Provider.create_characteristic!(%{name: :role, value: "worker", relationship_id: relationship.id, type: :relationship})
      {:error, _error} = Diffo.Provider.create_characteristic(%{name: :role, value: "worker", relationship_id: relationship.id, type: :relationship})
    end
  end

  describe "Diffo.Provider updated Characteristics" do
    test "update characteristic value - success" do
      parent_specification = Diffo.Provider.create_specification!(%{name: "can", type: :resourceSpecification})
      child_specification = Diffo.Provider.create_specification!(%{name: "cable", type: :resourceSpecification})
      parent_instance = Diffo.Provider.create_instance!(%{specification_id: parent_specification.id, type: :resource})
      child_instance = Diffo.Provider.create_instance!(%{specification_id: child_specification.id, type: :resource})
      relationship = Diffo.Provider.create_relationship!(%{type: :usedBy, source_id: child_instance.id, target_id: parent_instance.id})
      characteristic = Diffo.Provider.create_characteristic!(%{name: :pair, value: "pair13", relationship_id: relationship.id, type: :relationship})
      updated_characteristic = characteristic |> Diffo.Provider.update_characteristic!(%{value: true})
      assert updated_characteristic.name == :pair
      assert updated_characteristic.value == true
      updated_characteristic = characteristic |> Diffo.Provider.update_characteristic!(%{value: "_not_null"})
      assert updated_characteristic.value == "_not_null"
      updated_characteristic = characteristic |> Diffo.Provider.update_characteristic!(%{value: nil})
      assert updated_characteristic.value == nil
      updated_characteristic = characteristic |> Diffo.Provider.update_characteristic!(%{value: ["one", "two"]})
      assert updated_characteristic.value == ["one", "two"]
      updated_characteristic = characteristic |> Diffo.Provider.update_characteristic!(%{value: %{"aEnd" => 1, "zEnd" => 13}})
      assert updated_characteristic.value == %{"aEnd" => 1, "zEnd" => 13}
    end
  end

  describe "Diffo.Provider encode Characteristics" do
    test "encode json - success" do
      specification = Diffo.Provider.create_specification!(%{name: "siteConnection"})
      instance = Diffo.Provider.create_instance!(%{specification_id: specification.id})
      characteristic = Diffo.Provider.create_characteristic!(%{instance_id: instance.id, name: :device, value: :managed, type: :instance})
      encoding = Jason.encode!(characteristic)
      assert encoding == "{\"name\":\"device\",\"value\":\"managed\"}"
    end
  end

  describe "Diffo.Provider outstanding Characteristics" do
    use Outstand
    @port1 %Diffo.Provider.Characteristic{name: "port", value: 1}
    @port3 %Diffo.Provider.Characteristic{name: "port", value: 3}
    @port5 %Diffo.Provider.Characteristic{name: "port", value: 5}
    @pair1 %Diffo.Provider.Characteristic{name: "pair", value: 1}
    @name_only %Diffo.Provider.Characteristic{name: "port"}
    @value_only %Diffo.Provider.Characteristic{value: 1}
    @range_only %Diffo.Provider.Characteristic{value: 1..4}
    @port_range %Diffo.Provider.Characteristic{name: "port", value: 1..4}


    gen_nothing_outstanding_test("specific nothing outstanding", @port1, @port1)
    gen_result_outstanding_test("specific name and value result", @port1, nil, @port1)
    gen_result_outstanding_test("specific name result", @port1, @pair1, @name_only)
    gen_result_outstanding_test("specific value result", @port1, @port3, @value_only)

    gen_nothing_outstanding_test("port range nothing outstanding, port1", @port_range, @port1)
    gen_nothing_outstanding_test("port range nothing outstanding, port3", @port_range, @port3)
    gen_result_outstanding_test("port range name result, pair1", @port_range, @pair1, @name_only)
    gen_result_outstanding_test("port range value result, port5", @port_range, @port5, @range_only)
  end

  describe "Diffo.Provider delete Characteristics" do
    test "delete characteristic with related instance - success" do
      specification = Diffo.Provider.create_specification!(%{name: "siteConnection"})
      instance = Diffo.Provider.create_instance!(%{specification_id: specification.id})
      characteristic = Diffo.Provider.create_characteristic!(%{instance_id: instance.id, name: :device, value: :managed, type: :instance})
      :ok = Diffo.Provider.delete_characteristic(characteristic)
      {:error, _error} = Diffo.Provider.get_characteristic_by_id(characteristic.id)
    end
  end
end
