# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Extension.Feature do
  @moduledoc false
  require Logger

  alias Diffo.Provider
  alias Diffo.Provider.Instance
  alias Diffo.Type.Value

  defstruct [:name, :is_enabled?, :characteristics, __spark_metadata__: nil]

  def set_features_argument(changeset, declarations)
      when is_struct(changeset, Ash.Changeset) and is_list(declarations) do
    case features = create_features_from_declarations(declarations) do
      [] ->
        changeset

      {:error, error} ->
        Ash.Changeset.add_error(changeset, error)

      _ ->
        feature_ids = Enum.map(features, &Map.get(&1, :id))
        Ash.Changeset.force_set_argument(changeset, :features, feature_ids)
    end
  end

  defp create_features_from_declarations(declarations) do
    Enum.reduce_while(
      declarations,
      [],
      fn %{name: name, is_enabled?: isEnabled, characteristics: characteristics}, acc ->
        characteristic_ids =
          Enum.reduce_while(characteristics, [], fn %{name: name, value_type: value_type}, acc ->
            try do
              attrs =
                case value_type do
                  {:array, _inner} ->
                    %{name: name, type: :feature, values: [], is_array: true}

                  module ->
                    %{name: name, type: :feature, value: Value.dynamic(struct(module))}
                end

              case Provider.create_characteristic(attrs) do
                {:ok, result} ->
                  {:cont, [result.id | acc]}

                {:error, error} ->
                  {:halt, {:error, error}}
              end
            rescue
              _e in UndefinedFunctionError ->
                {:halt,
                 {:error,
                  "couldn't create feature characteristic with value of unknown type #{value_type}"}}
            end
          end)

        case characteristic_ids do
          {:error, error} ->
            {:halt, {:error, error}}

          _ ->
            case Provider.create_feature(%{
                   name: name,
                   isEnabled: isEnabled,
                   characteristics: characteristic_ids
                 }) do
              {:ok, result} ->
                {:cont, [result | acc]}

              {:error, error} ->
                {:halt, {:error, error}}
            end
        end
      end
    )
  end

  def relate_instance(result, changeset)
      when is_struct(result) and is_struct(changeset, Ash.Changeset) do
    features = Ash.Changeset.get_argument(changeset, :features)
    Provider.relate_instance_features(%Instance{id: result.id}, %{features: features})
  end

  defimpl String.Chars do
    def to_string(struct), do: inspect(struct)
  end
end
