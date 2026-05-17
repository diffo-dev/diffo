# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Extension.Verifiers.VerifyInstances do
  @moduledoc "Verifies instance role declarations — no duplicates, instance_type modules must exist and extend BaseInstance"
  use Spark.Dsl.Verifier

  alias Spark.Dsl.Verifier
  alias Spark.Error.DslError
  alias Diffo.Provider.Extension.Info

  @impl true
  def verify(dsl_state) do
    resource = Verifier.get_persisted(dsl_state, :module)
    instances = Verifier.get_entities(dsl_state, [:provider, :instances])

    duplicate_errors =
      instances
      |> Enum.group_by(& &1.role)
      |> Enum.filter(fn {_role, roles} -> length(roles) > 1 end)
      |> Enum.map(fn {role, _} ->
        DslError.exception(
          module: resource,
          path: [:provider, :instances],
          message: "instances: role #{inspect(role)} is declared more than once"
        )
      end)

    type_errors =
      Enum.reduce(instances, [], fn role, acc ->
        mod = role.instance_type

        cond do
          is_nil(mod) ->
            acc

          !Code.ensure_loaded?(mod) ->
            [
              DslError.exception(
                module: resource,
                path: [:provider, :instances, role.role],
                message: "instances: instance_type #{inspect(mod)} does not exist"
              )
              | acc
            ]

          !Info.instance?(mod) ->
            [
              DslError.exception(
                module: resource,
                path: [:provider, :instances, role.role],
                message: "instances: instance_type #{inspect(mod)} does not extend BaseInstance"
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
