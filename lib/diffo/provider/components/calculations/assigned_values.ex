# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Calculations.AssignedValues do
  @moduledoc false
  use Ash.Resource.Calculation

  @impl true
  def load(_query, _opts, _context), do: []

  @impl true
  def calculate(records, _opts, context) do
    thing = context.arguments[:thing]

    Enum.map(records, fn record ->
      Diffo.Provider.DefinedSimpleRelationship
      |> Ash.Query.filter_input(source_id: record.instance_id, type: :assignedTo)
      |> Ash.read!(domain: Diffo.Provider)
      |> Enum.filter(fn rel -> rel.characteristic && rel.characteristic.name == thing end)
      |> Enum.map(fn rel -> Diffo.Unwrap.unwrap(rel.characteristic.value) end)
    end)
  end
end
