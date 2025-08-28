defmodule Diffo.Access.FloatUnit do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  FloatUnit - AshTyped Struct for Float with Unit
  """
  use Ash.TypedStruct, extensions: [AshJason.TypedStruct]

  jason do
    pick [:amount, :unit]
  end

  typed_struct do
    field :amount, :float, description: "the amount"

    field :unit, :atom, description: "the unit"
  end

  defimpl String.Chars do
    def to_string(struct) do
      inspect(struct)
    end
  end
end
