defmodule Diffo.Provider.Instance.Place do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  Place for Instance Extension
  """

  alias Diffo.Provider

  @doc """
  Struct for a Place
  """
  defstruct [:id, :role]

  @doc """
  Ensures the places locate the Extended Instance
  """
  def locate_instance(result, changeset) when is_struct(result) and is_struct(changeset, Ash.Changeset) do
    places = Ash.Changeset.get_argument(changeset, :places)
    place_refs = Enum.reduce_while(places, [],
      fn %{id: id, role: role}, acc ->
        case Provider.create_place_ref(%{instance_id: result.id, place_id: id, role: role}) do
          {:ok, place_ref} ->
            {:cont, [place_ref | acc]}
          {:error, _error} ->
            {:halt, []}
        end
      end)
    case place_refs do
      [] ->
        {:error, "couldn't relate places"}
      _ ->
        #sorted = Ash.Sort.runtime_sort(place_refs, [role: :asc, inserted_at: :desc])
        {:ok, result |> Map.put(:places, place_refs)}
    end
  end
end
