# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Extension.Verifiers.VerifyPlaces do
  @moduledoc "Verifies place declarations and roles — no duplicates, place_type modules must exist and extend BasePlace"
  use Spark.Dsl.Verifier

  alias Spark.Dsl.Verifier
  alias Spark.Error.DslError
  alias Diffo.Provider.Extension.Info
  alias Diffo.Provider.Extension.InheritedPlaceDeclaration
  alias Diffo.Provider.Extension.Traversal

  @impl true
  def verify(dsl_state) do
    resource = Verifier.get_persisted(dsl_state, :module)
    places = Verifier.get_entities(dsl_state, [:provider, :places])

    duplicate_errors =
      places
      |> Enum.group_by(& &1.role)
      |> Enum.filter(fn {_role, declarations} -> length(declarations) > 1 end)
      |> Enum.map(fn {role, _} ->
        DslError.exception(
          module: resource,
          path: [:provider, :places],
          message: "places: role #{inspect(role)} is declared more than once"
        )
      end)

    type_errors =
      Enum.reduce(places, [], fn place, acc ->
        mod = Map.get(place, :place_type)

        cond do
          is_nil(mod) ->
            acc

          !Code.ensure_loaded?(mod) ->
            [
              DslError.exception(
                module: resource,
                path: [:provider, :places, place.role],
                message: "places: place_type #{inspect(mod)} does not exist"
              )
              | acc
            ]

          !Info.place?(mod) ->
            [
              DslError.exception(
                module: resource,
                path: [:provider, :places, place.role],
                message: "places: place_type #{inspect(mod)} does not extend BasePlace"
              )
              | acc
            ]

          true ->
            acc
        end
      end)

    via_errors = via_errors(places, resource)

    case duplicate_errors ++ type_errors ++ via_errors do
      [] -> :ok
      errors -> {:error, errors}
    end
  end

  defp via_errors(places, resource) do
    places
    |> Enum.filter(&is_struct(&1, InheritedPlaceDeclaration))
    |> Enum.reduce([], fn decl, acc ->
      case Traversal.normalize(decl.via, decl.role) do
        {:ok, _hops} ->
          acc

        {:error, reason} ->
          [
            DslError.exception(
              module: resource,
              path: [:provider, :places, decl.role],
              message: "inherited_place #{inspect(decl.role)}: invalid via — #{inspect(reason)}"
            )
            | acc
          ]
      end
    end)
  end
end
