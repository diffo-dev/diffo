# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Calculations.InheritedPlace do
  @moduledoc """
  Backing calculation for `inherited_place` DSL declarations.

  Traverses `AssignmentRelationship` by alias to reach source instances, then reads
  their `PlaceRef` records for the declared `source_role`. Injected automatically by
  `TransformInheritedRefs` — do not reference this module directly; use the
  `inherited_place` DSL entity instead.

  See `Diffo.Provider.Extension.InheritedPlaceDeclaration` for the DSL options.
  """
  use Ash.Resource.Calculation

  @impl true
  def load(_query, _opts, _context), do: []

  @impl true
  def calculate(records, opts, _context) do
    via = opts[:via]
    source_role = opts[:source_role]

    Enum.map(records, fn record ->
      final_ids =
        Enum.reduce(via, [record.id], fn alias_step, ids ->
          Enum.flat_map(ids, fn id ->
            Diffo.Provider.AssignmentRelationship
            |> Ash.Query.filter_input(target_id: id, alias: alias_step)
            |> Ash.read!(domain: Diffo.Provider)
            |> Enum.map(& &1.source_id)
          end)
        end)

      Enum.flat_map(final_ids, fn id ->
        Diffo.Provider.PlaceRef
        |> Ash.Query.filter_input(instance_id: id, role: source_role)
        |> Ash.Query.load(:place)
        |> Ash.read!(domain: Diffo.Provider)
        |> Enum.map(& &1.place)
      end)
    end)
  end
end
