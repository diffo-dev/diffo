defmodule Diffo.Provider.Instance.Characteristic do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  Characteristic for Instance Extension
  """

  require Logger

  alias Diffo.Provider
  alias Diffo.Provider.Instance
  alias Diffo.Provider.Instance.Extension.Info

  @doc """
  Struct for a Characteristic
  """
  defstruct [:name, :value_type]

  @doc """
  Sets the Extended Instances characteristics argument in the changeset, creating the characteristics
  """
  def set_characteristics_argument(changeset) when is_struct(changeset, Ash.Changeset) do
    %module{} = changeset.data
    case characteristics = create_characteristics(module, :instance) do
      [] ->
        Logger.error("couldn't create require characteristics")
        changeset
      _ ->
        characteristic_ids = Enum.map(characteristics, &Map.get(&1, :id))
        Ash.Changeset.force_set_argument(changeset, :characteristics, characteristic_ids)
    end
  end

  @doc """
  Creates the Characteristics from a Extended Instance's module
  """
  def create_characteristics(module, type) when is_atom(module) and is_atom(type)do
    characteristics = Info.characteristics(module)
    Enum.reduce_while(characteristics, [],
      fn %{name: name, value_type: value_type}, acc ->
        value = struct(value_type)
        case Provider.create_characteristic(%{name: name, type: type, value: value}) do
          {:ok, result} ->
            {:cont, [result | acc]}
          {:error, _error} ->
            {:halt, []}
        end
      end)
  end

  @doc """
  Relates the characteristics in the changeset with the Extended Instance
  """
  def relate_instance(result, changeset) when is_struct(result) and is_struct(changeset, Ash.Changeset) do
    characteristics = Ash.Changeset.get_argument(changeset, :characteristics)
    instance = struct(Instance, Map.from_struct(result))
    Provider.relate_instance_characteristics(instance, %{characteristics: characteristics})
  end

  defimpl String.Chars do
    def to_string(struct) do
      inspect(struct)
    end
  end
end
