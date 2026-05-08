# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Assignment do
  @moduledoc """
  Ash Typed Struct for Assignment
  """
  use Ash.TypedStruct, extensions: [AshJason.TypedStruct]

  jason do
    pick [:id, :assignee_id, :assignable_type, :operation]
    compact true
    rename assignable_type: :type
  end

  typed_struct do
    field :id, :integer,
      constraints: [min: 0],
      description: "the id of the assigned thing"

    field :assignable_type, :string, description: "the type of the assigned thing"

    field :assignee_id, :uuid, description: "the id of the assignee Ash resource"

    field :operation, :atom,
      description: "the operation the assignee is requesting",
      default: nil,
      constraints: [one_of: [nil, :assign, :unassign, :auto_assign]]
  end

  def compare(%__MODULE__{id: a}, %__MODULE__{id: b}) do
    cond do
      a < b -> :lt
      a > b -> :gt
      true -> :eq
    end
  end

  defimpl String.Chars do
    def to_string(struct) do
      inspect(struct)
    end
  end
end
