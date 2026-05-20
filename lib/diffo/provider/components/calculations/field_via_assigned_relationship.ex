# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Calculations.FieldViaAssignedRelationship do
  @moduledoc """
  Reads a field from the source instance of an `AssignmentRelationship`.

  Traverses `AssignmentRelationship` in reverse — filtering by `target_id = current.id`
  — to reach the source instances (pool owners) that assigned something to this instance,
  then returns the named field from each.

  ## Options

  - `field:` *(required)* — atom naming the field to read from the source instance
    (e.g. `:name`, `:type`).
  - `via:` *(optional)* — list of alias atoms to step through. Each step filters
    `AssignmentRelationship` by the alias and follows `source_id` to the next set of
    instances. Multi-hop is supported by chaining steps. When omitted, all assignments
    where `target_id = current.id` are traversed without alias filtering.

  ## Examples

      # Name of the CVC that holds the :svlan assignment slot on this AVC
      calculate :cvc_id, {:array, :string},
        {Diffo.Provider.Calculations.FieldViaAssignedRelationship, [via: [:svlan], field: :name]}

      # Name of every instance that has ever assigned anything to this one
      calculate :assigner_names, {:array, :string},
        {Diffo.Provider.Calculations.FieldViaAssignedRelationship, [field: :name]}
  """
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
