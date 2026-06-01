# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Calculations.Traversal do
  @moduledoc """
  Runtime graph walk for a normalised `via:` hop list.

  Threads a set of instance ids through each hop in order, following one edge per hop:

  - `:forward` — filter `source_id` in the current ids, collect `target_id`s.
  - `:reverse` — filter `target_id` in the current ids, collect `source_id`s.

  over `AssignmentRelationship` (`:assignment` hops) or `DefinedSimpleRelationship`
  (`:relationship` hops). A hop may fan out (reach many instances) or fan in (several
  intermediates reach the same instance); ids are de-duplicated between hops so a node
  reached by multiple paths is visited once.

  Hops are the canonical form produced by `Diffo.Provider.Extension.Traversal.normalize/2`:
  `{:forward | :reverse, :assignment | :relationship, selector}`. Built so
  `inherited_place` / `inherited_party` can adopt the same grammar later.
  """
  alias Diffo.Provider.AssignmentRelationship
  alias Diffo.Provider.DefinedSimpleRelationship

  @doc """
  Walks `hops` from `start_id`, returning the de-duplicated list of final instance ids.

  An empty `hops` list returns `[start_id]`.
  """
  def walk(start_id, hops) do
    Enum.reduce(hops, [start_id], fn hop, ids ->
      ids
      |> Enum.flat_map(&step(hop, &1))
      |> Enum.uniq()
    end)
  end

  defp step({direction, :assignment, %{alias: alias}}, id),
    do: edge_ids(AssignmentRelationship, direction, id, alias_filter(alias))

  defp step({direction, :relationship, %{type: type, alias: alias}}, id),
    do: edge_ids(DefinedSimpleRelationship, direction, id, relationship_filter(type, alias))

  defp edge_ids(resource, :forward, id, filter) do
    resource
    |> Ash.Query.filter_input([source_id: id] ++ filter)
    |> Ash.read!(domain: Diffo.Provider)
    |> Enum.map(& &1.target_id)
  end

  defp edge_ids(resource, :reverse, id, filter) do
    resource
    |> Ash.Query.filter_input([target_id: id] ++ filter)
    |> Ash.read!(domain: Diffo.Provider)
    |> Enum.map(& &1.source_id)
  end

  defp alias_filter(nil), do: []
  defp alias_filter(alias), do: [alias: alias]

  defp relationship_filter(type, alias) do
    []
    |> maybe_put(:type, type)
    |> maybe_put(:alias, alias)
  end

  defp maybe_put(filter, _key, nil), do: filter
  defp maybe_put(filter, key, value), do: Keyword.put(filter, key, value)
end
