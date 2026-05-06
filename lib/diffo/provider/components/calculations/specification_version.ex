# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Calculations.SpecificationVersion do
  @moduledoc false
  use Ash.Resource.Calculation

  @impl true
  def load(_query, _opts, _context), do: [:major_version, :minor_version, :patch_version]

  @impl true
  def calculate(records, _opts, _context) do
    Enum.map(records, fn
      %{major_version: maj, minor_version: min, patch_version: patch} ->
        "v#{maj}.#{min}.#{patch}"

      _ ->
        nil
    end)
  end
end
