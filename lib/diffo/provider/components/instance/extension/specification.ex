# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Instance.Specification do
  @moduledoc false
  require Logger

  alias Diffo.Provider
  alias Diffo.Provider.Instance

  @doc """
  Struct for a Specification
  """
  defstruct [:id, :name, :type, :major_version, :minor_version, :patch_version, :tmf_version, :description, :category]

  @doc """
  Sets the specified_by argument in the changeset, ensuring the Extended Instance's specification exists
  """
  def set_specified_by_argument(changeset, options)
      when is_struct(changeset, Ash.Changeset) and is_list(options) do
    specification = struct(__MODULE__, options)

    attrs = specification |> Map.from_struct() |> Map.reject(fn {_, v} -> is_nil(v) end)

    case Provider.create_specification(attrs) do
      {:ok, _} ->
        Ash.Changeset.force_set_argument(changeset, :specified_by, specification.id)

      {:error, error} ->
        Ash.Changeset.add_error(changeset, error)
    end
  end

  @doc """
  Relates a specification to the Extended Instance
  """
  def relate_instance(result, changeset)
      when is_struct(result) and is_struct(changeset, Ash.Changeset) do
    specified_by = Ash.Changeset.get_argument(changeset, :specified_by)
    Provider.respecify_instance(%Instance{id: result.id}, %{specified_by: specified_by})
  end

  defimpl String.Chars do
    def to_string(struct) do
      inspect(struct)
    end
  end
end
