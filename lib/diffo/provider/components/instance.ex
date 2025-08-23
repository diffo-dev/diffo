defmodule Diffo.Provider.Instance do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  Instance - Ash Resource for a TMF Service or Resource Instance
  """
  alias Diffo.Provider.BaseInstance

  use Ash.Resource,
    fragments: [BaseInstance],
    domain: Diffo.Provider

  resource do
    description "An Ash Resource for a TMF Service or Resource Instance"
    plural_name :instances
  end
end
