defmodule Diffo.Access.Line do
  use Ash.TypedStruct

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

  defimpl Jason.Encoder do
    def encode(%{port: port, slot: slot, standard: standard, profile: profile}, _opts) do
      Jason.OrderedObject.new(port: port, slot: slot, standard: standard, profile: profile)
      |> Jason.encode!()
    end
  end

  defimpl String.Chars do
    def to_string(struct) do
      inspect(struct)
    end
  end
end
