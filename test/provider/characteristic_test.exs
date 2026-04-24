# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.CharacteristicTest do
  @moduledoc false
  use ExUnit.Case
  alias Diffo.Test.Patch
  alias Diffo.Type.Value

  setup_all do
    AshNeo4j.BoltyHelper.start()
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
        value: Value.primitive("string", "_not_null"),
        type: :instance
      })

      Diffo.Provider.create_characteristic!(%{
        name: :circuit,
        value: Value.primitive("string", "_not_null"),
        type: :instance
      })

      Diffo.Provider.create_characteristic!(%{
        name: :type,
        value: Value.primitive("string", "fraudHeavy"),
        type: :feature
      })

      Diffo.Provider.create_characteristic!(%{
        name: :expiry,
        value: Value.primitive("date", ~D[2026-04-16]),
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
          value: Value.primitive("string", "port13"),
          type: :relationship
        })

      Diffo.Provider.create_relationship!(%{
        type: :usedBy,
        source_id: child_instance.id,
        target_id: parent_instance.id,
        characteristics: [characteristic.id]
      })

      assert characteristic.name == :port
      assert Diffo.Unwrap.unwrap(characteristic.value) == "port13"
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
          value: Value.primitive("string", "worker"),
          type: :relationship
        })

      reverse_characteristic =
        Diffo.Provider.create_characteristic!(%{
          name: :role,
          value: Value.primitive("string", "protect"),
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

  describe "Diffo.Provider update Characteristics" do
    @tag :debug
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
          value: Value.primitive("string", "pair13"),
          type: :relationship
        })

      _relationship =
        Diffo.Provider.create_relationship!(%{
          type: :usedBy,
          source_id: child_instance.id,
          target_id: parent_instance.id,
          characteristics: [characteristic.id]
        })

      # boolean
      updated_characteristic =
        characteristic
        |> Diffo.Provider.update_characteristic!(%{
          value: Value.primitive("boolean", false)
        })

      # we expect the value false here
      assert Diffo.Unwrap.unwrap(updated_characteristic.value) == false

      # string
      updated_characteristic =
        characteristic
        |> Diffo.Provider.update_characteristic!(%{value: Value.primitive("string", "_not_null")})

      assert Diffo.Unwrap.unwrap(updated_characteristic.value) == "_not_null"

      # integer
      updated_characteristic =
        characteristic
        |> Diffo.Provider.update_characteristic!(%{value: Value.primitive("integer", 1)})

      assert Diffo.Unwrap.unwrap(updated_characteristic.value) == 1

      # float
      updated_characteristic =
        characteristic
        |> Diffo.Provider.update_characteristic!(%{value: Value.primitive("float", 1.2)})

      assert Diffo.Unwrap.unwrap(updated_characteristic.value) == 1.2

      # nil (shouldn't need to unwrap nil)
      updated_characteristic =
        characteristic |> Diffo.Provider.update_characteristic!(%{value: nil})

      assert Diffo.Unwrap.unwrap(updated_characteristic.value) == nil

      # dynamic
      updated_characteristic =
        characteristic
        |> Diffo.Provider.update_characteristic!(%{
          value: Value.dynamic(%Patch{aEnd: 1, zEnd: 42})
        })

      assert Diffo.Unwrap.unwrap(updated_characteristic.value) == %Patch{aEnd: 1, zEnd: 42}
    end
  end

  describe "Diffo.Provider create array Characteristics" do
    test "create characteristic with values - success" do
      characteristic =
        Diffo.Provider.create_characteristic!(%{
          name: :ports,
          values: [
            Value.primitive("integer", 1),
            Value.primitive("integer", 2),
            Value.primitive("integer", 3)
          ],
          is_array: true,
          type: :instance
        })

      assert characteristic.is_array == true
      assert Diffo.Unwrap.unwrap(characteristic) == [1, 2, 3]
    end

    test "create characteristic with both value and values - failure" do
      assert {:error, _} =
               Diffo.Provider.create_characteristic(%{
                 name: :bad,
                 value: Value.primitive("string", "x"),
                 values: [Value.primitive("string", "y")],
                 type: :instance
               })
    end
  end

  describe "Diffo.Provider update array Characteristics" do
    test "update value characteristic to values (morphing) - success" do
      characteristic =
        Diffo.Provider.create_characteristic!(%{
          name: :ports,
          value: Value.primitive("integer", 1),
          type: :instance
        })

      updated =
        Diffo.Provider.update_characteristic!(characteristic, %{
          value: nil,
          values: [
            Value.primitive("integer", 1),
            Value.primitive("integer", 2)
          ],
          is_array: true
        })

      assert updated.is_array == true
      assert Diffo.Unwrap.unwrap(updated) == [1, 2]
    end

    test "update values characteristic back to value (shrinking) - success" do
      characteristic =
        Diffo.Provider.create_characteristic!(%{
          name: :ports,
          values: [Value.primitive("integer", 1), Value.primitive("integer", 2)],
          is_array: true,
          type: :instance
        })

      updated =
        Diffo.Provider.update_characteristic!(characteristic, %{
          values: nil,
          value: Value.primitive("integer", 1),
          is_array: false
        })

      assert updated.is_array == false
      assert Diffo.Unwrap.unwrap(updated) == 1
    end
  end

  describe "Diffo.Provider encode Characteristics" do
    test "encode json value - success" do
      characteristic =
        Diffo.Provider.create_characteristic!(%{
          name: :device,
          value: Value.primitive("string", "managed"),
          type: :instance
        })

      encoding = Jason.encode!(characteristic)
      assert encoding == "{\"name\":\"device\",\"value\":\"managed\"}"
    end

    test "encode json values - success" do
      characteristic =
        Diffo.Provider.create_characteristic!(%{
          name: :ports,
          values: [Value.primitive("integer", 1), Value.primitive("integer", 2)],
          is_array: true,
          type: :instance
        })

      encoding = Jason.encode!(characteristic)
      assert encoding == "{\"name\":\"ports\",\"values\":[1,2]}"
    end
  end

  describe "Diffo.Provider outstanding Characteristics" do
    use Outstand
    @port1 %Diffo.Provider.Characteristic{name: "port", value: Value.primitive("integer", 1)}
    @port3 %Diffo.Provider.Characteristic{name: "port", value: Value.primitive("integer", 3)}
    # @port5 %Diffo.Provider.Characteristic{name: "port", value: Value.primitive("integer", 5)}
    @pair1 %Diffo.Provider.Characteristic{name: "pair", value: Value.primitive("integer", 1)}
    @name_only %Diffo.Provider.Characteristic{name: "port"}
    # map only
    @value_only %Diffo.Provider.Characteristic{value: %{value: 1}}
    # @range_only %Diffo.Provider.Characteristic{value: 1..4}
    # @port_range %Diffo.Provider.Characteristic{name: "port", value: 1..4}

    gen_nothing_outstanding_test("specific nothing outstanding", @port1, @port1)

    gen_result_outstanding_test(
      "specific name and value result",
      @port1,
      nil,
      Ash.Test.strip_metadata(@port1)
    )

    gen_result_outstanding_test(
      "specific name result",
      @port1,
      @pair1,
      Ash.Test.strip_metadata(@name_only)
    )

    gen_result_outstanding_test(
      "specific value result",
      @port1,
      @port3,
      Ash.Test.strip_metadata(@value_only)
    )

    # gen_nothing_outstanding_test("port range nothing outstanding, port1", @port_range, @port1)
    # gen_nothing_outstanding_test("port range nothing outstanding, port3", @port_range, @port3)

    # gen_result_outstanding_test(
    #  "port range name result, pair1",
    #  @port_range,
    #  @pair1,
    #  Ash.Test.strip_metadata(@name_only)
    # )

    # gen_result_outstanding_test(
    #  "port range value result, port5",
    #  @port_range,
    #  @port5,
    #  Ash.Test.strip_metadata(@range_only)
    # )
  end

  describe "Diffo.Provider delete Characteristics" do
    test "delete characteristic without related instance - success" do
      characteristic =
        Diffo.Provider.create_characteristic!(%{
          name: :device,
          value: Value.primitive("string", "managed"),
          type: :instance
        })

      :ok = Diffo.Provider.delete_characteristic(characteristic)
      {:error, _error} = Diffo.Provider.get_characteristic_by_id(characteristic.id)
    end

    test "delete characteristic with related instance - failure" do
      specification = Diffo.Provider.create_specification!(%{name: "evc"})

      characteristic =
        Diffo.Provider.create_characteristic!(%{
          name: :device,
          value: Value.primitive("string", "managed"),
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
      Diffo.Provider.unrelate_instance_characteristics!(instance, %{
        characteristics: [characteristic.id]
      })

      :ok = Diffo.Provider.delete_characteristic(characteristic)
      {:error, _error} = Diffo.Provider.get_characteristic_by_id(characteristic.id)
    end
  end
end
