# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Extension.Verifiers.VerifyCharacteristics do
  @moduledoc "Verifies characteristic names are unique and value_type modules exist and extend BaseCharacteristic"
  use Spark.Dsl.Verifier

  alias Spark.Dsl.Verifier
  alias Spark.Error.DslError
  alias Diffo.Provider.Extension.Characteristic
  alias Diffo.Provider.Extension.InheritedCharacteristicDeclaration
  alias Diffo.Provider.Extension.Info
  alias Diffo.Provider.Extension.Traversal

  @impl true
  def verify(dsl_state) do
    resource = Verifier.get_persisted(dsl_state, :module)

    entities = Verifier.get_entities(dsl_state, [:provider, :characteristics])

    # The :characteristics section also holds inherited_characteristic declarations,
    # whose structs carry neither :name (as a value name) nor :value_type. The
    # name-uniqueness and value_type checks below apply only to plain `characteristic`
    # entities, so filter to those first (cf. #183).
    characteristics = Enum.filter(entities, &is_struct(&1, Characteristic))

    duplicate_errors =
      characteristics
      |> Enum.group_by(& &1.name)
      |> Enum.filter(fn {_name, chars} -> length(chars) > 1 end)
      |> Enum.map(fn {name, _} ->
        DslError.exception(
          module: resource,
          path: [:provider, :characteristics],
          message: "characteristics: name #{inspect(name)} is declared more than once"
        )
      end)

    type_errors =
      Enum.reduce(characteristics, [], fn char, acc ->
        case module_from_value_type(char.value_type) do
          {:ok, module} ->
            cond do
              !Code.ensure_loaded?(module) ->
                [
                  DslError.exception(
                    module: resource,
                    path: [:provider, :characteristics, char.name],
                    message: "characteristics: value_type #{inspect(module)} does not exist"
                  )
                  | acc
                ]

              !Info.characteristic?(module) ->
                [
                  DslError.exception(
                    module: resource,
                    path: [:provider, :characteristics, char.name],
                    message:
                      "characteristics: value_type #{inspect(module)} does not extend BaseCharacteristic"
                  )
                  | acc
                ]

              true ->
                acc
            end

          :error ->
            acc
        end
      end)

    via_errors =
      entities
      |> Enum.filter(&is_struct(&1, InheritedCharacteristicDeclaration))
      |> Enum.reduce([], fn decl, acc ->
        case Traversal.normalize(decl.via, decl.name) do
          {:ok, _hops} ->
            acc

          {:error, reason} ->
            [
              DslError.exception(
                module: resource,
                path: [:provider, :characteristics, decl.name],
                message:
                  "inherited_characteristic #{inspect(decl.name)}: invalid via — #{inspect(reason)}"
              )
              | acc
            ]
        end
      end)

    case duplicate_errors ++ type_errors ++ via_errors do
      [] -> :ok
      errors -> {:error, errors}
    end
  end

  defp module_from_value_type({:array, module}) when is_atom(module), do: {:ok, module}
  defp module_from_value_type(module) when is_atom(module), do: {:ok, module}
  defp module_from_value_type(_), do: :error
end
