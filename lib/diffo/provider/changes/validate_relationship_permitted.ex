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
      rels -> changeset |> validate_source_roles(rels) |> validate_target_roles(rels)
    end
  end

  defp validate_source_roles(changeset, rels) do
    permitted = changeset.resource.permitted_source_roles()

    Enum.reduce(rels, changeset, fn rel, cs ->
      case check_permitted(rel_alias(rel), permitted, :source) do
        :ok -> cs
        {:error, msg} -> Ash.Changeset.add_error(cs, msg)
      end
    end)
  end

  defp validate_target_roles(changeset, rels) do
    spec_id_to_module = build_spec_id_map(changeset.domain)

    Enum.reduce(rels, changeset, fn rel, cs ->
      target_id = Map.get(rel, :id) || Map.get(rel, "id")

      case resolve_target_module(target_id, spec_id_to_module, changeset.domain) do
        {:ok, module} ->
          case check_permitted(rel_alias(rel), module.permitted_target_roles(), :target) do
            :ok -> cs
            {:error, msg} -> Ash.Changeset.add_error(cs, msg)
          end

        :error ->
          Ash.Changeset.add_error(
            cs,
            "could not resolve target resource for id #{inspect(target_id)}"
          )
      end
    end)
  end

  # Builds a map of %{spec_uuid => module} from all Instance resource modules in the
  # domain that have both permitted_target_roles/0 and specification/0 baked by the
  # provider extension. Used for O(1) module lookup after resolving the target's spec id.
  defp build_spec_id_map(domain) do
    domain
    |> Ash.Domain.Info.resources()
    |> Enum.filter(
      &(function_exported?(&1, :permitted_target_roles, 0) and
          function_exported?(&1, :specification, 0))
    )
    |> Map.new(fn module -> {module.specification()[:id], module} end)
  end

  # Fetches the specification UUID for the target instance via a direct Cypher query,
  # then does an O(1) lookup in spec_id_to_module to find the resource module.
  defp resolve_target_module(id, spec_id_to_module, _domain) do
    case AshNeo4j.Cypher.run(
           "MATCH (n:Instance {uuid: $uuid})-[:SPECIFIED_BY]->(s) RETURN s.uuid AS spec_id",
           %{"uuid" => id}
         ) do
      {:ok, %{results: [%{"spec_id" => spec_uuid} | _]}} ->
        case Map.get(spec_id_to_module, spec_uuid) do
          nil -> :error
          module -> {:ok, module}
        end

      {:ok, %{results: []}} ->
        :error

      {:error, _} ->
        :error
    end
  end

  defp rel_alias(rel), do: Map.get(rel, :alias) || Map.get(rel, "alias")

  defp check_permitted(_role, :all, _direction), do: :ok

  defp check_permitted(_role, :none, :source),
    do: {:error, "relationships are not permitted as source on this resource"}

  defp check_permitted(_role, :none, :target),
    do: {:error, "relationships are not permitted as target on this resource"}

  defp check_permitted(role, roles, direction) when is_list(roles) do
    if role in roles do
      :ok
    else
      {:error,
       "relationship role #{inspect(role)} is not permitted as #{direction} on this resource"}
    end
  end
end
