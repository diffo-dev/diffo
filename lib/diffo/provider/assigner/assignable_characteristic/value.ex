# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.AssignableCharacteristic.Value do
  @moduledoc "JSON value struct for AssignableCharacteristic."
  use Ash.TypedStruct, extensions: [AshJason.TypedStruct]

  typed_struct do
    field :first, :integer, description: "the first assignable value in the pool"
    field :last, :integer, description: "the last assignable value in the pool"
    field :assignable_type, :string, description: "the type label of the assignable thing"
    field :algorithm, :atom, description: "the selection algorithm for auto-assign"
  end

  jason do
    pick [:first, :last, :assignable_type, :algorithm]
    compact true
    rename assignable_type: :type
  end

  defimpl String.Chars do
    def to_string(struct), do: inspect(struct)
  end
end
