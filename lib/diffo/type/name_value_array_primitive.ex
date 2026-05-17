# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Type.NameValueArrayPrimitive do
  @moduledoc """
  Ash TypedStruct for a named array of primitive values.

  A name/values pair where each value is a `Diffo.Type.Primitive` — covering string,
  integer, float, boolean, date, time, datetime, and duration.
  """
  use Ash.TypedStruct, extensions: [AshJason.TypedStruct]

  jason do
    order [:name, :values]
  end

  typed_struct do
    field :name, :atom, allow_nil?: false, description: "the name"
    field :values, {:array, Diffo.Type.Primitive}, default: [], description: "the primitive values"
  end
end
