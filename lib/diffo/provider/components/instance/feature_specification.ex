defmodule Diffo.Provider.FeatureSpecification do
  @doc """
  Struct for a Feature Specification
  """
  defstruct [:name, :is_enabled?, :characteristics]
end
