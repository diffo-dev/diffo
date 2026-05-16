# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Extension.Characteristic do
  @moduledoc false
  require Logger

  alias Diffo.Provider
  alias Diffo.Provider.Instance
  alias Diffo.Type.Value

  defstruct [:name, :value_type, __spark_metadata__: nil]

  # ── build_before: dynamic characteristics only ─────────────────────────────

  def set_characteristics_argument(changeset, declarations)
      when is_struct(changeset, Ash.Changeset) and is_list(declarations) do
    dynamic = Enum.reject(declarations, &typed?(&1.value_type))

    case characteristics = create_characteristics_from_declarations(dynamic, :instance) do
      [] ->
        changeset

      {:error, error} ->
        Ash.Changeset.add_error(changeset, error)

      _ ->
        characteristic_ids = Enum.map(characteristics, &Map.get(&1, :id))
        Ash.Changeset.force_set_argument(changeset, :characteristics, characteristic_ids)
    end
  end

  defp create_characteristics_from_declarations(declarations, type) do
    Enum.reduce_while(declarations, [], fn %{name: name, value_type: value_type}, acc ->
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

  # ── build_after: relate dynamic, create typed ──────────────────────────────

  def relate_instance(result, changeset)
      when is_struct(result) and is_struct(changeset, Ash.Changeset) do
    characteristics = Ash.Changeset.get_argument(changeset, :characteristics)

    Provider.relate_instance_characteristics(%Instance{id: result.id}, %{
      characteristics: characteristics
    })
  end

  def create_typed(result, declarations) when is_struct(result) and is_list(declarations) do
    typed = Enum.filter(declarations, &typed?(&1.value_type))

    Enum.reduce_while(typed, {:ok, result}, fn %{name: name, value_type: module}, {:ok, acc} ->
      case module
           |> Ash.Changeset.for_create(:create, %{name: name, instance_id: acc.id})
           |> Ash.create() do
        {:ok, _} -> {:cont, {:ok, acc}}
        {:error, error} -> {:halt, {:error, error}}
      end
    end)
  end

  # ── update: handle both typed and dynamic characteristics ──────────────────

  def update_values(result, changeset)
      when is_struct(result) and is_struct(changeset, Ash.Changeset) do
    update_all(result, changeset, [])
  end

  def update_all(result, changeset, declarations)
      when is_struct(result) and is_struct(changeset, Ash.Changeset) and is_list(declarations) do
    characteristic_value_updates =
      Ash.Changeset.get_argument(changeset, :characteristic_value_updates)

    case characteristic_value_updates do
      nil -> {:ok, result}
      [] -> {:ok, result}
      _ -> apply_updates(result, characteristic_value_updates, declarations)
    end
  end

  defp apply_updates(result, updates, declarations) do
    Enum.reduce_while(updates, {:ok, result}, fn {name, update}, {:ok, acc} ->
      decl = Enum.find(declarations, &(&1.name == name))

      if decl && typed?(decl.value_type) do
        apply_typed_update(acc, name, decl.value_type, update)
      else
        apply_dynamic_update(acc, name, update)
      end
    end)
  end

  defp apply_typed_update(result, name, module, field_updates) do
    case module
         |> Ash.Query.new()
         |> Ash.Query.filter_input(instance_id: result.id, name: name)
         |> Ash.read_one() do
      {:ok, nil} ->
        Logger.warning("couldn't find typed characteristic #{name}")
        {:cont, {:ok, result}}

      {:ok, char} ->
        attrs = if is_list(field_updates), do: Map.new(field_updates), else: field_updates

        case char
             |> Ash.Changeset.for_update(:update, attrs)
             |> Ash.update() do
          {:ok, _} -> {:cont, {:ok, result}}
          {:error, error} -> {:halt, {:error, error}}
        end

      {:error, error} ->
        {:halt, {:error, error}}
    end
  end

  defp apply_dynamic_update(result, name, update) do
    characteristic = Enum.find(result.characteristics, fn %{name: n} -> n == name end)

    if characteristic do
      new_value =
        cond do
          is_list(update) ->
            unwrapped = Diffo.Unwrap.unwrap(characteristic.value)
            value_type = unwrapped.__struct__

            updated =
              Enum.reduce(update, unwrapped, fn {field, val}, acc ->
                Map.put(acc, field, val)
              end)

            Value.dynamic(struct(value_type, Map.from_struct(updated)))

          true ->
            update
        end

      case Provider.update_characteristic(characteristic, %{value: new_value}) do
        {:ok, updated_char} ->
          updated_chars =
            Enum.map(result.characteristics, fn c ->
              if c.id == updated_char.id, do: updated_char, else: c
            end)

          {:cont, {:ok, %{result | characteristics: updated_chars}}}

        {:error, error} ->
          {:halt, {:error, error}}
      end
    else
      Logger.warning("couldn't find characteristic #{name}")
      {:cont, {:ok, result}}
    end
  end

  defimpl String.Chars do
    def to_string(struct), do: inspect(struct)
  end

  # ── helpers ────────────────────────────────────────────────────────────────

  def typed?(module) when is_atom(module) and not is_nil(module) do
    case Code.ensure_loaded(module) do
      {:module, _} ->
        try do
          module != Diffo.Provider.Characteristic and
            Diffo.Provider.Characteristic.Extension in Ash.Resource.Info.extensions(module)
        rescue
          _ -> false
        end

      _ ->
        false
    end
  end

  def typed?(_), do: false

end
