# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Type.CharacteristicValue do
  @moduledoc """
  Ash type for a typed characteristic value.

  Used as the return type for `:value` calculations on `BaseCharacteristic`-derived resources.
  The actual value is a `TypedStruct` defined by the extender (e.g. `Card.Value`, `Shelf.Value`),
  which controls field ordering and JSON encoding via `AshJason.TypedStruct`.
  """
  use Ash.Type.NewType,
    subtype_of: Ash.Type.Struct
end
