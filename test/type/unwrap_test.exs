# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.UnwrapTest do
  use ExUnit.Case

  alias Diffo.Type.Primitive
  alias Diffo.Type.Value

  describe "List" do
    test "unwraps a list of primitives" do
      list = [Primitive.wrap("integer", 1), Primitive.wrap("integer", 2)]
      assert Diffo.Unwrap.unwrap(list) == [1, 2]
    end

    test "unwraps a list of Value unions" do
      list = [Value.primitive("string", "a"), Value.primitive("string", "b")]
      {:ok, cast_a} = Ash.Type.cast_input(Value, Enum.at(list, 0), Value.subtype_constraints())
      {:ok, cast_b} = Ash.Type.cast_input(Value, Enum.at(list, 1), Value.subtype_constraints())
      assert Diffo.Unwrap.unwrap([cast_a, cast_b]) == ["a", "b"]
    end

    test "returns plain values unchanged" do
      assert Diffo.Unwrap.unwrap([1, 2, 3]) == [1, 2, 3]
    end

    test "unwraps empty list" do
      assert Diffo.Unwrap.unwrap([]) == []
    end
  end
end
