# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Extension.InheritedPartyDeclaration do
  @moduledoc "DSL entity declaring an inherited party role — derived by traversing the assignment graph"
  defstruct [:role, :via, :source_role, __spark_metadata__: nil]

  defimpl String.Chars do
    def to_string(struct), do: inspect(struct)
  end
end
