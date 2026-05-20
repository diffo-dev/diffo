# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Calculations.FieldViaRelationship do
  @moduledoc false
  use Ash.Resource.Calculation

  @impl true
  def load(_query, _opts, _context), do: []

  @impl true
  def calculate(records, opts, _context) do
    alias_name = opts[:alias]
    type = opts[:type]
    field = opts[:field]

    Enum.map(records, fn record ->
      filter = [source_id: record.id]
      filter = if type, do: Keyword.put(filter, :type, type), else: filter
      filter = if alias_name, do: Keyword.put(filter, :alias, alias_name), else: filter

      Diffo.Provider.DefinedSimpleRelationship
      |> Ash.Query.filter_input(filter)
      |> Ash.read!(domain: Diffo.Provider)
      |> Enum.flat_map(fn rel ->
        Diffo.Provider.Instance
        |> Ash.Query.filter_input(id: rel.target_id)
        |> Ash.read!(domain: Diffo.Provider)
        |> Enum.map(&Map.get(&1, field))
      end)
    end)
  end
end
