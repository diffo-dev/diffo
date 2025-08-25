defmodule Diffo.Access.CardValue do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  CardValue - AshTyped Struct for Card Characteristic Value
  """
  use Ash.TypedStruct, extensions: [AshJason.TypedStruct]

  jason do
    pick [:name, :family, :model, :technology]
  end

  typed_struct do
    field :name, :string,
      description: "the card name"

    field :family, :atom,
      description: "the card family name"

    field :model, :string, description: "the card model name"

    field :technology, :atom,
      description: "the card technology"
  end

  defimpl String.Chars do
    def to_string(struct) do
      inspect(struct)
    end
  end
end
