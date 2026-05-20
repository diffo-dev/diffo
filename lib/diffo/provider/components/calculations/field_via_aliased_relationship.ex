# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Calculations.FieldViaAliasedRelationship do
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
      |> traverse(alias_name)
      |> Enum.flat_map(fn target_id ->
        Diffo.Provider.Instance
        |> Ash.Query.filter_input(id: target_id)
        |> Ash.read!(domain: Diffo.Provider)
        |> Enum.map(&Map.get(&1, field))
      end)
    end)
  end

  defp traverse(id, nil) do
    Diffo.Provider.DefinedSimpleRelationship
    |> Ash.Query.filter_input(source_id: id)
    |> Ash.read!(domain: Diffo.Provider)
    |> Enum.map(& &1.target_id)
  end

  defp traverse(id, alias_name) do
    Diffo.Provider.DefinedSimpleRelationship
    |> Ash.Query.filter_input(source_id: id, alias: alias_name)
    |> Ash.read!(domain: Diffo.Provider)
    |> Enum.map(& &1.target_id)
  end
end
