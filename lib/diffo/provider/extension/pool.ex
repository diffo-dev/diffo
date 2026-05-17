# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Extension.Pool do
  @moduledoc false
  require Logger

  defstruct [:name, :thing, __spark_metadata__: nil]

  @doc "Creates AssignableCharacteristic nodes for each declared pool during the build action"
  def create_pools(result, pools) when is_struct(result) and is_list(pools) do
    Enum.reduce_while(pools, {:ok, result}, fn %__MODULE__{name: name, thing: thing}, {:ok, acc} ->
      case Diffo.Provider.AssignableCharacteristic
           |> Ash.Changeset.for_create(:create, %{name: name, thing: thing, instance_id: acc.id})
           |> Ash.create() do
        {:ok, _} -> {:cont, {:ok, acc}}
        {:error, error} -> {:halt, {:error, error}}
      end
    end)
  end

  @doc "Applies characteristic_value_updates to pool AssignableCharacteristic records"
  def update_pools(result, changeset, pools)
      when is_struct(result) and is_struct(changeset, Ash.Changeset) and is_list(pools) do
    characteristic_value_updates =
      Ash.Changeset.get_argument(changeset, :characteristic_value_updates)

    case characteristic_value_updates do
      nil -> {:ok, result}
      [] -> {:ok, result}
      _ -> apply_pool_updates(result, pools, characteristic_value_updates)
    end
  end

  defp apply_pool_updates(result, pools, updates) do
    Enum.reduce_while(pools, {:ok, result}, fn %__MODULE__{name: name}, {:ok, acc} ->
      case Keyword.get(updates, name) do
        nil ->
          {:cont, {:ok, acc}}

        update ->
          case Diffo.Provider.AssignableCharacteristic
               |> Ash.Query.new()
               |> Ash.Query.filter_input(instance_id: acc.id, name: name)
               |> Ash.read_one() do
            {:ok, nil} ->
              Logger.warning("pool #{name} not found on instance #{acc.id}")
              {:cont, {:ok, acc}}

            {:ok, char} ->
              attrs = if is_list(update), do: Map.new(update), else: update

              case char |> Ash.Changeset.for_update(:update, attrs) |> Ash.update() do
                {:ok, _} -> {:cont, {:ok, acc}}
                {:error, error} -> {:halt, {:error, error}}
              end

            {:error, error} ->
              {:halt, {:error, error}}
          end
      end
    end)
  end

  defimpl String.Chars do
    def to_string(struct), do: inspect(struct)
  end
end
