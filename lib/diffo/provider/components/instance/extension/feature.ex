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
        feature_ids = Enum.map(features, &Map.get(&1, :id)) |> IO.inspect(label: :feature_ids)
        Ash.Changeset.force_set_argument(changeset, :features, feature_ids)
    end
  end

  @doc """
  Creates the Features from a Extended Instance's module
  """
  def create_features(module) when is_atom(module) do
    features = Info.features(module) |> IO.inspect(label: :features)
    Enum.reduce_while(features, [],
      fn %{name: name, is_enabled?: isEnabled}, acc ->
        # todo create characteristics so they can be related on create feature
        case Provider.create_feature(%{name: name, isEnabled: isEnabled}) do
          {:ok, result} ->
            IO.inspect(result, label: :create_feature_result)
            {:cont, [result | acc]}
          {:error, error} ->
            IO.inspect(error, label: :error)
            {:halt, []}
        end
      end)
  end

  @doc """
  Ensures the features define the Extended Instance
  """
  def define_instance(result, changeset) when is_struct(result) and is_struct(changeset, Ash.Changeset) do
    features = Ash.Changeset.get_argument(changeset, :features)
    instance = struct(Instance, Map.from_struct(result))
    Provider.relate_instance_features(instance, %{features: features}) |> IO.inspect(label: :relate_instance_features)
  end

  defimpl String.Chars do
    def to_string(struct) do
      inspect(struct)
    end
  end
end
