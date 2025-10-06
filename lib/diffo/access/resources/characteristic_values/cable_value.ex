defmodule Diffo.Access.CableValue do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  CableValue - AshTyped Struct for Cable Characteristic Value
  """
  use Ash.TypedStruct, extensions: [AshJason.TypedStruct]

  jason do
    pick [:name, :pairs, :length, :loss, :technology]
    compact true
  end

  typed_struct do
    field :name, :string, description: "the cable name"

    field :pairs, :integer, description: "the number of pairs in the cable"

    field :length, :struct,
      constraints: [instance_of: IntegerUnit],
      description: "the length of the cable"

    field :loss, :struct,
      constraints: [instance_of: FloatUnit],
      description: "the loss of the cable at 300kHz"

    field :technology, :atom, description: "the cable technology"
  end

  defimpl String.Chars do
    def to_string(struct) do
      inspect(struct)
    end
  end
end
