# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Changes.ValidateRelationshipPermitted do
  @moduledoc false
  use Ash.Resource.Change

  @impl true
  def change(changeset, _opts, _context) do
    case Ash.Changeset.get_argument(changeset, :relationships) do
      nil -> changeset
      [] -> changeset
      rels -> validate_source_roles(changeset, rels)
    end
  end

  defp validate_source_roles(changeset, rels) do
    permitted = changeset.resource.permitted_source_roles()

    Enum.reduce(rels, changeset, fn rel, cs ->
      role = Map.get(rel, :alias) || Map.get(rel, "alias")

      case check_permitted(role, permitted) do
        :ok -> cs
        {:error, msg} -> Ash.Changeset.add_error(cs, msg)
      end
    end)
  end

  defp check_permitted(_role, :all), do: :ok

  defp check_permitted(_role, :none),
    do: {:error, "relationships are not permitted as source on this resource"}

  defp check_permitted(role, roles) when is_list(roles) do
    if role in roles do
      :ok
    else
      {:error, "relationship role #{inspect(role)} is not permitted as source on this resource"}
    end
  end
end
