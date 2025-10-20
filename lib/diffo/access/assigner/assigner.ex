# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Access.Assigner do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  Assigner - Helper to perform Assignment maintaining AssignableValue
  """

  alias Diffo.Access.AssignableValue

  @doc """
  Assign a thing using the instance changeset assignment
  """
  def assign(result, changeset, things, thing)
      when is_struct(result) and is_struct(changeset, Ash.Changeset) and is_atom(things) and
             is_atom(thing) do
    assignment = Map.get(changeset.arguments, :assignment, %{})
    assignee_id = Map.get(assignment, :assignee_id)

    case assignee_id do
      nil ->
        {:error, "assignment not valid"}

      _ ->
        case Map.get(assignment, :operation, :auto_assign) do
          :auto_assign ->
            case next(result, things, thing) do
              {:ok, assigned} ->
                relate_is_assigned(result, things, thing, assigned, assignee_id)

              {:error, error} ->
                {:error, error}
            end

          :assign ->
            case assignable?(result, things, thing, assignment.id) do
              true ->
                relate_is_assigned(result, things, thing, assignment.id, assignee_id)

              false ->
                {:error, "#{thing} #{assignment.id} is not assignable"}
            end

          :unassign ->
            unrelate_is_assigned(result, things, assignment.id, assignee_id)
        end
    end
  end

  defp relate_is_assigned(result, things, thing, value, assignee_id)
       when is_struct(result) and is_atom(things) and is_atom(thing) and is_integer(value) and
              is_bitstring(assignee_id) do
    case Diffo.Provider.create_characteristic(%{name: thing, value: value, type: :relationship}) do
      {:ok, characteristic} ->
        case Diffo.Provider.create_relationship(%{
               type: :assignedTo,
               source_id: result.id,
               target_id: assignee_id,
               characteristics: [characteristic.id]
             }) do
          {:ok, _relationship} ->
            # we haven't refreshed the result there will be a new forward_relationship and an updated things characteristic
            case decrement_free(result, things) do
              :ok ->
                {:ok, result}

              {:error, error} ->
                {:error, error}
            end

          {:error, error} ->
            {:error, error}
        end

      {:error, error} ->
        {:error, error}
    end
  end

  defp unrelate_is_assigned(result, things, value, assignee_id)
       when is_struct(result) and is_atom(things) and is_integer(value) and
              is_bitstring(assignee_id) do
    # destroy characteristic
    # destroy relationship
    {:error, "not implemented"}
  end

  defp assignments(instance, thing) when is_struct(instance) and is_atom(thing) do
    Enum.reduce(instance.forward_relationships, [], fn %{
                                                         type: type,
                                                         characteristics: characteristics,
                                                         target_id: target_id
                                                       },
                                                       acc ->
      case type do
        :assignedTo ->
          characteristic = Enum.find(characteristics, fn %{name: n} -> n == thing end)

          if characteristic do
            assignment =
              struct(Diffo.Access.Assignment, %{id: characteristic.value, instance_id: target_id})

            [assignment | acc]
          else
            acc
          end

        _ ->
          acc
      end
    end)
    |> Enum.sort(Diffo.Access.Assignment)
  end

  defp next(instance, things, thing)
       when is_struct(instance) and is_atom(things) and is_atom(thing) do
    characteristic = Enum.find(instance.characteristics, fn %{name: name} -> name == things end)
    algorithm = Map.get(characteristic.value, :algorithm)

    case free = free(instance, thing, characteristic.value) do
      [] ->
        {:error, "all things are assigned"}

      _ ->
        case algorithm do
          :lowest ->
            {:ok, hd(free)}

          :random ->
            {:ok, Enum.random(free)}

          :highest ->
            {:ok, List.last(free)}
        end
    end
  end

  defp assignable?(instance, things, thing, value)
       when is_struct(instance) and is_atom(things) and is_atom(thing) and is_integer(value) do
    characteristic = Enum.find(instance.characteristics, fn %{name: name} -> name == things end)
    free = free(instance, thing, characteristic.value)

    value in free
  end

  defp decrement_free(instance, things) when is_struct(instance) and is_atom(things) do
    characteristic =
      Enum.find(instance.characteristics, fn %{name: name} -> name == things end)

    {_free, assignable_value} =
      Map.get_and_update(characteristic.value, :free, fn free -> {free - 1, free - 1} end)

    case Diffo.Provider.update_characteristic(characteristic, %{value: assignable_value}) do
      {:ok, _characteristic} ->
        :ok

      {:error, error} ->
        {:error, error}
    end
  end

  defp free(instance, thing, assignable_value)
       when is_struct(instance) and is_atom(thing) and
              is_struct(assignable_value, AssignableValue) do
    assigned =
      assignments(instance, thing)
      |> Enum.into([], &Map.get(&1, :id))

    first = Map.get(assignable_value, :first)
    last = Map.get(assignable_value, :last)

    Enum.to_list(first..last) -- assigned
  end
end
