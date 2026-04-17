# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT
defmodule Diffo.Type.Value do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  Value - an Ash.Type.NewType subtype_of :union representing a primitive or Dynamic value
  """

  use Ash.Type.NewType,
    subtype_of: :union,
    constraints: [
      types: [
        string: [
          type: Diffo.Type.Primitive,
          tag: :type,
          tag_value: "string",
          constraints: Diffo.Type.Primitive.subtype_constraints()
        ],
        integer: [
          type: Diffo.Type.Primitive,
          tag: :type,
          tag_value: "integer",
          constraints: Diffo.Type.Primitive.subtype_constraints()
        ],
        float: [
          type: Diffo.Type.Primitive,
          tag: :type,
          tag_value: "float",
          constraints: Diffo.Type.Primitive.subtype_constraints()
        ],
        boolean: [
          type: Diffo.Type.Primitive,
          tag: :type,
          tag_value: "boolean",
          constraints: Diffo.Type.Primitive.subtype_constraints()
        ],
        date: [
          type: Diffo.Type.Primitive,
          tag: :type,
          tag_value: "date",
          constraints: Diffo.Type.Primitive.subtype_constraints()
        ],
        time: [
          type: Diffo.Type.Primitive,
          tag: :type,
          tag_value: "time",
          constraints: Diffo.Type.Primitive.subtype_constraints()
        ],
        datetime: [
          type: Diffo.Type.Primitive,
          tag: :type,
          tag_value: "datetime",
          constraints: Diffo.Type.Primitive.subtype_constraints()
        ],
        duration: [
          type: Diffo.Type.Primitive,
          tag: :type,
          tag_value: "duration",
          constraints: Diffo.Type.Primitive.subtype_constraints()
        ],
        dynamic: [type: Diffo.Type.Dynamic, tag: :type, tag_value: "dynamic", cast_tag?: false]
      ],
      storage: :type_and_value
    ]

  def primitive(type, value), do: Diffo.Type.Primitive.wrap(type, value)

  def dynamic(type, value),
    do: %{type: "dynamic", value: %Diffo.Type.Dynamic{type: type, value: value}}

  def wrap(type, value), do: %Ash.Union{type: type, value: value}

  defimpl Diffo.Unwrap do
    def unwrap(%{value: value}), do: Diffo.Unwrap.unwrap(value)
  end
end
