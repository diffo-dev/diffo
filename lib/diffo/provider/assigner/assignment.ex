# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Assignment do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  Assignment - AshTyped Struct for Assignment
  """
  use Ash.TypedStruct, extensions: [AshJason.TypedStruct]

  jason do
    pick [:id, :assignee_id, :operation]
    compact true
  end

  typed_struct do
    field :id, :integer,
      constraints: [min: 0],
      description: "the id of the partial resource"

    field :assignee_id, :uuid, description: "the id of the assignee Ash resource"

    field :operation, :atom,
      description: "the operation the assignee is requesting",
      default: :assign,
      constraints: [one_of: [:assign, :unassign, :auto_assign]]
  end

  defimpl String.Chars do
    def to_string(struct) do
      inspect(struct)
    end
  end

  def compare(%{id: id0}, %{id: id1}),
    do: Diffo.Util.compare(id0, id1)
end
