# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT
defmodule Diffo.Type.Dynamic do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  `Diffo.Type.Dynamic` is an `Ash.Type.NewType` for values whose exact type is not known until
  runtime. The `:type` field holds the `Ash.Type.NewType` module and `:value` holds the cast value.

  Dynamic is limited to types that have `storage_type: :map` — that is, `Ash.TypedStruct` and
  `Ash.Type.NewType` subtypes of `:struct`, `:map`, `:union`, `:keyword`, or `:tuple`.
  Scalar Ash types such as `Ash.Type.Date` or `Ash.Type.Decimal` are not supported.

  In practice, `Diffo.Type.Dynamic` is used as a member of `Diffo.Type.Value` and is not
  typically used as a standalone attribute type.

  ## Nil handling

      iex> Ash.Type.cast_input(Diffo.Type.Dynamic, nil, [])
      {:ok, nil}

      iex> Ash.Type.dump_to_native(Diffo.Type.Dynamic, nil, [])
      {:ok, nil}

      iex> Ash.Type.cast_stored(Diffo.Type.Dynamic, nil, [])
      {:ok, nil}

  ## Invalid types

  Scalar Ash types and modules that are not `Ash.Type.NewType` with `storage_type: :map` are
  rejected at cast time:

      iex> Ash.Type.cast_input(Diffo.Type.Dynamic, %Diffo.Type.Dynamic{type: Ash.Type.Date, value: ~D[2026-01-01]}, [])
      {:error, "Dynamic type Ash.Type.Date must be an Ash.Type.NewType with storage_type :map"}

      iex> Ash.Type.cast_input(Diffo.Type.Dynamic, %Diffo.Type.Dynamic{type: Diffo.Type.NonExistent, value: nil}, [])
      {:error, "Dynamic type Diffo.Type.NonExistent must be an Ash.Type.NewType with storage_type :map"}

  ## Checking type compatibility

  Use `is_valid?/1` to check whether a module is usable as a Dynamic type before
  constructing a `%Diffo.Type.Dynamic{}`:

      iex> Diffo.Type.Dynamic.is_valid?(Ash.Type.Date)
      false

      iex> Diffo.Type.Dynamic.is_valid?(Diffo.Type.NonExistent)
      false

  ## Constraints

      iex> Diffo.Type.Dynamic.dynamic_constraints(nil)
      []
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
      is_valid?(type) ->
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
  def apply_constraints(%__MODULE__{type: type} = value, _constraints) do
    if is_valid?(type) do
      {:ok, value}
    else
      {:error, "Dynamic type #{inspect(type)} must be an Ash.Type.NewType with storage_type :map"}
    end
  end

  def apply_constraints(nil, _constraints), do: {:ok, nil}
  def apply_constraints(value, _constraints), do: {:error, "is invalid: #{inspect(value)}"}

  @impl true
  def cast_input(nil, _constraints), do: {:ok, nil}

  def cast_input(%__MODULE__{type: type, value: value}, _constraints) do
    if is_valid?(type) do
      constraints = dynamic_constraints(type)
      result = Ash.Type.cast_input(type, value, constraints[:fields][:value][:constraints] || [])

      case result do
        {:ok, cast_value} -> {:ok, %__MODULE__{type: type, value: cast_value}}
        error -> error
      end
    else
      {:error, "Dynamic type #{inspect(type)} must be an Ash.Type.NewType with storage_type :map"}
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
  def cast_stored(nil, _constraints), do: {:ok, nil}

  def cast_stored(%{"type" => type_string, "value" => value}, _constraints) do
    type = String.to_existing_atom(type_string)
    constraints = dynamic_constraints(type_string)

    case Ash.Type.cast_stored(type, value, constraints[:fields][:value][:constraints] || []) do
      {:ok, cast_value} -> {:ok, %__MODULE__{type: type, value: cast_value}}
      error -> error
    end
  end

  @impl true
  def dump_to_native(nil, _constraints), do: {:ok, nil}

  def dump_to_native(%__MODULE__{type: type, value: value}, _constraints) do
    constraints = dynamic_constraints(type)

    case Ash.Type.dump_to_native(type, value, constraints[:fields][:value][:constraints] || []) do
      {:ok, dumped} -> {:ok, %{"type" => to_string(type), "value" => dumped}}
      error -> error
    end
  end

  @doc """
  Returns true if the module is a valid Dynamic type — an `Ash.Type.NewType` with
  `storage_type: :map`. Returns false for unloaded modules, non-NewTypes, and scalar
  Ash types such as `Ash.Type.Date`.
  """
  def is_valid?(type) when is_atom(type) do
    Code.ensure_loaded?(type) and
      Ash.Type.NewType.new_type?(type) and
      Ash.Type.storage_type(type, []) == :map
  rescue
    _ -> false
  end

  def is_valid?(_), do: false

  defimpl Diffo.Unwrap do
    def unwrap(%{value: value}), do: Diffo.Unwrap.unwrap(value)
  end

  defimpl Jason.Encoder do
    def encode(value, opts) do
      value |> Diffo.Unwrap.unwrap() |> Jason.Encode.value(opts)
    end
  end
end
