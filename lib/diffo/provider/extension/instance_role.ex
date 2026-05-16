# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Extension.InstanceRole do
  @moduledoc "DSL entity declaring a role a Party or Place kind plays with respect to Instances"
  defstruct [:role, :instance_type, :reference, __spark_metadata__: nil]

  defimpl String.Chars do
    def to_string(struct), do: inspect(struct)
  end
end
