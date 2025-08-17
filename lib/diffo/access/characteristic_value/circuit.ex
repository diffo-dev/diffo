defmodule Diffo.Access.Circuit do
  use Ash.TypedStruct
  alias Diffo.Access.BandwidthProfile

  typed_struct do
    field(:circuit_id, :string,
      constraints: [match: ~r/Q[A-Z]{4}\d{4} eth \d{1,4}:\d{1,4}/],
      description: "the circuit id"
    )

    field(:cvlan_id, :integer,
      default: 0,
      constraints: [min: 0, max: 4095],
      description: "the circuit cvlan id"
    )

    field(:vci, :integer,
      default: 0,
      constraints: [min: 0, max: 4095],
      description: "the circuit vci"
    )

    field(:encapsulation, :atom,
      default: :IPoE,
      constraints: [one_of: [:PPPoA, :PPPoE, :IPoE]],
      description: "the circuit encapsulation"
    )

    field(:bandwidth_profile, :struct,
      constraints: [instance_of: BandwidthProfile],
      description: "the circuit bandwidth profile"
    )
  end

  defimpl Jason.Encoder do
    def encode(
          %{circuit_id: circuit_id, cvlan_id: cvlan_id, vci: vci, encapsulation: encapsulation, bandwidth_profile: bandwidth_profile},
          _opts
        ) do
      Jason.OrderedObject.new(
        circuit_id: circuit_id,
        cvlan_id: cvlan_id,
        vci: vci,
        encapsulation: encapsulation,
        bandwidth_profile: bandwidth_profile
      )
      |> Jason.encode!()
    end
  end

  defimpl String.Chars do
    def to_string(struct) do
      inspect(struct)
    end
  end
end
