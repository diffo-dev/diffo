defmodule Diffo.Access.ShelfValue do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  ShelfValue - AshTyped Struct for Shelf Characteristic Value
  """
  use Ash.TypedStruct, extensions: [AshJason.TypedStruct]

  jason do
    pick [:name, :family, :model, :technology]
  end

  typed_struct do
    field :name, :string,
      description: "the shelf name"

    field :family, :atom,
      description: "the shelf family name"

    field :model, :string, description: "the shelf model name"

    field :technology, :atom,
      description: "the shelf technology"
  end

  defimpl String.Chars do
    def to_string(struct) do
      inspect(struct)
    end
  end
end
