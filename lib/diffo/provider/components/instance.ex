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

  def init do
    init(__MODULE__)
  end

  def init(module) when is_atom(module) do
        IO.puts("initialising #{module}")
    IO.inspect(Diffo.Provider.Instance.Extension.Info.specification_id(module), label: :specification_id)
    IO.inspect(Diffo.Provider.Instance.Extension.Info.specification_name(module), label: :specification_name)
    IO.inspect(Diffo.Provider.Instance.Extension.Info.specification_options(module), label: :specification_options)
  end
end
