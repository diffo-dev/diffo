defmodule Diffo.Access.Line do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  Line - AshTyped Struct for Line Characteristic Value
  """
  use Ash.TypedStruct, extensions: [AshJason.TypedStruct]

  typed_struct do
    field(:port, :integer,
      constraints: [min: 0, max: 47],
      description: "the line port number"
    )

    field(:slot, :integer,
      constraints: [min: 0, max: 15],
      description: "the line port slot number"
    )

    field(:standard, :atom,
      constraints: [one_of: [:ADSL, :ADSL2plus, :VDSL]],
      default: :ADSL2plus,
      description: "the line port standard"
    )

    field(:profile, :string, description: "the line port profile")
  end

  jason do
    pick([:port, :slot, :standard, :profile])
  end

  defimpl String.Chars do
    def to_string(struct) do
      inspect(struct)
    end
  end
end
