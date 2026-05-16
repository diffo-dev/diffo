# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Extension.PlaceDeclaration do
  @moduledoc "DSL entity declaring a place role on an Instance"
  defstruct [
    :role,
    :place_type,
    :multiple,
    :reference,
    :calculate,
    :constraints,
    __spark_metadata__: nil
  ]

  defimpl String.Chars do
    def to_string(struct), do: inspect(struct)
  end
end
