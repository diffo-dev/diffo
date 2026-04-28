# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Instance.Extension.Verifiers.VerifyCharacteristics do
  @moduledoc "Verifies that characteristic names are unique and value_type modules exist"
  use Spark.Dsl.Verifier

  alias Spark.Dsl.Verifier
  alias Spark.Error.DslError

  @impl true
  def verify(dsl_state) do
    resource = Verifier.get_persisted(dsl_state, :module)
    characteristics = Verifier.get_entities(dsl_state, [:structure, :characteristics])

    duplicate_errors =
      characteristics
      |> Enum.group_by(& &1.name)
      |> Enum.filter(fn {_name, chars} -> length(chars) > 1 end)
      |> Enum.map(fn {name, _} ->
        DslError.exception(
          module: resource,
          path: [:structure, :characteristics],
          message: "characteristics: name #{inspect(name)} is declared more than once"
        )
      end)

    type_errors =
      Enum.reduce(characteristics, [], fn char, acc ->
        case module_from_value_type(char.value_type) do
          {:ok, module} ->
            if Code.ensure_loaded?(module) do
              acc
            else
              [
                DslError.exception(
                  module: resource,
                  path: [:structure, :characteristics, char.name],
                  message: "characteristics: value_type #{inspect(module)} does not exist"
                )
                | acc
              ]
            end

          :error ->
            acc
        end
      end)

    errors = duplicate_errors ++ type_errors

    case errors do
      [] -> :ok
      errors -> {:error, errors}
    end
  end

  defp module_from_value_type({:array, module}) when is_atom(module), do: {:ok, module}
  defp module_from_value_type(module) when is_atom(module), do: {:ok, module}
  defp module_from_value_type(_), do: :error
end
