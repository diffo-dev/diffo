# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Type.NameValuePrimitive do
  @moduledoc """
  Ash TypedStruct for a named primitive value.

  A name/value pair where the value is a `Diffo.Type.Primitive` — covering string,
  integer, float, boolean, date, time, datetime, and duration.
  """
  use Ash.TypedStruct, extensions: [AshJason.TypedStruct]

  jason do
    order [:name, :value]
  end

  typed_struct do
    field :name, :atom, allow_nil?: false, description: "the name"
    field :value, Diffo.Type.Primitive, description: "the primitive value"
  end
end
