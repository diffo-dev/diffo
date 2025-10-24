# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.AssignableValue do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  AssignableValue - AshTyped Struct for Assignable Characteristic Value
  """
  use Ash.TypedStruct, extensions: [AshJason.TypedStruct]

  jason do
    pick [:first, :last, :free, :type, :algorithm]
    compact true
  end

  typed_struct do
    field :first, :integer,
      description: "the first assignable thing",
      default: 1,
      constraints: [min: 0]

    field :last, :integer,
      description: "the last assignable thing",
      default: 1,
      constraints: [min: 0]

    field :free, :integer,
      description: "the number of free things",
      default: 1,
      constraints: [min: 0]

    field :type, :string, description: "the type of the thing"

    field :algorithm, :atom,
      description: "the assignment algorithm",
      default: :lowest,
      constraints: [one_of: [:lowest, :highest, :random]]
  end

  defimpl String.Chars do
    def to_string(struct) do
      inspect(struct)
    end
  end
end
