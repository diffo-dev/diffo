# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Instance.Specification do
  @moduledoc false

  alias Diffo.Provider

  @doc """
  Struct for a Specification
  """
  defstruct [
    :id,
    :name,
    :type,
    :major_version,
    :minor_version,
    :patch_version,
    :tmf_version,
    :description,
    :category
  ]

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

    # Clear specification_id so manage_relationship sees nil→id (add only, no spurious remove).
    # action_helper pre-sets specification_id before calling us, which would make
    # Ash treat old==new and generate an empty-argument remove that fails.
    %{result | specification_id: nil}
    |> Ash.Changeset.for_update(:specify, %{specified_by: specified_by})
    |> Ash.update()
  end

  defimpl String.Chars do
    def to_string(struct) do
      inspect(struct)
    end
  end
end
