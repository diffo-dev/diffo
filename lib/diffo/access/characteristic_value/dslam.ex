defmodule Diffo.Access.Dslam do
  use Ash.TypedStruct, extensions: [AshJason.TypedStruct]

  typed_struct do
    field(:name, :string,
      constraints: [match: ~r/Q[A-Z]{4}\d{4}/],
      description: "the DSLAM name"
    )

    field(:family, :atom,
      constraints: [one_of: [:ISAM, :AMX]],
      default: :ISAM,
      description: "the DSLAM family name"
    )

    field(:model, :string, description: "the DSLAM model name")

    field(:technology, :atom,
      constraints: [one_of: [:eth, :atm]],
      default: :eth,
      description: "the DSLAM technology"
    )
  end

  jason do
    pick([:name, :family, :model, :technology])
  end

  defimpl String.Chars do
    def to_string(struct) do
      inspect(struct)
    end
  end
end
