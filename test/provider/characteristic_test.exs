defmodule Diffo.Provider.Characteristic_Test do
  @moduledoc false
  use ExUnit.Case
  use Diffo.DataCase, async: true


  describe "Diffo.Provider prepare Characteristics" do
    test "check there are no characteristics" do
      assert Diffo.Provider.list_characteristics!() == []
    end
  end

  describe "Diffo.Provider read Characteristics" do
    test "list service characteristics from - success" do
      broadband_specification = Diffo.Provider.create_specification!(%{name: "broadband"})
      dnsRecord_specification = Diffo.Provider.create_specification!(%{name: "dnsRecord", type: :resourceSpecification})
      broadband_instance = Diffo.Provider.create_instance!(%{specification_id: broadband_specification.id})
      dnsRecord_instance = Diffo.Provider.create_instance!(%{specification_id: dnsRecord_specification.id, type: :resource})
      relationship = Diffo.Provider.create_relationship!(%{type: :dependency_on, source_id: broadband_instance.id, target_id: dnsRecord_instance.id})
      Diffo.Provider.create_characteristic!(%{relationship_id: relationship.id, name: :static, value: "true", type: :forward_relationship})
      Diffo.Provider.create_characteristic!(%{relationship_id: relationship.id, name: :publish, value: "true", type: :forward_relationship})
      forward_characteristics = Diffo.Provider.list_characteristics_by_relationship_id!(relationship.id, :forward_relationship)
      assert length(forward_characteristics) == 2
      assert Diffo.Provider.list_characteristics_by_relationship_id!(relationship.id, :reverse_relationship) == []
    end
  end

  describe "Diffo.Provider create Characteristics" do
    test "create reverse relationship characteristic value - success" do
      parent_specification = Diffo.Provider.create_specification!(%{name: "can", type: :resourceSpecification})
      child_specification = Diffo.Provider.create_specification!(%{name: "dslamLineCard", type: :resourceSpecification})
      parent_instance = Diffo.Provider.create_instance!(%{specification_id: parent_specification.id, type: :resource})
      child_instance = Diffo.Provider.create_instance!(%{specification_id: child_specification.id, type: :resource})
      relationship = Diffo.Provider.create_relationship!(%{alias: :port, type: :uses, reverse_type: :usedBy, source_id: parent_instance.id, target_id: child_instance.id})
      characteristic = Diffo.Provider.create_characteristic!(%{name: :port, value: "port13", relationship_id: relationship.id, type: :reverse_relationship})
      assert characteristic.name == :port
      assert characteristic.value == "port13"
    end

    test "create forward and reverse characteristic with same name on same relationship - success" do
      specification = Diffo.Provider.create_specification!(%{name: "evc"})
      first_instance = Diffo.Provider.create_instance!(%{specification_id: specification.id, name: "first"})
      second_instance = Diffo.Provider.create_instance!(%{specification_id: specification.id, name: "second"})
      relationship = Diffo.Provider.create_relationship!(%{type: :uses, reverse_type: :usedBy, source_id: first_instance.id, target_id: second_instance.id})
      _forward_characteristic = Diffo.Provider.create_characteristic!(%{name: :role, value: "worker", relationship_id: relationship.id, type: :forward_relationship})
      _reverse_characteristic = Diffo.Provider.create_characteristic!(%{name: :role, value: "protect", relationship_id: relationship.id, type: :reverse_relationship})
      assert length(Diffo.Provider.list_characteristics_by_relationship_id!(relationship.id, :forward_relationship)) == 1
      assert length(Diffo.Provider.list_characteristics_by_relationship_id!(relationship.id, :reverse_relationship)) == 1
    end

    test "create duplicate characteristic on same relationship - failure" do
      specification = Diffo.Provider.create_specification!(%{name: "evc"})
      first_instance = Diffo.Provider.create_instance!(%{specification_id: specification.id, name: "first"})
      second_instance = Diffo.Provider.create_instance!(%{specification_id: specification.id, name: "second"})
      relationship = Diffo.Provider.create_relationship!(%{type: :uses, reverse_type: :usedBy, source_id: first_instance.id, target_id: second_instance.id})
      _first_characteristic = Diffo.Provider.create_characteristic!(%{name: :role, value: "worker", relationship_id: relationship.id, type: :forward_relationship})
      {:error, _error} = Diffo.Provider.create_characteristic(%{name: :role, value: "worker", relationship_id: relationship.id, type: :forward_relationship})
    end
  end

  describe "Diffo.Provider updated Characteristics" do
    test "update characteristic value - success" do
      parent_specification = Diffo.Provider.create_specification!(%{name: "can", type: :resourceSpecification})
      child_specification = Diffo.Provider.create_specification!(%{name: "cable", type: :resourceSpecification})
      parent_instance = Diffo.Provider.create_instance!(%{specification_id: parent_specification.id, type: :resource})
      child_instance = Diffo.Provider.create_instance!(%{specification_id: child_specification.id, type: :resource})
      relationship = Diffo.Provider.create_relationship!(%{alias: :port, type: :uses, reverse_type: :usedBy, source_id: parent_instance.id, target_id: child_instance.id})
      characteristic = Diffo.Provider.create_characteristic!(%{name: :pair, value: "pair13", relationship_id: relationship.id, type: :reverse_relationship})
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

  describe "Diffo.Provider cleanup Characteristics" do
    test "ensure there are no characteristics" do
      for characteristic <- Diffo.Provider.list_characteristics!() do
        Diffo.Provider.delete_characteristic!(%{id: characteristic.id})
      end
      assert Diffo.Provider.list_characteristics!() == []
    end

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
