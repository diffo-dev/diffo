# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Calculations.SpecificationHref do
  use Ash.Resource.Calculation

  @moduledoc false
  @impl true
  def load(_query, _opts, _context), do: [:type, :tmf_version, :id]

  @impl true
  def calculate(records, _opts, _context) do
    Enum.map(records, fn
      %{type: :serviceSpecification, tmf_version: tmf_version, id: id} ->
        "serviceCatalogManagement/v#{tmf_version}/serviceSpecification/#{id}"

      %{type: :resourceSpecification, tmf_version: tmf_version, id: id} ->
        "resourceCatalogManagement/v#{tmf_version}/resourceSpecification/#{id}"

      _ ->
        nil
    end)
  end
end
