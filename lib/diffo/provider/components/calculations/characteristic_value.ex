# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Calculations.CharacteristicValue do
  @moduledoc false
  use Ash.Resource.Calculation

  @impl true
  def load(_query, _opts, _context), do: []

  @impl true
  def calculate(records, _opts, _context) do
    Enum.map(records, fn record ->
      value_module = Module.concat(record.__struct__, :Value)
      field_names = value_module |> struct() |> Map.from_struct() |> Map.keys()
      struct(value_module, Map.take(Map.from_struct(record), field_names))
    end)
  end
end
