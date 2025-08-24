defmodule Diffo.Access do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  Access - example domain
  """
  use Ash.Domain,
    otp_app: :diffo

  alias Diffo.Access.DslAccess.Instance, as: DslAccess

  resources do
    resource DslAccess do
      define :get_dsl_by_id, action: :read, get_by: :id
      define :qualify_dsl, action: :qualify
      define :qualify_dsl_result, action: :qualify_result
      define :design_dsl_result, action: :design_result
    end
  end
end
