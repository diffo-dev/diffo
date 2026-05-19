# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Instance.Place do
  @moduledoc false
  alias Diffo.Provider

  @doc """
  Struct for a Place
  """
  defstruct [:id, :role]

  @doc """
  Relates the places in the changeset with the Extended Instance by creating place_ref
  """
  def relate_instance(result, changeset)
      when is_struct(result) and is_struct(changeset, Ash.Changeset) do
    places = Ash.Changeset.get_argument(changeset, :places)

    case places do
      nil ->
        {:ok, result}

      [] ->
        {:ok, result}

      _ ->
        Enum.reduce_while(places, {:ok, []}, fn %{id: id, role: role}, {:ok, acc} ->
          case Provider.create_place_ref(%{instance_id: result.id, place_id: id, role: role}) do
            {:ok, place_ref} -> {:cont, {:ok, [place_ref | acc]}}
            {:error, error} -> {:halt, {:error, error}}
          end
        end)
        |> case do
          {:ok, place_refs} -> {:ok, Map.put(result, :places, place_refs)}
          {:error, error} -> {:error, error}
        end
    end
  end
end
