# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Validations.ValidateRelationshipPermitted do
  @moduledoc false
  use Ash.Resource.Validation

  @impl true
  def init(opts), do: {:ok, opts}

  @impl true
  def validate(changeset, _opts, _context) do
    case Ash.Changeset.get_argument(changeset, :relationships) do
      nil -> :ok
      [] -> :ok
      rels -> check(changeset, rels)
    end
  end

  defp check(changeset, rels) do
    case source_errors(changeset, rels) ++ target_errors(changeset, rels) do
      [] -> :ok
      errors -> {:error, errors}
    end
  end

  defp source_errors(changeset, rels) do
    permitted = changeset.resource.permitted_source_roles()

    Enum.flat_map(rels, fn rel ->
      case check_permitted(rel_alias(rel), permitted, :source) do
        :ok -> []
        {:error, msg} -> [[field: :relationships, message: msg]]
      end
    end)
  end

  defp target_errors(changeset, rels) do
    spec_id_to_module = build_spec_id_map(changeset.domain)

    Enum.flat_map(rels, fn rel ->
      target_id = Map.get(rel, :id) || Map.get(rel, "id")

      case resolve_target_module(target_id, spec_id_to_module) do
        {:ok, module} ->
          case check_permitted(rel_alias(rel), module.permitted_target_roles(), :target) do
            :ok -> []
            {:error, msg} -> [[field: :relationships, message: msg]]
          end

        :error ->
          [[field: :relationships, message: "could not resolve target resource for id #{inspect(target_id)}"]
          ]
      end
    end)
  end

  defp build_spec_id_map(domain) do
    domain
    |> Ash.Domain.Info.resources()
    |> Enum.filter(
      &(function_exported?(&1, :permitted_target_roles, 0) and
          function_exported?(&1, :specification, 0))
    )
    |> Map.new(fn module -> {module.specification()[:id], module} end)
  end

  defp resolve_target_module(id, spec_id_to_module) do
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
      {:error, "relationship role #{inspect(role)} is not permitted as #{direction} on this resource"}
    end
  end
end
