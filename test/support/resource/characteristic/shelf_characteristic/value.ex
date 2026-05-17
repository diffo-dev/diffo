# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Test.Characteristic.ShelfCharacteristic.Value do
  @moduledoc "Typed value struct for a Shelf characteristic."
  use Ash.TypedStruct, extensions: [AshJason.TypedStruct]

  typed_struct do
    field :family, :atom, description: "the shelf family name"
    field :model, :string, description: "the shelf model name"
    field :technology, :atom, description: "the shelf technology"
  end

  jason do
    pick [:family, :model, :technology]
    compact true
  end
end
