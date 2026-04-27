# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Instance.Feature do
  @moduledoc false
  require Logger

  alias Diffo.Provider
  alias Diffo.Provider.Instance
  alias Diffo.Provider.Instance.Extension.Info
  alias Diffo.Type.Value

  @doc """
  Struct for a Feature
  """
  defstruct [:name, :is_enabled?, :characteristics, __spark_metadata__: nil]

  @doc """
  Sets the Extended Instances features argument in the changeset, creating the features and feature characteristics
  """
  def set_features_argument(changeset) when is_struct(changeset, Ash.Changeset) do
    %module{} = changeset.data

    case features = create_features(module) do
      [] ->
        changeset

      {:error, error} ->
        Ash.Changeset.add_error(changeset, error)

      _ ->
        feature_ids = Enum.map(features, &Map.get(&1, :id))
        Ash.Changeset.force_set_argument(changeset, :features, feature_ids)
    end
  end

  @doc """
  Creates the Features from a Extended Instance's module
  """
  def create_features(module) when is_atom(module) do
    features = Info.features(module)

    Enum.reduce_while(
      features,
      [],
      # create any feature characteristics
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
            # create feature with feature characteristics
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

  @doc """
  Relates the features in the changeset with the Extended Instance
  """
  def relate_instance(result, changeset)
      when is_struct(result) and is_struct(changeset, Ash.Changeset) do
    features = Ash.Changeset.get_argument(changeset, :features)
    instance = struct(Instance, Map.from_struct(result))
    Provider.relate_instance_features(instance, %{features: features})
  end

  defimpl String.Chars do
    def to_string(struct) do
      inspect(struct)
    end
  end
end
