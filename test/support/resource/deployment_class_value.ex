# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Test.DeploymentClassValue do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  DeploymentClassValue - AshTyped Struct for DeploymentClass Feature Characteristic Value
  """
  use Ash.TypedStruct, extensions: [AshJason.TypedStruct, AshOutstanding.TypedStruct]

  jason do
    pick [:class, :mask]
    compact true
  end

  outstanding do
    expect [:name]
  end

  typed_struct do
    field :class, :string, description: "the deployment class"
    field :mask, :string, description: "the mask name"
  end

  defimpl String.Chars do
    def to_string(struct) do
      inspect(struct)
    end
  end
end
