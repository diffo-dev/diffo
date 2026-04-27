# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Instance.Specification do
  @moduledoc false
  require Logger

  alias Diffo.Provider
  alias Diffo.Provider.Instance
  alias Diffo.Provider.Instance.Extension.Info

  @doc """
  Struct for a Specification
  """
  defstruct [:id, :name, :type, :major_version, :category]

  @doc """
  Sets the specified_by argument in the changeset, ensuring the Extended Instance's specification exists
  """
  def set_specified_by_argument(changeset) when is_struct(changeset, Ash.Changeset) do
    %module{} = changeset.data
    # ensure the specification exists
    case upsert_specification(module) do
      {:ok, specification} ->
        Ash.Changeset.force_set_argument(changeset, :specified_by, specification.id)

      {:error, error} ->
        Ash.Changeset.add_error(changeset, error)
    end
  end

  @doc """
  Upserts the Specification from a Extended Instance's module
  """
  def upsert_specification(module) when is_atom(module) do
    options = Info.specification_options(module)
    specification = struct(__MODULE__, options)

    case Provider.create_specification(Map.from_struct(specification)) do
      {:ok, _result} ->
        {:ok, specification}

      {:error, error} ->
        {:error, error}
    end
  end

  @doc """
  Relates a specification to the Extended Instance
  """
  def relate_instance(result, changeset)
      when is_struct(result) and is_struct(changeset, Ash.Changeset) do
    specified_by = Ash.Changeset.get_argument(changeset, :specified_by)
    Provider.specify_instance(%Instance{id: result.id}, %{specified_by: specified_by})
  end

  defimpl String.Chars do
    def to_string(struct) do
      inspect(struct)
    end
  end
end
