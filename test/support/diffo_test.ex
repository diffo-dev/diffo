# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Test do
  @moduledoc """
  Shared test helpers.

  `create_instance/1` and `create_instance!/1` replace the old bare
  `Diffo.Provider.create_instance` used pervasively across the suite. This helper
  reads the specification named by `:specified_by`, looks at its `type`, and
  creates the matching instance kind: `Diffo.Provider.Instance` (the generic
  Service, which is also the projection reader) for a `:serviceSpecification`, or
  the `ResourceInstance` leaf for a `:resourceSpecification`. This enforces "an
  instance is exactly one of Service or Resource" without each call site choosing.
  """
  alias Diffo.Test.Instance.ResourceInstance

  def create_instance!(attrs) when is_map(attrs) do
    spec = Diffo.Provider.get_specification_by_id!(Map.fetch!(attrs, :specified_by))
    {leaf, type} = leaf_for(spec.type)
    Ash.create!(leaf, Map.put(attrs, :type, type), action: :create)
  end

  def create_instance(attrs) when is_map(attrs) do
    case Diffo.Provider.get_specification_by_id(Map.get(attrs, :specified_by)) do
      {:ok, spec} ->
        {leaf, type} = leaf_for(spec.type)
        Ash.create(leaf, Map.put(attrs, :type, type), action: :create)

      {:error, _} = error ->
        error
    end
  end

  defp leaf_for(:serviceSpecification), do: {Diffo.Provider.Instance, :service}
  defp leaf_for(:resourceSpecification), do: {ResourceInstance, :resource}
end
