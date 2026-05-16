# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Extension.Verifiers.VerifyParties do
  @moduledoc "Verifies party declarations and roles — no duplicates, party_type modules must exist and extend BaseParty"
  use Spark.Dsl.Verifier

  alias Spark.Dsl.Verifier
  alias Spark.Error.DslError
  alias Diffo.Provider.Extension.Info

  @impl true
  def verify(dsl_state) do
    resource = Verifier.get_persisted(dsl_state, :module)
    parties = Verifier.get_entities(dsl_state, [:provider, :parties])

    duplicate_errors =
      parties
      |> Enum.group_by(& &1.role)
      |> Enum.filter(fn {_role, declarations} -> length(declarations) > 1 end)
      |> Enum.map(fn {role, _} ->
        DslError.exception(
          module: resource,
          path: [:provider, :parties],
          message: "parties: role #{inspect(role)} is declared more than once"
        )
      end)

    type_errors =
      Enum.reduce(parties, [], fn party, acc ->
        mod = Map.get(party, :party_type)

        cond do
          is_nil(mod) ->
            acc

          !Code.ensure_loaded?(mod) ->
            [
              DslError.exception(
                module: resource,
                path: [:provider, :parties, party.role],
                message: "parties: party_type #{inspect(mod)} does not exist"
              )
              | acc
            ]

          !Info.party?(mod) ->
            [
              DslError.exception(
                module: resource,
                path: [:provider, :parties, party.role],
                message: "parties: party_type #{inspect(mod)} does not extend BaseParty"
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
