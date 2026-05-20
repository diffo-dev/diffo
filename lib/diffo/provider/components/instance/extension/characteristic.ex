# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Instance.Characteristic do
  @moduledoc false
  require Logger

  alias Diffo.Provider
  alias Diffo.Type.Value
  alias AshNeo4j.Resource.Info, as: Neo4jInfo
  alias AshNeo4j.Neo4jHelper

  @doc """
  Struct for a Characteristic
  """
  defstruct [:name, :value_type, __spark_metadata__: nil]

  @doc """
  Sets the Extended Instances characteristics argument in the changeset, creating the characteristics
  """
  def set_characteristics_argument(changeset, declarations)
      when is_struct(changeset, Ash.Changeset) and is_list(declarations) do
    case create_characteristics_from_declarations(declarations, :instance) do
      {:ok, []} ->
        changeset

      {:ok, characteristics} ->
        characteristic_ids = Enum.map(characteristics, &Map.get(&1, :id))
        Ash.Changeset.force_set_argument(changeset, :characteristics, characteristic_ids)

      {:error, error} ->
        Ash.Changeset.add_error(changeset, error)
    end
  end

  defp create_characteristics_from_declarations(declarations, type) do
    Enum.reduce_while(declarations, {:ok, []}, fn %{name: name, value_type: value_type},
                                                  {:ok, acc} ->
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
            {:cont, {:ok, [result | acc]}}

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
    relate_to_instance(result, characteristics)
  end

  # Directly create HAS edges in Neo4j rather than going through manage_relationship.
  # manage_relationship on a has_many triggers accessing_from updates on each
  # Characteristic, which break because Ash.Resource.Info.reverse_relationship
  # finds no path back to the concrete resource (ShelfInstance etc.) — Characteristic's
  # belongs_to :instance targets the generic Diffo.Provider.Instance, not the
  # domain-specific subtype.
  defp relate_to_instance(result, nil), do: {:ok, result}
  defp relate_to_instance(result, []), do: {:ok, result}

  defp relate_to_instance(result, char_ids) do
    instance_label_pair = Neo4jInfo.label_pair(result.__struct__)
    char_label = Neo4jInfo.label(Diffo.Provider.Characteristic)

    Enum.reduce_while(char_ids, {:ok, result}, fn char_id, acc ->
      case Neo4jHelper.relate_nodes(
             instance_label_pair,
             %{uuid: result.id},
             char_label,
             %{uuid: char_id},
             :HAS,
             :outgoing
           ) do
        {:ok, _} -> {:cont, acc}
        {:error, error} -> {:halt, {:error, error}}
      end
    end)
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
          Enum.reduce_while(characteristic_updates, {:ok, []}, fn {characteristic, value},
                                                                  {:ok, acc} ->
            case Provider.update_characteristic(characteristic, %{value: value}) do
              {:ok, characteristic} ->
                {:cont, {:ok, [characteristic | acc]}}

              {:error, error} ->
                {:halt, {:error, error}}
            end
          end)

        case characteristics do
          {:ok, []} ->
            {:error, "couldn't update characteristics"}

          {:ok, updated} ->
            {:ok, Map.put(result, :characteristics, updated)}

          {:error, error} ->
            {:error, error}
        end
    end
  end

  defimpl String.Chars do
    def to_string(struct) do
      inspect(struct)
    end
  end
end
