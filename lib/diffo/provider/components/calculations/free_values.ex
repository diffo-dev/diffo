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
          Diffo.Provider.AssignedToRelationship
          |> Ash.Query.filter_input(
            source_id: record.instance_id,
            pool: record.name,
            thing: record.thing
          )
          |> Ash.read!(domain: Diffo.Provider)
          |> length()

        record.last - record.first + 1 - count
    end)
  end
end
