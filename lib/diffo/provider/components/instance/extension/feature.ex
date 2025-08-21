defmodule Diffo.Provider.Instance.Extension.Feature do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  Feature for Instance Extension
  """

  @doc """
  Struct for a Feature
  """
  defstruct [:name, :is_enabled?, :characteristics]

  defimpl String.Chars do
    def to_string(struct) do
      inspect(struct)
    end
  end
end
