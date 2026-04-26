# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Party.Extension.InstanceRole do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  InstanceRole - DSL entity declaring a role this Party kind plays with respect to Instances
  """

  defstruct [:role, :party_type, __spark_metadata__: nil]

  defimpl String.Chars do
    def to_string(struct), do: inspect(struct)
  end
end
