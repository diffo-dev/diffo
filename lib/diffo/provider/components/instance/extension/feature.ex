# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Instance.Feature do
  @moduledoc false
  require Logger

  alias Diffo.Provider
  alias Diffo.Type.Value
  alias AshNeo4j.Resource.Info, as: Neo4jInfo
  alias AshNeo4j.Neo4jHelper

  @doc """
  Struct for a Feature
  """
  defstruct [:name, :is_enabled?, :characteristics, __spark_metadata__: nil]

  @doc """
  Sets the Extended Instances features argument in the changeset, creating the features and feature characteristics
  """
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
    relate_to_instance(result, features)
  end

  # Directly create HAS edges rather than going through manage_relationship,
  # for the same reason as Characteristic: the accessing_from path breaks because
  # Feature's belongs_to :instance targets Diffo.Provider.Instance, not the
  # domain-specific concrete resource (ShelfInstance etc.).
  defp relate_to_instance(result, nil), do: {:ok, result}
  defp relate_to_instance(result, []), do: {:ok, result}

  defp relate_to_instance(result, feature_ids) do
    instance_label_pair = Neo4jInfo.label_pair(result.__struct__)
    feature_label = Neo4jInfo.label(Diffo.Provider.Feature)

    Enum.reduce_while(feature_ids, {:ok, result}, fn feature_id, acc ->
      case Neo4jHelper.relate_nodes(
             instance_label_pair,
             %{uuid: result.id},
             feature_label,
             %{uuid: feature_id},
             :HAS,
             :outgoing
           ) do
        {:ok, _} -> {:cont, acc}
        {:error, error} -> {:halt, {:error, error}}
      end
    end)
  end

  defimpl String.Chars do
    def to_string(struct) do
      inspect(struct)
    end
  end
end
