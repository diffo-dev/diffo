# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Calculations.SpecificationInstanceType do
  @moduledoc false
  use Ash.Resource.Calculation

  @impl true
  def load(_query, _opts, _context), do: [:type]

  @impl true
  def calculate(records, _opts, _context) do
    Enum.map(records, fn record ->
      case record.type do
        :serviceSpecification -> :service
        :resourceSpecification -> :resource
        _ -> nil
      end
    end)
  end
end
