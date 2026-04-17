defmodule Diffo.Type.Primitive do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  Primitive - an Ash.TypedStruct representing a single TMF primitive value.
  The :type field identifies which primitive field is populated.
  """
  use Ash.TypedStruct

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
end
