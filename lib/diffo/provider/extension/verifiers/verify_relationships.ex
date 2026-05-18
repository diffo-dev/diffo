# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Extension.Verifiers.VerifyRelationships do
  @moduledoc "Verifies that relationship role declarations are atoms, not modules or other invalid values"
  use Spark.Dsl.Verifier

  alias Spark.Dsl.Verifier
  alias Spark.Error.DslError

  @impl true
  def verify(dsl_state) do
    resource = Verifier.get_persisted(dsl_state, :module)
    steps = Verifier.get_entities(dsl_state, [:provider, :relationships])

    errors = Enum.flat_map(steps, &validate_step(resource, &1))

    case errors do
      [] -> :ok
      errors -> {:error, errors}
    end
  end

  defp validate_step(resource, %{direction: direction, roles: roles}) do
    validate_roles(resource, direction, roles)
  end

  defp validate_roles(_resource, _direction, :all), do: []
  defp validate_roles(_resource, _direction, :none), do: []

  defp validate_roles(resource, direction, roles) when is_list(roles) and length(roles) > 0 do
    Enum.flat_map(roles, fn role ->
      if is_atom(role) do
        []
      else
        [
          DslError.exception(
            module: resource,
            path: [:provider, :relationships],
            message:
              "relationships: #{direction} role #{inspect(role)} must be an atom, got #{inspect(role)}"
          )
        ]
      end
    end)
  end

  defp validate_roles(resource, direction, roles) do
    [
      DslError.exception(
        module: resource,
        path: [:provider, :relationships],
        message:
          "relationships: #{direction} roles must be :all, :none, or a non-empty list of atoms, got: #{inspect(roles)}"
      )
    ]
  end
end
