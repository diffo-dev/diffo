# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Calculations.PoolCharacteristics do
  @moduledoc """
  Loads the `AssignableCharacteristic` pool records associated with an
  instance, one per `pool :name, :thing` declaration on the resource module.

  Used by `BaseInstance` to surface pool characteristics alongside the
  dynamic `Diffo.Provider.Characteristic` records in the
  `serviceCharacteristic` / `resourceCharacteristic` JSON view (#169).
  """
  use Ash.Resource.Calculation

  @impl true
  def load(_query, _opts, _context), do: []

  @impl true
  def calculate(records, _opts, _context) do
    Enum.map(records, fn record ->
      if function_exported?(record.__struct__, :pools, 0) and record.__struct__.pools() != [] do
        Diffo.Provider.AssignableCharacteristic
        |> Ash.Query.filter_input(instance_id: record.id)
        |> Ash.read!(domain: Diffo.Provider)
      else
        []
      end
    end)
  end
end
