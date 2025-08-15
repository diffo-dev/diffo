defmodule Diffo.Access.AggregateInterface do
 use Ash.TypedStruct

  typed_struct do
    field :name, :string,
      description: "the name of the aggregate interface"
    field :physical_interface, :string, constraints: [match: ~r/OC-3 LR(-2)?|1000BASE-(L|E|Z)X/],
      description: "the aggregate interface physical interface type"
    field :physical_layer, :atom, constraints: [one_of: [:STM1, :GbE]],
      description: "the aggregate interface physical layer standard"
    field :link_layer, :atom, constraints: [one_of: [:VP, :Q, :QINQ]],
      description: "the aggregate interface link layer standard"
    field :svlan_id, :integer, constraints: [min: 0, max: 4095],
      description: "the aggregate interface svlan_id"
    field :vpi, :integer, constraints: [min: 0, max: 4095],
      description: "the aggregate interface vpi"
  end
end
