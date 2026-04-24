# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT
defmodule Diffo.Type.Value do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  `Diffo.Type.Value` is an `Ash.Type.NewType` union that holds either a `Diffo.Type.Primitive`
  or a `Diffo.Type.Dynamic` value.

  It is the intended attribute type for `Diffo.Provider.Characteristic.value` and any resource
  field that needs to carry a value whose type is known only at runtime.

  Use `primitive/2` to build a primitive value and `dynamic/1` to build a dynamic value.
  Use `Diffo.Unwrap.unwrap/1` on the stored `%Ash.Union{}` to extract the underlying Elixir value.

  ## Examples

      iex> Diffo.Type.Value.primitive("string", "connectivity") |> Diffo.Unwrap.unwrap()
      "connectivity"

      iex> Diffo.Type.Value.primitive("integer", 42) |> Diffo.Unwrap.unwrap()
      42

      iex> Diffo.Type.Value.primitive("float", 3.14) |> Diffo.Unwrap.unwrap()
      3.14

      iex> Diffo.Type.Value.primitive("boolean", true) |> Diffo.Unwrap.unwrap()
      true

      iex> Diffo.Type.Value.primitive("date", ~D[2026-04-24]) |> Diffo.Unwrap.unwrap()
      "2026-04-24"
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

  def handle_change(_old_value, nil, _constraints), do: {:ok, nil}
  def handle_change(old_value, new_value, constraints), do: super(old_value, new_value, constraints)

  def handle_change_array(_old_values, nil, _constraints), do: {:ok, nil}
  def handle_change_array(old_values, new_values, constraints), do: super(old_values, new_values, constraints)

  def prepare_change_array(_old_values, nil, _constraints), do: {:ok, nil}
  def prepare_change_array(old_values, new_values, constraints), do: super(old_values, new_values, constraints)

  def primitive(type, value), do: Diffo.Type.Primitive.wrap(type, value)

  def dynamic(%type{} = dynamic), do: dynamic(type, dynamic)

  defp dynamic(type, value),
    do: %{type: "dynamic", value: %Diffo.Type.Dynamic{type: type, value: value}}

  def wrap(type, value), do: %Ash.Union{type: type, value: value}

  defimpl Diffo.Unwrap do
    def unwrap(%{value: value}), do: Diffo.Unwrap.unwrap(value)
  end
end
