# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Type.PrimitiveTest do
  use ExUnit.Case

  use Outstand
  alias Diffo.Type.Primitive

  describe "primitive json" do
    test "Primitive implements Json.Encode" do
      expected = Primitive.wrap("string", "connectivity")
      assert Jason.Encoder.impl_for(expected) == Jason.Encoder.Diffo.Type.Primitive
    end

    test "primitive string renders" do
      value = Primitive.wrap("string", "connectivity")
      assert Jason.encode!(value) == "\"connectivity\""
    end

    test "primitive integer renders" do
      value = Primitive.wrap("integer", 5)
      assert Jason.encode!(value) == "5"
    end

    test "primitive float renders" do
      value = Primitive.wrap("float", 5.0)
      assert Jason.encode!(value) == "5.0"
    end

    test "primitive boolean renders" do
      value = Primitive.wrap("boolean", true)
      assert Jason.encode!(value) == "true"
    end

    test "primitive date renders" do
      value = Primitive.wrap("date", ~D[2026-04-16])
      assert Jason.encode!(value) == "\"2026-04-16\""
    end

    test "primitive time renders" do
      value = Primitive.wrap("time", ~T[15:43:13.817332])
      assert Jason.encode!(value) == "\"15:43:13.817332\""
    end

    test "primitive datetime renders" do
      value = Primitive.wrap("datetime", ~U[2026-04-16 15:43:13.817332Z])
      assert Jason.encode!(value) == "\"2026-04-16T15:43:13.817332Z\""
    end

    test "primitive duration renders" do
      value = Primitive.wrap("duration", %Duration{hour: 1})
      assert Jason.encode!(value) == "\"PT1H\""
    end

    def unwrap(%{type: "string", string: value}), do: value
    def unwrap(%{type: "integer", integer: value}), do: value
    def unwrap(%{type: "float", float: value}), do: value
    def unwrap(%{type: "boolean", boolean: value}), do: value
    def unwrap(%{type: "date", date: value}), do: value
    def unwrap(%{type: "time", time: value}), do: value
    def unwrap(%{type: "datetime", datetime: value}), do: value
    def unwrap(%{type: "duration", duration: value}), do: value
  end

  describe "primitive outstanding" do
    test "Primitive implements Outstanding" do
      expected = Primitive.wrap("string", "connectivity")
      assert Outstanding.impl_for(expected) == Outstanding.Diffo.Type.Primitive
    end

    test "actual is missing" do
      expected = Primitive.wrap("string", "connectivity")
      actual = nil
      assert expected --- actual == %{type: "string", value: "connectivity"}
      assert expected >>> actual == true
    end

    test "actual is wrong type and value" do
      expected = Primitive.wrap("string", "connectivity")
      actual = Primitive.wrap("boolean", true)
      assert expected --- actual == %{type: "string", value: "connectivity"}
      assert expected >>> actual == true
    end

    test "actual is wrong value" do
      expected = Primitive.wrap("string", "connectivity")
      actual = Primitive.wrap("string", "Connectivity")
      assert expected --- actual == %{value: "connectivity"}
      assert expected >>> actual == true
    end

    test "actual is wrong type" do
      expected = Primitive.wrap("float", 4)
      actual = Primitive.wrap("integer", 4)
      assert expected --- actual == %{type: "float"}
      assert expected >>> actual == true
    end

    test "value function is outstanding" do
      expected = Primitive.wrap("string", &any_bitstring/1)
      actual = Primitive.wrap("string", nil)
      assert expected --- actual == %{value: :any_bitstring}
      assert expected >>> actual == true
    end

    test "expected string is resolved" do
      expected = Primitive.wrap("string", "connectivity")
      actual = Primitive.wrap("string", "connectivity")
      assert expected --- actual == nil
      assert expected >>> actual == false
    end

    test "expected function is resolved" do
      expected = Primitive.wrap("string", &any_bitstring/1)
      actual = Primitive.wrap("string", "connectivity")
      assert expected --- actual == nil
      assert expected >>> actual == false
    end
  end
end
