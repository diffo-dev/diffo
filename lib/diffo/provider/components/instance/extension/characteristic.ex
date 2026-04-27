# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Instance.Characteristic do
  @moduledoc false
  require Logger

  alias Diffo.Provider
  alias Diffo.Provider.Instance
  alias Diffo.Provider.Instance.Extension.Info
  alias Diffo.Type.Value

  @doc """
  Struct for a Characteristic
  """
  defstruct [:name, :value_type, __spark_metadata__: nil]

  @doc """
  Sets the Extended Instances characteristics argument in the changeset, creating the characteristics
  """
  def set_characteristics_argument(changeset) when is_struct(changeset, Ash.Changeset) do
    %module{} = changeset.data

    case characteristics = create_characteristics(module, :instance) do
      [] ->
        changeset

      {:error, error} ->
        Ash.Changeset.add_error(changeset, error)

      _ ->
        characteristic_ids = Enum.map(characteristics, &Map.get(&1, :id))
        Ash.Changeset.force_set_argument(changeset, :characteristics, characteristic_ids)
    end
  end

  @doc """
  Creates the Characteristics from a Extended Instance's module
  """
  def create_characteristics(module, type) when is_atom(module) and is_atom(type) do
    characteristics = Info.characteristics(module)

    Enum.reduce_while(characteristics, [], fn %{name: name, value_type: value_type}, acc ->
      try do
        attrs =
          case value_type do
            {:array, _inner} ->
              %{name: name, type: type, values: [], is_array: true}

            module ->
              %{name: name, type: type, value: Value.dynamic(struct(module))}
          end

        case Provider.create_characteristic(attrs) do
          {:ok, result} ->
            {:cont, [result | acc]}

          {:error, error} ->
            {:halt, {:error, error}}
        end
      rescue
        _e in UndefinedFunctionError ->
          {:halt,
           {:error, "couldn't create characteristic with value of unknown type #{value_type}"}}
      end
    end)
  end

  @doc """
  Relates the characteristics in the changeset with the Extended Instance
  """
  def relate_instance(result, changeset)
      when is_struct(result) and is_struct(changeset, Ash.Changeset) do
    characteristics = Ash.Changeset.get_argument(changeset, :characteristics)
    instance = struct(Instance, Map.from_struct(result))
    Provider.relate_instance_characteristics(instance, %{characteristics: characteristics})
  end

  @doc """
  Updates the characteristic values according to the changeset
  """
  def update_values(result, changeset)
      when is_struct(result) and is_struct(changeset, Ash.Changeset) do
    characteristic_value_updates =
      Ash.Changeset.get_argument(changeset, :characteristic_value_updates)

    case characteristic_value_updates do
      nil ->
        {:ok, result}

      [] ->
        {:ok, result}

      _ ->
        characteristic_updates =
          Enum.reduce(characteristic_value_updates, [], fn {name, update}, acc ->
            # find the named characteristic, perform updates to value
            characteristic =
              Enum.find(changeset.data.characteristics, fn %{name: n} -> n == name end)

            if characteristic do
              cond do
                is_list(update) ->
                  # unwrap the current value, merge the update fields, rewrap
                  unwrapped = Diffo.Unwrap.unwrap(characteristic.value)
                  value_type = unwrapped.__struct__

                  updated =
                    Enum.reduce(update, unwrapped, fn {field, val}, acc ->
                      Map.put(acc, field, val)
                    end)

                  new_value =
                    Value.dynamic(struct(value_type, Map.from_struct(updated)))

                  [{characteristic, new_value} | acc]

                true ->
                  # replace the value entirely
                  [{characteristic, update} | acc]
              end
            else
              Logger.warning("couldn't find characteristic #{name}")
              acc
            end
          end)

        characteristics =
          Enum.reduce_while(characteristic_updates, [], fn {characteristic, value}, acc ->
            case Provider.update_characteristic(characteristic, %{value: value}) do
              {:ok, characteristic} ->
                {:cont, [characteristic | acc]}

              {:error, error} ->
                # preserve the error
                {:halt, {:error, error}}
            end
          end)

        case characteristics do
          {:error, error} ->
            {:error, error}

          [] ->
            {:error, "couldn't update characteristics"}

          _ ->
            {:ok, Map.put(result, :characteristics, characteristics)}
        end
    end
  end

  defimpl String.Chars do
    def to_string(struct) do
      inspect(struct)
    end
  end
end
