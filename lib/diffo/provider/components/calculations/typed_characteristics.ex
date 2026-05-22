# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Calculations.TypedCharacteristics do
  @moduledoc """
  Loads all typed `BaseCharacteristic`-derived records associated with an
  instance.

  For each `characteristic :role, ValueModule` declaration on the instance's
  resource module — including both singular and `{:array, ValueModule}` forms
  — this calculation queries `ValueModule` by `instance_id == record.id` and
  returns the collected records as a flat list.

  Used by `BaseInstance` to surface typed characteristics alongside the
  dynamic `Diffo.Provider.Characteristic` records in the
  `serviceCharacteristic` / `resourceCharacteristic` JSON view (#169).
  """
  use Ash.Resource.Calculation

  alias Diffo.Provider.Extension.Characteristic, as: CharacteristicHelper

  @impl true
  def load(_query, _opts, _context), do: []

  @impl true
  def calculate(records, _opts, _context) do
    Enum.map(records, fn record ->
      record
      |> typed_value_modules()
      |> Enum.flat_map(fn module ->
        module
        |> Ash.Query.filter_input(instance_id: record.id)
        |> Ash.read!(domain: Diffo.Provider)
      end)
    end)
  end

  defp typed_value_modules(record) do
    module = record.__struct__

    if function_exported?(module, :characteristics, 0) do
      module.characteristics()
      |> Enum.map(fn %{value_type: value_type} ->
        case value_type do
          {:array, mod} -> mod
          mod when is_atom(mod) -> mod
        end
      end)
      |> Enum.uniq()
      |> Enum.filter(&CharacteristicHelper.typed?/1)
    else
      []
    end
  end
end
