defmodule Diffo.Provider.Instance.Extension.Specification do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  Specification for Instance Extension
  """
  require Logger

  alias Diffo.Provider
  alias Diffo.Provider.Instance
  alias Diffo.Provider.Instance.Extension.Info

  @doc """
  Struct for a Specification
  """
  defstruct [:id, :name, :type, :major_version, :category]

  @doc """
  Sets the specified_by argument in the changeset, ensuring the specification exists
  """
  def set_specified_by_argument(changeset) when is_struct(changeset, Ash.Changeset) do
    %module{} = changeset.data
    case upsert_specification(module) do
      {:ok, specification} ->
        Ash.Changeset.force_set_argument(changeset, :specified_by, specification.id)
      {:error, _error} ->
        Logger.error("couldn't find/create required specification")
    end
  end

  @doc """
  Upserts the Specification from a Extended Instance's module
  """
  def upsert_specification(module) when is_atom(module) do
    options = Info.specification_options(module)
    specification = struct(__MODULE__,  options)
    case Provider.create_specification(Map.from_struct(specification)) do
      {:ok, _result} ->
        {:ok, specification}
      {:error, error} ->
        {:error, error}
    end
  end

  @doc """
  Ensures the specified_by specification is related to the Extended Instance
  """
  def specify_instance(changeset, result) when is_struct(changeset, Ash.Changeset) and is_struct(result) do
    specified_by = Ash.Changeset.get_argument(changeset, :specified_by)
    instance = struct(Instance, Map.from_struct(result)) |> IO.inspect(label: :instance)
    case Provider.specify_instance(instance, %{specified_by: specified_by}) do
      {:ok, specification} ->
        {:ok, result |> Map.put(:specification, specification) |> Map.put(:specification_id, specified_by)}
      {:error, _error} ->
        {:error, "couldn't relate specification"}
    end
  end

  defimpl String.Chars do
    def to_string(struct) do
      inspect(struct)
    end
  end
end
