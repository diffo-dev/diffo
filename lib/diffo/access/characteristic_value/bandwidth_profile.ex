defmodule Diffo.Access.BandwidthProfile do
  use Ash.TypedStruct

  typed_struct do
    field(:downstream, :integer,
      constraints: [min: 0],
      description: "the bandwidth profile downstream rate"
    )

    field(:upstream, :integer,
      constraints: [min: 0],
      description: "the bandwidth profile upstream rate"
    )

    field(:units, :atom,
      default: :Mbps,
      constraints: [one_of: [:kbps, :Mbps]],
      description: "the bandwidth profile units"
    )
  end

  defimpl Jason.Encoder do
    def encode(%{downstream: downstream, upstream: upstream, units: units}, _opts) do
      Jason.OrderedObject.new(downstream: downstream, upstream: upstream, units: units)
      |> Jason.encode!()
    end
  end

  defimpl String.Chars do
    def to_string(struct) do
      inspect(struct)
    end
  end
end
