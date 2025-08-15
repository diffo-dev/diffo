defmodule Diffo.Access.Line do
 use Ash.TypedStruct

  typed_struct do
    field :port, :integer, constraints: [min: 0, max: 47],
      description: "the line port number"
    field :slot, :integer, constraints: [min: 0, max: 15],
      description: "the line port slot number"
    field :standard, {:array, :atom}, constraints: [items: [one_of: [:ADSL, :ADSL2plus, :VDSL]]],
      description: "the line port standard"
    field :profile, :string,
      description: "the line port profile"
  end
end
