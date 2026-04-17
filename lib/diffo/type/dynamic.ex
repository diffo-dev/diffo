# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT
defmodule Diffo.Type.Dynamic do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  Dynamic - an Ash.Type subtype_of :struct with dynamic Ash.Type.NewType typing
  """

  defstruct [:type, :value]

  @type_field_constraints [
    type: :module,
    allow_nil?: false,
    constraints: [behaviour: Ash.Type.NewType]
  ]

  @constraints [
    fields: [
      type: @type_field_constraints,
      value: [
        type: :struct
      ]
    ]
  ]

  use Ash.Type.NewType,
    subtype_of: :struct,
    constraints: @constraints

  @doc """
  Returns the dynamic constraints from dynamic struct or map
  """

  def dynamic_constraints(nil), do: []

  def dynamic_constraints(%{type: type}) when is_atom(type), do: dynamic_constraints(type)

  def dynamic_constraints(%{"type" => type}) when is_binary(type), do: dynamic_constraints(type)

  def dynamic_constraints(type) when is_binary(type),
    do: dynamic_constraints(String.to_existing_atom(type))

  def dynamic_constraints(type) when is_atom(type) do
    cond do
      Ash.Type.NewType.new_type?(type) ->
        [
          fields: [
            type: @type_field_constraints,
            value: [type: type, constraints: type.subtype_constraints()]
          ],
          instance_of: __MODULE__
        ]

      true ->
        []
    end
  end

  def dynamic_constraints(_), do: []

  @impl true
  def apply_constraints(%__MODULE__{} = value, _constraints), do: {:ok, value}
  def apply_constraints(nil, _constraints), do: {:ok, nil}
  def apply_constraints(value, _constraints), do: {:error, "is invalid: #{inspect(value)}"}

  @impl true
  def cast_input(nil, _constraints), do: {:ok, nil}

  def cast_input(%__MODULE__{type: type, value: value}, _constraints) do
    constraints = dynamic_constraints(type)
    result = Ash.Type.cast_input(type, value, constraints[:fields][:value][:constraints] || [])

    case result do
      {:ok, cast_value} ->
        {:ok, %__MODULE__{type: type, value: cast_value}}

      error ->
        error
    end
  end

  def cast_input(%{value: %__MODULE__{} = dynamic}, _constraints) do
    cast_input(dynamic, [])
  end

  def cast_input(%{"value" => %__MODULE__{} = dynamic}, _constraints) do
    cast_input(dynamic, [])
  end

  def cast_input(_value, _constraints) do
    :error
  end

  @impl true
  def cast_stored(%{"type" => type_string, "value" => value}, _constraints) do
    type = String.to_existing_atom(type_string)
    constraints = dynamic_constraints(type_string)

    case Ash.Type.cast_stored(type, value, constraints[:fields][:value][:constraints] || []) do
      {:ok, cast_value} -> {:ok, %__MODULE__{type: type, value: cast_value}}
      error -> error
    end
  end

  @impl true
  def dump_to_native(%__MODULE__{type: type, value: value}, _constraints) do
    constraints = dynamic_constraints(type)

    case Ash.Type.dump_to_native(type, value, constraints[:fields][:value][:constraints] || []) do
      {:ok, dumped} -> {:ok, %{"type" => to_string(type), "value" => dumped}}
      error -> error
    end
  end

  defimpl Diffo.Unwrap do
    def unwrap(%{value: value}), do: Diffo.Unwrap.unwrap(value)
  end

  defimpl Jason.Encoder do
    def encode(value, opts) do
      value |> Diffo.Unwrap.unwrap() |> Jason.Encode.value(opts)
    end
  end
end
