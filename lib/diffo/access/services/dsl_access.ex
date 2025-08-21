defmodule Diffo.Access.DslAccess.Instance do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  DslAccess.Instance - DSL Access Service Instance
  """
  alias Diffo.Provider.BaseInstance
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
    category :network_service
  end

# features do
#   feature :dynamic_line_management do
#.    is_enabled?: true
#     characteristics do
#       characteristic :constraints, Diffo.Access.Constraints
#     end
#   end
# end

# characteristics do
#   characteristic :dslam, Diffo.Access.Dslam
#   characteristic :aggregate_interface, Diffo.Access.AggregateInterface
#   characteristic :circuit, Diffo.Access.Circuit
#   characteristic :line, Diffo.Access.Line
# end

  def init() do
    Diffo.Provider.Instance.init(__MODULE__)
  end
end
