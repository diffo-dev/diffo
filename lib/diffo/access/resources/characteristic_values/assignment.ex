defmodule Diffo.Access.Assignment do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  Assignment - AshTyped Struct for Assignment
  """
  use Ash.TypedStruct, extensions: [AshJason.TypedStruct]

  jason do
    pick [:id, :instance_id, :operation]
  end

  typed_struct do
    field :id, :integer,
      constraints: [min: 0],
      description: "the id of the assigned thing"

    field :instance_id, :uuid,
      description: "the consuming instance_id"

    field :operation, :atom,
      description: "the operation the consumer is requesting",
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
