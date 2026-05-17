# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Extension.Verifiers.VerifyPools do
  @moduledoc "Verifies pool names are unique"
  use Spark.Dsl.Verifier

  alias Spark.Dsl.Verifier
  alias Spark.Error.DslError

  @impl true
  def verify(dsl_state) do
    resource = Verifier.get_persisted(dsl_state, :module)
    pools = Verifier.get_entities(dsl_state, [:provider, :pools])

    errors =
      pools
      |> Enum.group_by(& &1.name)
      |> Enum.filter(fn {_name, ps} -> length(ps) > 1 end)
      |> Enum.map(fn {name, _} ->
        DslError.exception(
          module: resource,
          path: [:provider, :pools],
          message: "pools: name #{inspect(name)} is declared more than once"
        )
      end)

    case errors do
      [] -> :ok
      errors -> {:error, errors}
    end
  end
end
