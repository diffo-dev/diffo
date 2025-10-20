# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Access.PathValue do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  PathValue - AshTyped Struct for Path Characteristic Value
  """
  use Ash.TypedStruct, extensions: [AshJason.TypedStruct, AshOutstanding.TypedStruct]

  jason do
    pick [:name, :sections, :length, :loss, :technology]
    compact(true)
  end

  outstanding do
    expect [:loss]
  end

  typed_struct do
    field :name, :string, description: "the cable name"

    field :sections, :integer,
      default: 0,
      constraints: [min: 0],
      description: "the number of sections in the path"

    field :length, :struct,
      constraints: [instance_of: IntegerUnit],
      description: "the length of the path"

    field :loss, :struct,
      constraints: [instance_of: FloatUnit],
      description: "the loss of the path at 300kHz"

    field :technology, :atom, description: "the path technology"
  end

  defimpl String.Chars do
    def to_string(struct) do
      inspect(struct)
    end
  end
end
