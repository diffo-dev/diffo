defmodule Diffo.Provider.Instance.Feature do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  Feature for Instance Extension
  """

  require Logger

  alias Diffo.Provider
  alias Diffo.Provider.Instance
  alias Diffo.Provider.Instance.Extension.Info

  @doc """
  Struct for a Feature
  """
  defstruct [:name, :is_enabled?, :characteristics]

  @doc """
  Sets the Extended Instances features argument in the changeset, creating the features and feature characteristics
  """
  def set_features_argument(changeset) when is_struct(changeset, Ash.Changeset) do
    %module{} = changeset.data
    case features = create_features(module) do
      [] ->
        Logger.error("couldn't create require features")
        changeset
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
    Enum.reduce_while(features, [],
      # create any feature characteristics
      fn %{name: name, is_enabled?: isEnabled, characteristics: characteristics}, acc ->
        characteristic_ids = Enum.reduce_while(characteristics, [],
          fn %{name: name, value_type: value_type}, acc ->
            value = struct(value_type)
            case Provider.create_characteristic(%{name: name, value: value, type: :feature}) do
              {:ok, result} ->
                {:cont, [result.id | acc]}
              {:error, _error} ->
                {:halt, []}
            end
          end)
        # create feature with feature characteristics
        case Provider.create_feature(%{name: name, isEnabled: isEnabled, characteristics: characteristic_ids}) do
          {:ok, result} ->
            {:cont, [result | acc]}
          {:error, _error} ->
            {:halt, []}
        end
      end)
  end

  @doc """
  Relates the features in the changeset with the Extended Instance
  """
  def relate_instance(result, changeset) when is_struct(result) and is_struct(changeset, Ash.Changeset) do
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
