defmodule Diffo.Provider.CharacteristicTest do
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

  describe "Diffo.Provider read Characteristics" do
    test "list characteristics - success" do
      Diffo.Provider.create_characteristic!(%{
        name: :port,
        value: "_not_null",
        type: :instance
      })

      Diffo.Provider.create_characteristic!(%{
        name: :circuit,
        value: "_not_null",
        type: :instance
      })

      Diffo.Provider.create_characteristic!(%{
        name: :type,
        value: :fraudHeavy,
        type: :feature
      })

      Diffo.Provider.create_characteristic!(%{
        name: :expiry,
        value: "20250131",
        type: :feature
      })

      characteristics = Diffo.Provider.list_characteristics!()
      assert length(characteristics) == 4
      # should be sorted by name
      assert List.first(characteristics).name == :circuit
      assert List.last(characteristics).name == :type
    end
  end

  describe "Diffo.Provider create Characteristics" do
    test "create reverse relationship characteristic value - success" do
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

      characteristic =
        Diffo.Provider.create_characteristic!(%{
          name: :port,
          value: "port13",
          type: :relationship
        })

      Diffo.Provider.create_relationship!(%{
          type: :usedBy,
          source_id: child_instance.id,
          target_id: parent_instance.id,
          characteristics: [characteristic.id]
        })

      assert characteristic.name == :port
      assert characteristic.value == "port13"
    end

    test "create forward and reverse characteristic with same name on same relationship - success" do
      specification = Diffo.Provider.create_specification!(%{name: "evc"})

      first_instance =
        Diffo.Provider.create_instance!(%{specified_by: specification.id, name: "first"})

      second_instance =
        Diffo.Provider.create_instance!(%{specified_by: specification.id, name: "second"})

      forward_characteristic =
        Diffo.Provider.create_characteristic!(%{
          name: :role,
          value: "worker",
          type: :relationship
        })

      reverse_characteristic =
        Diffo.Provider.create_characteristic!(%{
          name: :role,
          value: "protect",
          type: :relationship
        })

      _forward_relationship =
        Diffo.Provider.create_relationship!(%{
          type: :uses,
          source_id: first_instance.id,
          target_id: second_instance.id,
          characteristics: [forward_characteristic.id]
        })

      _reverse_relationship =
        Diffo.Provider.create_relationship!(%{
          type: :usedBy,
          source_id: second_instance.id,
          target_id: first_instance.id,
          characteristics: [reverse_characteristic.id]
        })
    end
  end

  describe "Diffo.Provider updated Characteristics" do
    test "update characteristic value - success" do
      parent_specification =
        Diffo.Provider.create_specification!(%{name: "can", type: :resourceSpecification})

      child_specification =
        Diffo.Provider.create_specification!(%{name: "cable", type: :resourceSpecification})

      parent_instance =
        Diffo.Provider.create_instance!(%{specified_by: parent_specification.id, type: :resource})

      child_instance =
        Diffo.Provider.create_instance!(%{specified_by: child_specification.id, type: :resource})

      characteristic =
        Diffo.Provider.create_characteristic!(%{
          name: :pair,
          value: "pair13",
          type: :relationship
        })

      _relationship =
        Diffo.Provider.create_relationship!(%{
          type: :usedBy,
          source_id: child_instance.id,
          target_id: parent_instance.id,
          characteristics: [characteristic.id]
        })

      updated_characteristic =
        characteristic |> Diffo.Provider.update_characteristic!(%{value: true})

      assert updated_characteristic.name == :pair
      assert updated_characteristic.value == true

      updated_characteristic =
        characteristic |> Diffo.Provider.update_characteristic!(%{value: "_not_null"})

      assert updated_characteristic.value == "_not_null"

      updated_characteristic =
        characteristic |> Diffo.Provider.update_characteristic!(%{value: nil})

      assert updated_characteristic.value == nil

      updated_characteristic =
        characteristic |> Diffo.Provider.update_characteristic!(%{value: ["one", "two"]})

      assert updated_characteristic.value == ["one", "two"]

      updated_characteristic =
        characteristic
        |> Diffo.Provider.update_characteristic!(%{value: %{aEnd: 1, zEnd: 13}})

      assert updated_characteristic.value == %{aEnd: 1, zEnd: 13}

      updated_characteristic =
        characteristic
        |> Diffo.Provider.update_characteristic!(%{value: %{"aEnd" => 1, "zEnd" => 13}})

      assert updated_characteristic.value == %{"aEnd" => 1, "zEnd" => 13}
    end
  end

  describe "Diffo.Provider encode Characteristics" do
    test "encode json - success" do
      characteristic =
        Diffo.Provider.create_characteristic!(%{
          name: :device,
          value: :managed,
          type: :instance
        })

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

    gen_result_outstanding_test(
      "port range value result, port5",
      @port_range,
      @port5,
      @range_only
    )
  end

  describe "Diffo.Provider delete Characteristics" do
    test "delete characteristic without related instance - success" do
      characteristic =
        Diffo.Provider.create_characteristic!(%{
          name: :device,
          value: :managed,
          type: :instance
        })

      :ok = Diffo.Provider.delete_characteristic(characteristic)
      {:error, _error} = Diffo.Provider.get_characteristic_by_id(characteristic.id)
    end

    @tag debug: true
    test "delete characteristic with related instance - failure" do
      specification = Diffo.Provider.create_specification!(%{name: "evc"})

      characteristic =
        Diffo.Provider.create_characteristic!(%{
          name: :device,
          value: :managed,
          type: :instance
        })

      instance =
        Diffo.Provider.create_instance!(%{
          specified_by: specification.id,
          characteristics: [characteristic.id]
        })

      {:error, error} = Diffo.Provider.delete_characteristic(characteristic)
      assert is_struct(error, Ash.Error.Invalid)

      # now unrelate the characteristic from the instance
      Diffo.Provider.unrelate_instance_characteristics!(instance, %{characteristics: [characteristic.id]})

      :ok = Diffo.Provider.delete_characteristic(characteristic)
      {:error, _error} = Diffo.Provider.get_characteristic_by_id(characteristic.id)
    end
  end
end
