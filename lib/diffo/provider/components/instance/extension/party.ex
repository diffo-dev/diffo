# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Instance.Party do
  @moduledoc false
  alias Diffo.Provider

  @doc """
  Struct for a Party
  """
  defstruct [:id, :role]

  @doc false
  def validate_parties(changeset, declarations) do
    if declarations == [] do
      changeset
    else
      parties = Ash.Changeset.get_argument(changeset, :parties) || []
      changeset
      |> validate_roles(parties, declarations)
      |> validate_constraints(parties, declarations)
    end
  end

  defp validate_roles(changeset, parties, declarations) do
    declared_roles = MapSet.new(declarations, & &1.role)

    Enum.reduce(parties, changeset, fn %{role: role}, cs ->
      if MapSet.member?(declared_roles, role) do
        cs
      else
        Ash.Changeset.add_error(cs,
          field: :parties,
          message: "role #{inspect(role)} is not declared on this resource"
        )
      end
    end)
  end

  defp validate_constraints(changeset, parties, declarations) do
    counts = Enum.frequencies_by(parties, & &1.role)

    declarations
    |> Enum.reject(&(&1.reference || &1.calculate))
    |> Enum.reduce(changeset, fn decl, cs ->
      count = Map.get(counts, decl.role, 0)
      constraints = decl.constraints || []

      cs
      |> check_min(decl.role, count, Keyword.get(constraints, :min))
      |> check_max(decl.role, count, Keyword.get(constraints, :max))
    end)
  end

  defp check_min(cs, _role, _count, nil), do: cs
  defp check_min(cs, _role, count, min) when count >= min, do: cs
  defp check_min(cs, role, count, min),
    do: Ash.Changeset.add_error(cs, field: :parties,
          message: "role #{inspect(role)} requires at least #{min} (got #{count})")

  defp check_max(cs, _role, _count, nil), do: cs
  defp check_max(cs, _role, count, max) when count <= max, do: cs
  defp check_max(cs, role, count, max),
    do: Ash.Changeset.add_error(cs, field: :parties,
          message: "role #{inspect(role)} allows at most #{max} (got #{count})")

  @doc """
  Relates the parties in the changeset with the Extended Instance by creating party_ref
  """
  def relate_instance(result, changeset)
      when is_struct(result) and is_struct(changeset, Ash.Changeset) do
    parties = Ash.Changeset.get_argument(changeset, :parties)

    case parties do
      nil ->
        {:ok, result}

      [] ->
        {:ok, result}

      _ ->
        party_refs =
          Enum.reduce_while(parties, [], fn %{id: id, role: role}, acc ->
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
            # sorted = Ash.Sort.runtime_sort(party_refs, [role: :asc, created_at: :desc])
            {:ok, result |> Map.put(:parties, party_refs)}
        end
    end
  end
end
