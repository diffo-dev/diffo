# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Calculations.InstanceHref do
  @moduledoc false
  use Ash.Resource.Calculation

  @impl true
  def load(_query, _opts, _context), do: [:specification]

  @impl true
  def calculate(records, _opts, _context) do
    Enum.map(records, fn record ->
      case record.specification do
        %{tmf_version: tmf_version, type: :serviceSpecification} ->
          "serviceInventoryManagement/v#{tmf_version}/service/#{record.id}"

        %{tmf_version: tmf_version, type: :resourceSpecification} ->
          "resourceInventoryManagement/v#{tmf_version}/resource/#{record.id}"

        _ ->
          nil
      end
    end)
  end
end
