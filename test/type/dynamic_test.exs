# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Type.DynamicTest do
  use ExUnit.Case

  use Outstand
  alias Diffo.Type.Dynamic
  alias Diffo.Test.Patch
  alias Diffo.Test.CardValue

  describe "dynamic type validation" do
    test "cast_input rejects non-NewType scalar Ash type" do
      value = %Dynamic{type: Ash.Type.Date, value: ~D[2026-01-01]}
      assert {:error, msg} = Ash.Type.cast_input(Dynamic, value, [])
      assert msg =~ "storage_type :map"
    end

    test "cast_input rejects unloaded module" do
      value = %Dynamic{type: Diffo.Type.NonExistent, value: nil}
      assert {:error, msg} = Ash.Type.cast_input(Dynamic, value, [])
      assert msg =~ "storage_type :map"
    end

    test "apply_constraints rejects invalid type" do
      value = %Dynamic{type: Ash.Type.Date, value: ~D[2026-01-01]}
      assert {:error, msg} = Ash.Type.apply_constraints(Dynamic, value, [])
      assert msg =~ "storage_type :map"
    end

    test "is_valid? returns false for non-NewType" do
      assert Dynamic.is_valid?(Ash.Type.Date) == false
    end

    test "is_valid? returns false for unloaded module" do
      assert Dynamic.is_valid?(Diffo.Type.NonExistent) == false
    end

    test "is_valid? returns true for valid map-storage NewType" do
      assert Dynamic.is_valid?(Patch) == true
    end

    test "dynamic_constraints returns [] for non-NewType" do
      assert Dynamic.dynamic_constraints(Ash.Type.Date) == []
    end

    test "dynamic_constraints returns [] for unloaded module" do
      assert Dynamic.dynamic_constraints(Diffo.Type.NonExistent) == []
    end

    test "valid map-storage NewType still works" do
      value = %Dynamic{type: Patch, value: %Patch{aEnd: 1, zEnd: 42}}
      assert {:ok, %Dynamic{type: Patch}} = Ash.Type.cast_input(Dynamic, value, [])
    end
  end

  describe "dynamic cast and dump" do
    test "cast_input from struct" do
      value = %Dynamic{type: Patch, value: %Patch{aEnd: 1, zEnd: 42}}

      assert {:ok, %Dynamic{type: Patch, value: %Patch{aEnd: 1, zEnd: 42}}} =
               Ash.Type.cast_input(Dynamic, value, [])
    end

    test "cast_input nil" do
      assert {:ok, nil} = Ash.Type.cast_input(Dynamic, nil, [])
    end

    test "dump_to_native" do
      value = %Dynamic{type: Patch, value: %Patch{aEnd: 1, zEnd: 42}}
      assert {:ok, _dumped} = Ash.Type.dump_to_native(Dynamic, value, [])
    end

    test "dump_to_native nil" do
      assert {:ok, nil} = Ash.Type.dump_to_native(Dynamic, nil, [])
    end

    test "cast_stored roundtrip" do
      value = %Dynamic{type: Patch, value: %Patch{aEnd: 1, zEnd: 42}}
      {:ok, dumped} = Ash.Type.dump_to_native(Dynamic, value, [])

      assert {:ok, %Dynamic{type: Patch, value: %Patch{aEnd: 1, zEnd: 42}}} =
               Ash.Type.cast_stored(Dynamic, dumped, [])
    end

    test "cast_stored nil" do
      assert {:ok, nil} = Ash.Type.cast_stored(Dynamic, nil, [])
    end

    test "apply_constraints with valid struct" do
      value = %Dynamic{type: Patch, value: %Patch{aEnd: 1, zEnd: 42}}
      assert {:ok, ^value} = Ash.Type.apply_constraints(Dynamic, value, [])
    end

    test "apply_constraints nil" do
      assert {:ok, nil} = Ash.Type.apply_constraints(Dynamic, nil, [])
    end

    test "apply_constraints with invalid value" do
      assert {:error, _} = Ash.Type.apply_constraints(Dynamic, "not a dynamic", [])
    end
  end

  describe "dynamic json" do
    test "Dynamic implements Jason.Encoder" do
      expected = %Dynamic{type: Patch, value: %Patch{aEnd: 1, zEnd: 42}}
      assert Jason.Encoder.impl_for(expected) == Jason.Encoder.Diffo.Type.Dynamic
    end

    test "dynamic struct renders value only" do
      value = %Dynamic{type: Patch, value: %Patch{aEnd: 1, zEnd: 42}}
      assert Jason.encode!(value) == ~s({"aEnd":1,"zEnd":42})
    end
  end

  describe "dynamic outstanding" do
    test "Dynamic implements Outstanding" do
      expected = %Dynamic{type: Patch, value: %Patch{aEnd: 1, zEnd: 42}}
      assert Outstanding.impl_for(expected) == Outstanding.Diffo.Type.Dynamic
    end

    test "actual is missing" do
      expected = %Dynamic{type: Patch, value: %Patch{aEnd: 1, zEnd: 42}}
      actual = nil
      assert expected --- actual == expected
      assert expected >>> actual == true
    end

    test "actual is wrong type and value" do
      expected = %Dynamic{type: Patch, value: %Patch{aEnd: 1, zEnd: 42}}
      actual = %Dynamic{type: CardValue, value: %CardValue{name: "test"}}
      assert expected --- actual == expected
      assert expected >>> actual == true
    end

    test "actual is wrong value" do
      expected = %Dynamic{type: Patch, value: %Patch{aEnd: 1, zEnd: 42}}
      actual = %Dynamic{type: Patch, value: %Patch{aEnd: 3, zEnd: 42}}
      assert expected --- actual == %Dynamic{type: nil, value: %Patch{aEnd: 1}}
      assert expected >>> actual == true
    end

    test "expected is resolved" do
      expected = %Dynamic{type: Patch, value: %Patch{aEnd: 1, zEnd: 42}}
      actual = %Dynamic{type: Patch, value: %Patch{aEnd: 1, zEnd: 42}}
      assert expected --- actual == nil
      assert expected >>> actual == false
    end
  end
end
