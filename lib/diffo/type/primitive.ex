# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT
defmodule Diffo.Type.Primitive do
  @moduledoc """
  `Diffo.Type.Primitive` is a discriminated union of primitive types: string, integer, float,
  boolean, date, time, datetime, and duration.

  Use `wrap/2` to construct a Primitive from a type name string and a value.
  Use `Diffo.Unwrap.unwrap/1` to extract the value.
  Outstanding comparison is implemented inline via `defoutstanding`.

  > #### Temporal types {: .info}
  >
  > Date, time, datetime, and duration values are stored internally as ISO 8601 strings
  > to avoid nested serialisation issues. `Diffo.Unwrap.unwrap/1` returns the string form.

  ## Examples

      iex> Diffo.Type.Primitive.wrap("string", "connectivity") |> Diffo.Unwrap.unwrap()
      "connectivity"

      iex> Diffo.Type.Primitive.wrap("integer", 42) |> Diffo.Unwrap.unwrap()
      42

      iex> Diffo.Type.Primitive.wrap("float", 3.14) |> Diffo.Unwrap.unwrap()
      3.14

      iex> Diffo.Type.Primitive.wrap("boolean", false) |> Diffo.Unwrap.unwrap()
      false

      iex> Diffo.Type.Primitive.wrap("date", ~D[2026-04-24]) |> Diffo.Unwrap.unwrap()
      "2026-04-24"

      iex> Diffo.Type.Primitive.wrap("unknown", "x")
      nil
  """
  use Ash.TypedStruct
  use Outstand

  typed_struct do
    field :type, :string, description: "the primitive type discriminator"
    field :string, :string, description: "string value"
    field :integer, :integer, description: "integer value"
    field :float, :float, description: "float value"
    field :boolean, :boolean, description: "boolean value"
    field :date, :date, description: "date value"
    field :time, :time, description: "time value"
    field :datetime, :datetime, description: "datetime value"
    field :duration, :duration, description: "duration value"
  end

  # workarounds for temporal types until AshNeo4j ash_json handles nested ash_json types better
  def wrap("date", %Date{} = value),
    do: %__MODULE__{type: "string", string: Date.to_iso8601(value)}

  def wrap("time", %Time{} = value),
    do: %__MODULE__{type: "string", string: Time.to_iso8601(value)}

  def wrap("datetime", %DateTime{} = value),
    do: %__MODULE__{type: "string", string: DateTime.to_iso8601(value)}

  def wrap("duration", %Duration{} = value),
    do: %__MODULE__{type: "string", string: Duration.to_iso8601(value)}

  def wrap(type = "string", value), do: %__MODULE__{type: type, string: value}
  def wrap(type = "integer", value), do: %__MODULE__{type: type, integer: value}
  def wrap(type = "float", value), do: %__MODULE__{type: type, float: value}
  def wrap(type = "boolean", value), do: %__MODULE__{type: type, boolean: value}
  def wrap(type = "date", value), do: %__MODULE__{type: type, date: value}
  def wrap(type = "time", value), do: %__MODULE__{type: type, time: value}
  def wrap(type = "datetime", value), do: %__MODULE__{type: type, datetime: value}
  def wrap(type = "duration", value), do: %__MODULE__{type: type, duration: value}
  def wrap(_, _), do: nil

  defimpl Diffo.Unwrap do
    def unwrap(%{type: "string", string: value}), do: value
    def unwrap(%{type: "integer", integer: value}), do: value
    def unwrap(%{type: "float", float: value}), do: value
    def unwrap(%{type: "boolean", boolean: value}), do: value
    def unwrap(%{type: "date", date: value}), do: value
    def unwrap(%{type: "time", time: value}), do: value
    def unwrap(%{type: "datetime", datetime: value}), do: value
    def unwrap(%{type: "duration", duration: value}), do: value
    def unwrap(_), do: nil
  end

  defimpl String.Chars do
    def to_string(primitive), do: inspect(primitive)
  end

  defimpl Jason.Encoder do
    def encode(value, _opts) do
      value |> Diffo.Unwrap.unwrap() |> Jason.encode!()
    end
  end

  defoutstanding expected :: Diffo.Type.Primitive, actual :: Any do
    # we return a map since Primitive doesn't allow type nil
    type_outstanding =
      case actual do
        %{type: type} -> Outstanding.outstanding(expected.type, type)
        nil -> expected.type
        # actual is wrong type entirely
        _ -> expected.type
      end

    value_outstanding =
      case actual do
        %{} ->
          Outstanding.outstanding(
            Diffo.Unwrap.unwrap(expected),
            Diffo.Unwrap.unwrap(actual)
          )

        _ ->
          Diffo.Unwrap.unwrap(expected)
      end

    case {type_outstanding, value_outstanding} do
      {nil, nil} -> nil
      {nil, _} -> %{value: value_outstanding}
      {_, nil} -> %{type: type_outstanding}
      {_, _} -> %{type: type_outstanding, value: value_outstanding}
    end
  end
end
