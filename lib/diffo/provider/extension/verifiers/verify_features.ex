# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Extension.Verifiers.VerifyFeatures do
  @moduledoc "Verifies feature names are unique and feature characteristic value_type modules exist and extend BaseCharacteristic"
  use Spark.Dsl.Verifier

  alias Spark.Dsl.Verifier
  alias Spark.Error.DslError
  alias Diffo.Provider.Extension.Info

  @impl true
  def verify(dsl_state) do
    resource = Verifier.get_persisted(dsl_state, :module)
    features = Verifier.get_entities(dsl_state, [:provider, :features])

    duplicate_errors =
      features
      |> Enum.group_by(& &1.name)
      |> Enum.filter(fn {_name, fs} -> length(fs) > 1 end)
      |> Enum.map(fn {name, _} ->
        DslError.exception(
          module: resource,
          path: [:provider, :features],
          message: "features: name #{inspect(name)} is declared more than once"
        )
      end)

    char_errors =
      Enum.reduce(features, [], fn feature, acc ->
        duplicate_char_errors =
          feature.characteristics
          |> Enum.group_by(& &1.name)
          |> Enum.filter(fn {_name, chars} -> length(chars) > 1 end)
          |> Enum.map(fn {name, _} ->
            DslError.exception(
              module: resource,
              path: [:provider, :features, feature.name, :characteristics],
              message:
                "features: characteristic name #{inspect(name)} is declared more than once in #{inspect(feature.name)}"
            )
          end)

        type_errors =
          Enum.reduce(feature.characteristics || [], [], fn char, inner_acc ->
            case module_from_value_type(char.value_type) do
              {:ok, module} ->
                cond do
                  !Code.ensure_loaded?(module) ->
                    [
                      DslError.exception(
                        module: resource,
                        path: [:provider, :features, feature.name, :characteristics, char.name],
                        message:
                          "features: characteristic value_type #{inspect(module)} does not exist"
                      )
                      | inner_acc
                    ]

                  !Info.characteristic?(module) ->
                    [
                      DslError.exception(
                        module: resource,
                        path: [:provider, :features, feature.name, :characteristics, char.name],
                        message:
                          "features: characteristic value_type #{inspect(module)} does not extend BaseCharacteristic"
                      )
                      | inner_acc
                    ]

                  true ->
                    inner_acc
                end

              :error ->
                inner_acc
            end
          end)

        acc ++ duplicate_char_errors ++ type_errors
      end)

    case duplicate_errors ++ char_errors do
      [] -> :ok
      errors -> {:error, errors}
    end
  end

  defp module_from_value_type({:array, module}) when is_atom(module), do: {:ok, module}
  defp module_from_value_type(module) when is_atom(module), do: {:ok, module}
  defp module_from_value_type(_), do: :error
end
