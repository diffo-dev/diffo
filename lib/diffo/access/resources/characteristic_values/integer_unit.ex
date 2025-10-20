# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Access.IntegerUnit do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  IntegerUnit - AshTyped Struct for Integer with Unit
  """
  use Ash.TypedStruct, extensions: [AshJason.TypedStruct, AshOutstanding.TypedStruct]

  jason do
    pick [:amount, :unit]
    compact(true)
  end

  outstanding do
    expect [:amount, :unit]
  end

  typed_struct do
    field :amount, :integer, description: "the amount"

    field :unit, :atom, description: "the unit"
  end

  defimpl String.Chars do
    def to_string(struct) do
      inspect(struct)
    end
  end
end
