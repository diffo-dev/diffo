# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Unwrap.AshCustomExpression do
  @moduledoc false

  use Ash.CustomExpression,
    name: :unwrap,
    arguments: [
      [:term]
    ]

  def expression(_data_layer, term) do
    {:ok, expr(fragment(&__MODULE__.unwrap/1, ^term))}
  end

  @doc "Unwraps a term using the Diffo.Unwrap protocol"
  def unwrap(term) do
    Diffo.Unwrap.unwrap(term)
  end
end
