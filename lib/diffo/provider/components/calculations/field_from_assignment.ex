# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Calculations.FieldFromAssignment do
  @moduledoc false
  use Ash.Resource.Calculation

  @impl true
  def load(_query, _opts, _context), do: []

  @impl true
  def calculate(records, opts, _context) do
    alias_name = opts[:alias]
    field = opts[:field]

    Enum.map(records, fn record ->
      record.id
      |> assignments(alias_name)
      |> Enum.map(&Map.get(&1, field))
    end)
  end

  defp assignments(id, nil) do
    Diffo.Provider.AssignmentRelationship
    |> Ash.Query.filter_input(target_id: id)
    |> Ash.read!(domain: Diffo.Provider)
  end

  defp assignments(id, alias_name) do
    Diffo.Provider.AssignmentRelationship
    |> Ash.Query.filter_input(target_id: id, alias: alias_name)
    |> Ash.read!(domain: Diffo.Provider)
  end
end
