# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Instance.Relationship do
  @moduledoc false
  alias Diffo.Provider

  @doc """
  Struct for a Relationship
  """
  defstruct [:id, :alias, :type, :direction]

  @doc """
  Relates the instances in the changeset with the Extended Instance by creating relationships
  """
  def relate_instance(result, changeset)
      when is_struct(result) and is_struct(changeset, Ash.Changeset) do
    relationships = Ash.Changeset.get_argument(changeset, :relationships)

    case relationships do
      nil ->
        {:ok, result}

      [] ->
        {:ok, result}

      _ ->
        Enum.reduce_while(relationships, :ok, fn %{
                                                    id: id,
                                                    alias: name,
                                                    type: type,
                                                    direction: direction
                                                  },
                                                  :ok ->
          attrs =
            case direction do
              :reverse -> %{source_id: id, party_id: result.id, alias: name, type: type}
              _ -> %{source_id: result.id, target_id: id, alias: name, type: type}
            end

          case Provider.create_relationship(attrs) do
            {:ok, _} -> {:cont, :ok}
            {:error, error} -> {:halt, {:error, error}}
          end
        end)
        |> case do
          :ok -> {:ok, result}
          {:error, error} -> {:error, error}
        end
    end
  end
end
