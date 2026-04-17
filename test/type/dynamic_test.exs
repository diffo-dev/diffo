# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Type.DynamicTest do
  use ExUnit.Case

  use Outstand
  alias Diffo.Type.Dynamic
  alias Diffo.Test.Patch
  alias Diffo.Test.CardValue

  describe "dynamic cast and dump" do
    test "cast_input from struct" do
      value = %Dynamic{type: Patch, value: %Patch{aEnd: 1, zEnd: 42}}

      assert {:ok, %Dynamic{type: Patch, value: %Patch{aEnd: 1, zEnd: 42}}} =
               Ash.Type.cast_input(Dynamic, value, [])
    end

    test "dump_to_native" do
      value = %Dynamic{type: Patch, value: %Patch{aEnd: 1, zEnd: 42}}
      assert {:ok, _dumped} = Ash.Type.dump_to_native(Dynamic, value, [])
    end

    test "cast_stored roundtrip" do
      value = %Dynamic{type: Patch, value: %Patch{aEnd: 1, zEnd: 42}}
      {:ok, dumped} = Ash.Type.dump_to_native(Dynamic, value, [])

      assert {:ok, %Dynamic{type: Patch, value: %Patch{aEnd: 1, zEnd: 42}}} =
               Ash.Type.cast_stored(Dynamic, dumped, [])
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
