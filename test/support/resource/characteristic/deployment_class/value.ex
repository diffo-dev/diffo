# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Test.Characteristic.DeploymentClass.Value do
  @moduledoc "Typed value struct for a DeploymentClass characteristic."
  use Ash.TypedStruct, extensions: [AshJason.TypedStruct]

  jason do
    pick [:class, :mask]
    compact true
  end

  typed_struct do
    field :class, :string, description: "the deployment class"
    field :mask, :string, description: "the mask name"
  end
end
