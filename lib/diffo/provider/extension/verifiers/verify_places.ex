# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Extension.Verifiers.VerifyPlaces do
  @moduledoc "Verifies place declarations and roles — no duplicates, place_type modules must exist and extend BasePlace"
  use Spark.Dsl.Verifier

  alias Spark.Dsl.Verifier
  alias Spark.Error.DslError
  alias Diffo.Provider.Extension.Info

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

    case duplicate_errors ++ type_errors do
      [] -> :ok
      errors -> {:error, errors}
    end
  end
end
