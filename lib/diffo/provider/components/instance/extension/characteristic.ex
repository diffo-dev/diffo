defmodule Diffo.Provider.Instance.Characteristic do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  Characteristic for Instance Extension
  """

  @doc """
  Struct for a Characteristic
  """
  defstruct [:name, :type, :value_type]

  defimpl String.Chars do
    def to_string(struct) do
      inspect(struct)
    end
  end
end
