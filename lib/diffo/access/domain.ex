defmodule Diffo.Access do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  Access - example domain
  """
  use Ash.Domain,
    otp_app: :diffo

  resources do
    resource Diffo.Access.DslAccess.Instance
  end
end
