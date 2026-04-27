# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Instance.Extension.Verifiers.VerifyParties do
  @moduledoc "Verifies party role declarations — no duplicates, party_type modules must exist"
  use Spark.Dsl.Verifier

  alias Spark.Dsl.Verifier
  alias Spark.Error.DslError

  @impl true
  def verify(dsl_state) do
    resource = Verifier.get_persisted(dsl_state, :module)
    parties = Verifier.get_entities(dsl_state, [:parties])

    duplicate_errors =
      parties
      |> Enum.group_by(& &1.role)
      |> Enum.filter(fn {_role, declarations} -> length(declarations) > 1 end)
      |> Enum.map(fn {role, _} ->
        DslError.exception(
          module: resource,
          path: [:parties],
          message: "parties: role #{inspect(role)} is declared more than once"
        )
      end)

    type_errors =
      Enum.reduce(parties, [], fn party, acc ->
        if party.party_type && !Code.ensure_loaded?(party.party_type) do
          [
            DslError.exception(
              module: resource,
              path: [:parties, party.role],
              message: "parties: party_type #{inspect(party.party_type)} does not exist"
            )
            | acc
          ]
        else
          acc
        end
      end)

    errors = duplicate_errors ++ type_errors

    case errors do
      [] -> :ok
      errors -> {:error, errors}
    end
  end
end
