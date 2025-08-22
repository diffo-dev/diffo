defmodule Diffo.Provider.Instance.Party do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  Party for Instance Extension
  """

  alias Diffo.Provider

  @doc """
  Struct for a Party
  """
  defstruct [:id, :role]

  @doc """
  Ensures the parties involve the Extended Instance
  """
  def involve_instance(result, changeset) when is_struct(result) and is_struct(changeset, Ash.Changeset) do
    parties = Ash.Changeset.get_argument(changeset, :parties)
    party_refs = Enum.reduce_while(parties, [],
      fn %{id: id, role: role}, acc ->
        case Provider.create_party_ref(%{instance_id: result.id, party_id: id, role: role}) do
          {:ok, party_ref} ->
            {:cont, [party_ref | acc]}
          {:error, _error} ->
            {:halt, []}
        end
      end)
    case party_refs do
      [] ->
        {:error, "couldn't relate parties"}
      _ ->
        #sorted = Ash.Sort.runtime_sort(party_refs, [role: :asc, inserted_at: :desc])
        {:ok, result |> Map.put(:parties, party_refs)}
    end
  end
end
