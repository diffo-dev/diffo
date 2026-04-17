# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Type.ValueTest do
  use ExUnit.Case

  use Outstand
  alias Diffo.Type.Value
  alias Diffo.Type.Primitive
  alias Diffo.Type.Dynamic
  alias Diffo.Test.Patch

  describe "value cast and dump" do
    test "cast_input dynamic using Value.dynamic" do
      value = Value.dynamic(%Patch{aEnd: 1, zEnd: 42})

      assert {:ok, %Ash.Union{type: :dynamic, value: %Dynamic{type: Patch}}} =
               Ash.Type.cast_input(Value, value, Value.subtype_constraints())
    end

    test "cast_input primitive using Value.primitive" do
      value = Value.primitive("string", "hello")

      assert {:ok, %Ash.Union{type: :string, value: %Primitive{type: "string", string: "hello"}}} =
               Ash.Type.cast_input(Value, value, Value.subtype_constraints())
    end

    test "cast_input primitive string" do
      value = Primitive.wrap("string", "hello")

      assert {:ok, %Ash.Union{type: :string, value: %Primitive{type: "string", string: "hello"}}} =
               Ash.Type.cast_input(Value, value, Value.subtype_constraints())
    end

    @tag bugged: "raw Dynamic struct cast_input requires Value wrapper"
    @tag :skip
    test "cast_input dynamic" do
      value = %Dynamic{type: Patch, value: %Patch{aEnd: 1, zEnd: 42}}

      assert {:ok, %Ash.Union{type: :dynamic, value: %Dynamic{type: Patch}}} =
               Ash.Type.cast_input(Value, value, Value.subtype_constraints())
    end

    test "dump_to_native primitive" do
      value = %Ash.Union{type: :string, value: Primitive.wrap("string", "hello")}

      assert {:ok, %{"type" => :string, "value" => _}} =
               Ash.Type.dump_to_native(Value, value, Value.subtype_constraints())
    end

    test "dump_to_native dynamic" do
      value = %Ash.Union{
        type: :dynamic,
        value: %Dynamic{type: Patch, value: %Patch{aEnd: 1, zEnd: 42}}
      }

      assert {:ok, %{"type" => :dynamic, "value" => %{"type" => _, "value" => _}}} =
               Ash.Type.dump_to_native(Value, value, Value.subtype_constraints())
    end

    test "cast_stored roundtrip primitive" do
      value = %Ash.Union{type: :string, value: Primitive.wrap("string", "hello")}
      {:ok, dumped} = Ash.Type.dump_to_native(Value, value, Value.subtype_constraints())

      assert {:ok, %Ash.Union{type: :string}} =
               Ash.Type.cast_stored(Value, dumped, Value.subtype_constraints())
    end

    test "cast_stored roundtrip dynamic" do
      value = %Ash.Union{
        type: :dynamic,
        value: %Dynamic{type: Patch, value: %Patch{aEnd: 1, zEnd: 42}}
      }

      {:ok, dumped} = Ash.Type.dump_to_native(Value, value, Value.subtype_constraints())

      assert {:ok,
              %Ash.Union{
                type: :dynamic,
                value: %Dynamic{type: Patch, value: %Patch{aEnd: 1, zEnd: 42}}
              }} =
               Ash.Type.cast_stored(Value, dumped, Value.subtype_constraints())
    end

    test "roundtrip primitive from Value.primitive" do
      value = Value.primitive("string", "hello")
      {:ok, cast} = Ash.Type.cast_input(Value, value, Value.subtype_constraints())
      {:ok, dumped} = Ash.Type.dump_to_native(Value, cast, Value.subtype_constraints())
      {:ok, result} = Ash.Type.cast_stored(Value, dumped, Value.subtype_constraints())
      assert Diffo.Unwrap.unwrap(result) == "hello"
    end

    test "roundtrip dynamic from Value.dynamic" do
      value = Value.dynamic(%Patch{aEnd: 1, zEnd: 42})
      {:ok, cast} = Ash.Type.cast_input(Value, value, Value.subtype_constraints())
      {:ok, dumped} = Ash.Type.dump_to_native(Value, cast, Value.subtype_constraints())
      {:ok, result} = Ash.Type.cast_stored(Value, dumped, Value.subtype_constraints())
      assert Diffo.Unwrap.unwrap(result) == %Patch{aEnd: 1, zEnd: 42}
    end
  end

  describe "value json" do
    test "Value implements Jason.Encoder" do
      expected = %Ash.Union{type: :string, value: Primitive.wrap("string", "connectivity")}
      assert Jason.Encoder.impl_for(expected) == Jason.Encoder.Ash.Union
    end

    test "primitive string value renders" do
      value = %Ash.Union{type: :string, value: Primitive.wrap("string", "connectivity")}
      assert Jason.encode!(value) == "\"connectivity\""
    end

    test "dynamic value renders" do
      value = %Ash.Union{
        type: :dynamic,
        value: %Dynamic{type: Patch, value: %Patch{aEnd: 1, zEnd: 42}}
      }

      assert Jason.encode!(value) == ~s({"aEnd":1,"zEnd":42})
    end
  end

  describe "value outstanding" do
    test "Value implements Outstanding" do
      expected = %Ash.Union{type: :string, value: Primitive.wrap("string", "connectivity")}
      assert Outstanding.impl_for(expected) == Outstanding.Ash.Union
    end

    test "actual is missing" do
      expected = %Ash.Union{type: :string, value: Primitive.wrap("string", "connectivity")}
      actual = nil
      assert expected --- actual == expected
      assert expected >>> actual == true
    end

    test "actual is wrong value" do
      expected = %Ash.Union{type: :string, value: Primitive.wrap("string", "connectivity")}
      actual = %Ash.Union{type: :string, value: Primitive.wrap("string", "wrong")}
      assert expected --- actual != nil
      assert expected >>> actual == true
    end

    test "expected string is resolved" do
      expected = %Ash.Union{type: :string, value: Primitive.wrap("string", "connectivity")}
      actual = %Ash.Union{type: :string, value: Primitive.wrap("string", "connectivity")}
      assert expected --- actual == nil
      assert expected >>> actual == false
    end

    test "dynamic value is resolved" do
      expected = %Ash.Union{
        type: :dynamic,
        value: %Dynamic{type: Patch, value: %Patch{aEnd: 1, zEnd: 42}}
      }

      actual = %Ash.Union{
        type: :dynamic,
        value: %Dynamic{type: Patch, value: %Patch{aEnd: 1, zEnd: 42}}
      }

      assert expected --- actual == nil
      assert expected >>> actual == false
    end
  end
end
