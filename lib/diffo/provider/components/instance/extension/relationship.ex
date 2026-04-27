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
        created_relationships =
          Enum.reduce_while(relationships, [], fn %{
                                                    id: id,
                                                    alias: name,
                                                    type: type,
                                                    direction: direction
                                                  },
                                                  acc ->
            case direction do
              :reverse ->
                case Provider.create_relationship(%{
                       source_id: id,
                       party_id: result.id,
                       alias: name,
                       type: type
                     }) do
                  {:ok, relationship} ->
                    {:cont, [relationship | acc]}

                  {:error, _error} ->
                    {:halt, []}
                end

              _ ->
                # default :forward
                case Provider.create_relationship(%{
                       source_id: result.id,
                       target_id: id,
                       alias: name,
                       type: type
                     }) do
                  {:ok, relationship} ->
                    {:cont, [relationship | acc]}

                  {:error, _error} ->
                    {:halt, []}
                end
            end
          end)

        case created_relationships do
          [] ->
            {:error, "couldn't relate instances"}

          _ ->
            # we haven't put the relationships into the result, they might be forward_relationships or reverse_relationships
            {:ok, result}
        end
    end
  end
end
