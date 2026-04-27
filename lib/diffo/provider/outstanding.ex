# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Outstanding do
  @moduledoc false
  @doc false
  def instance_list_by_key(outstanding, expected, actual, list, key) do
    # assemble keyword lists of expected and actual lists
    expected_keywords =
      Keyword.new(Map.get(expected, list), fn element -> {Map.get(element, key), element} end)

    actual_keywords =
      Keyword.new(Map.get(actual, list), fn element -> {Map.get(element, key), element} end)

    outstanding_keywords = Outstanding.outstanding(expected_keywords, actual_keywords)

    if outstanding_keywords == nil do
      outstanding
    else
      # accumulate outstanding, with outstanding result back as a list
      if outstanding == nil do
        Map.put(%Diffo.Provider.Instance{}, list, Keyword.values(outstanding_keywords))
      else
        outstanding |> Map.put(list, Keyword.values(outstanding_keywords))
      end
    end
  end
end
