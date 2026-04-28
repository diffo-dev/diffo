# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Place.Extension.PlaceRole do
  @moduledoc """
  PlaceRole - DSL entity declaring a role this Place kind plays with respect to other Places
  """
  defstruct [:role, :place_type, __spark_metadata__: nil]

  defimpl String.Chars do
    def to_string(struct), do: inspect(struct)
  end
end
