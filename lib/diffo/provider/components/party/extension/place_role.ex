# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Party.Extension.PlaceRole do
  @moduledoc """
  PlaceRole - DSL entity declaring a role this Party kind plays with respect to Places
  """
  defstruct [:role, :place_type, __spark_metadata__: nil]

  defimpl String.Chars do
    def to_string(struct), do: inspect(struct)
  end
end
