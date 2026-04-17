# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Test.Patch do
  @moduledoc false

  use Ash.TypedStruct, extensions: [AshJason.TypedStruct, AshOutstanding.TypedStruct]

  jason do
    pick [:aEnd, :zEnd]
  end

  outstanding do
    expect [:aEnd, :zEnd]
  end

  typed_struct do
    field :aEnd, :integer, constraints: [min: 0]
    field :zEnd, :integer, constraints: [min: 0]
  end
end
