# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Calculations.FreeValues do
  @moduledoc false
  use Ash.Resource.Calculation

  @impl true
  def load(_query, _opts, _context), do: []

  @impl true
  def calculate(records, _opts, _context) do
    Enum.map(records, fn
      %{thing: nil} ->
        nil

      record ->
        count =
          Diffo.Provider.DefinedSimpleRelationship
          |> Ash.Query.filter_input(source_id: record.instance_id, type: :assignedTo)
          |> Ash.read!(domain: Diffo.Provider)
          |> Enum.count(fn rel ->
            rel.characteristic && rel.characteristic.name == record.thing
          end)

        record.last - record.first + 1 - count
    end)
  end
end
