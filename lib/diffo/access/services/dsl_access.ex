defmodule Diffo.Access.DslAccess.Instance do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  DslAccess.Instance - DSL Access Service Instance
  """

  alias Diffo.Provider.BaseInstance
  alias Diffo.Provider.Instance
  alias Diffo.Provider.Instance.Specification
  alias Diffo.Provider.Instance.Characteristic
  alias Diffo.Provider.Instance.Party
  alias Diffo.Provider.Instance.Place

  use Ash.Resource,
    fragments: [BaseInstance],
    domain: Diffo.Access

  resource do
    description "An Ash Resource representing a DSL Access Service"
    plural_name :DslAccesses
  end

  specification do
    id "da9b207a-26c3-451d-8abd-0640c6349979"
    name "dslAccess"
    description "A DSL Access Network Service connecting a subscriber premises to an NNI"
    category "Network Service"
  end

# features do
#   feature :dynamic_line_management do
#.    is_enabled?: true
#     characteristics do
#       characteristic :constraints, Diffo.Access.Constraints
#     end
#   end
# end

  characteristics do
    characteristic :dslam, Diffo.Access.Dslam
    characteristic :aggregate_interface, Diffo.Access.AggregateInterface
    characteristic :circuit, Diffo.Access.Circuit
    characteristic :line, Diffo.Access.Line
  end

  actions do
    create :qualify do
      description "creates a new DSL Access service instance for qualification"
      argument :places, {:array, :struct}
      argument :parties, {:array, :struct}
      argument :specified_by, :uuid, public?: false
      argument :characteristics, {:array, :uuid}, public?: false

      #change manage_relationship(:specified_by, :specification, type: :append)
      #change manage_relationship(:characteristics, :characteristics, type: :append)

      change before_action fn changeset, _context ->
        changeset
        |> Specification.set_specified_by_argument()
        |> Characteristic.set_characteristics_argument()
      end

      change after_action fn changeset, result, _context ->
        with {:ok, with_specification} <- Specification.specify_instance(result, changeset),
             {:ok, with_characteristics} <- Characteristic.define_instance(with_specification, changeset),
             {:ok, with_parties} <- Party.involve_instance(with_characteristics, changeset),
             {:ok, with_places} <- Place.locate_instance(with_parties, changeset),
            do: {:ok, with_places}
      end

      change load [:href]
      upsert? false
    end
  end

  def init() do
    Instance.init(__MODULE__)
  end
end
