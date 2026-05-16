# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Test.Characteristic.Card.Value do
  @moduledoc "Typed value struct for a Card characteristic."
  use Ash.TypedStruct, extensions: [AshJason.TypedStruct]

  typed_struct do
    field :family, :atom, description: "the card family name"
    field :model, :string, description: "the card model name"
    field :technology, :atom, description: "the card technology"
  end

  jason do
    pick [:family, :model, :technology]
    compact true
  end
end
