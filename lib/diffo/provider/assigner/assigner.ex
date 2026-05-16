# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Assigner do
  @moduledoc """
  Helper to perform Assignment using Relationship attributes.

  Assignment state is stored directly on `Diffo.Provider.Relationship` nodes
  (pool, thing, assigned) rather than creating a separate Characteristic node.
  """
  alias Diffo.Provider.AssignableCharacteristic
  alias Diffo.Provider.Relationship

  @doc """
  Assign a thing using the instance changeset assignment.
  """
  def assign(result, changeset, pool, thing)
      when is_struct(result) and is_struct(changeset, Ash.Changeset) and is_atom(pool) and
             is_atom(thing) do
    assignment = Map.get(changeset.arguments, :assignment, %{})
    assignee_id = Map.get(assignment, :assignee_id)

    case assignee_id do
      nil ->
        {:error, "assignment not valid"}

      _ ->
        case Map.get(assignment, :operation, :auto_assign) do
          :auto_assign ->
            case next(result, pool, thing) do
              {:ok, assigned} ->
                relate_is_assigned(result, pool, thing, assigned, assignee_id)

              {:error, error} ->
                {:error, error}
            end

          :assign ->
            case assignable?(result, pool, thing, assignment.id) do
              true ->
                relate_is_assigned(result, pool, thing, assignment.id, assignee_id)

              false ->
                {:error, "#{thing} #{assignment.id} is not assignable"}
            end

          :unassign ->
            unrelate_is_assigned(result, pool, thing, assignment.id, assignee_id)
        end
    end
  end

  defp relate_is_assigned(result, pool, thing, value, assignee_id)
       when is_struct(result) and is_atom(pool) and is_atom(thing) and is_integer(value) and
              is_bitstring(assignee_id) do
    case Diffo.Provider.create_assignment_relationship(%{
           pool: pool,
           thing: thing,
           assigned: value,
           source_id: result.id,
           target_id: assignee_id
         }) do
      {:ok, _relationship} ->
        {:ok, result}

      {:error, error} ->
        {:error, error}
    end
  end

  defp unrelate_is_assigned(result, pool, thing, value, assignee_id)
       when is_struct(result) and is_atom(pool) and is_atom(thing) and is_integer(value) and
              is_bitstring(assignee_id) do
    case find_assignment(result.id, assignee_id, pool, thing, value) do
      {:ok, nil} ->
        {:error, "#{thing} #{value} is not assigned to assignee #{assignee_id}"}

      {:ok, relationship} ->
        case Ash.destroy(relationship, domain: Diffo.Provider) do
          :ok ->
            {:ok, result}

          {:error, error} ->
            {:error, error}
        end

      {:error, error} ->
        {:error, error}
    end
  end

  defp find_assignment(source_id, target_id, pool, thing, value) do
    Relationship
    |> Ash.Query.new()
    |> Ash.Query.filter_input(
      source_id: source_id,
      target_id: target_id,
      pool: pool,
      thing: thing,
      assigned: value,
      type: :assignedTo
    )
    |> Ash.read_one(domain: Diffo.Provider)
  end

  defp next(instance, pool, thing)
       when is_struct(instance) and is_atom(pool) and is_atom(thing) do
    case pool_characteristic(instance.id, pool) do
      {:ok, nil} ->
        {:error, "pool #{pool} not found on instance #{instance.id}"}

      {:ok, char} ->
        free = free_values(instance.id, pool, thing, char.first, char.last)

        case free do
          [] ->
            {:error, "all things are assigned"}

          _ ->
            case char.algorithm do
              :lowest -> {:ok, hd(free)}
              :random -> {:ok, Enum.random(free)}
              :highest -> {:ok, List.last(free)}
            end
        end

      {:error, error} ->
        {:error, error}
    end
  end

  defp assignable?(instance, pool, thing, value)
       when is_struct(instance) and is_atom(pool) and is_atom(thing) and is_integer(value) do
    case pool_characteristic(instance.id, pool) do
      {:ok, nil} -> false
      {:ok, char} -> value in free_values(instance.id, pool, thing, char.first, char.last)
      {:error, _} -> false
    end
  end

  defp pool_characteristic(instance_id, pool) do
    AssignableCharacteristic
    |> Ash.Query.new()
    |> Ash.Query.filter_input(instance_id: instance_id, name: pool)
    |> Ash.read_one(domain: Diffo.Provider)
  end

  defp free_values(source_id, pool, thing, first, last) do
    assigned =
      Relationship
      |> Ash.Query.new()
      |> Ash.Query.filter_input(
        source_id: source_id,
        pool: pool,
        thing: thing,
        type: :assignedTo
      )
      |> Ash.read!(domain: Diffo.Provider)
      |> Enum.map(& &1.assigned)

    Enum.to_list(first..last) -- assigned
  end
end
