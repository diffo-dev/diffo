# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Calculations.FieldViaAssignedRelationship do
  @moduledoc false
  use Ash.Resource.Calculation

  @impl true
  def load(_query, _opts, _context), do: []

  @impl true
  def calculate(records, opts, _context) do
    via = opts[:via]
    field = opts[:field]

    Enum.map(records, fn record ->
      record.id
      |> traverse(via)
      |> Enum.flat_map(fn source_id ->
        Diffo.Provider.Instance
        |> Ash.Query.filter_input(id: source_id)
        |> Ash.read!(domain: Diffo.Provider)
        |> Enum.map(&Map.get(&1, field))
      end)
    end)
  end

  defp traverse(id, nil) do
    Diffo.Provider.AssignmentRelationship
    |> Ash.Query.filter_input(target_id: id)
    |> Ash.read!(domain: Diffo.Provider)
    |> Enum.map(& &1.source_id)
  end

  defp traverse(id, via) do
    Enum.reduce(via, [id], fn alias_step, ids ->
      Enum.flat_map(ids, fn i ->
        Diffo.Provider.AssignmentRelationship
        |> Ash.Query.filter_input(target_id: i, alias: alias_step)
        |> Ash.read!(domain: Diffo.Provider)
        |> Enum.map(& &1.source_id)
      end)
    end)
  end
end
