# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Assigner do
  @moduledoc """
  Helper to perform Assignment using `Diffo.Provider.DefinedSimpleRelationship`.

  Each assignment is stored as a `DefinedSimpleRelationship` with `type: :assignedTo`
  and a single `NameValuePrimitive` characteristic carrying the thing name and assigned value.
  """
  alias Diffo.Provider.AssignableCharacteristic
  alias Diffo.Provider.DefinedSimpleRelationship
  alias Diffo.Type.NameValuePrimitive
  alias Diffo.Type.Primitive

  @doc """
  Assign a thing using the pool declared via `pools do` on the instance module.
  The thing name is looked up from the pool declaration.
  """
  def assign(result, changeset, pool_name)
      when is_struct(result) and is_struct(changeset, Ash.Changeset) and is_atom(pool_name) do
    case result.__struct__.pool(pool_name) do
      nil -> {:error, "pool #{pool_name} not declared on #{result.__struct__}"}
      pool -> assign(result, changeset, pool_name, pool.thing)
    end
  end

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

  defp relate_is_assigned(result, _pool, thing, value, assignee_id)
       when is_struct(result) and is_atom(thing) and is_integer(value) and
              is_bitstring(assignee_id) do
    case Diffo.Provider.create_defined_simple_relationship(%{
           type: :assignedTo,
           characteristic: %NameValuePrimitive{
             name: thing,
             value: Primitive.wrap("integer", value)
           },
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

  defp find_assignment(source_id, target_id, _pool, thing, value) do
    case DefinedSimpleRelationship
         |> Ash.Query.new()
         |> Ash.Query.filter_input(source_id: source_id, target_id: target_id, type: :assignedTo)
         |> Ash.read(domain: Diffo.Provider) do
      {:ok, rels} ->
        {:ok,
         Enum.find(rels, fn rel ->
           rel.characteristic &&
             rel.characteristic.name == thing &&
             Diffo.Unwrap.unwrap(rel.characteristic.value) == value
         end)}

      {:error, error} ->
        {:error, error}
    end
  end

  defp next(instance, pool, thing)
       when is_struct(instance) and is_atom(pool) and is_atom(thing) do
    case pool_characteristic(instance.id, pool, thing) do
      {:ok, nil} ->
        {:error, "pool #{pool} not found on instance #{instance.id}"}

      {:ok, char} ->
        free = Enum.to_list(char.first..char.last) -- char.assigned_values

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
    case pool_characteristic(instance.id, pool, thing) do
      {:ok, nil} -> false
      {:ok, char} -> value in Enum.to_list(char.first..char.last) -- char.assigned_values
      {:error, _} -> false
    end
  end

  defp pool_characteristic(instance_id, pool, thing) do
    AssignableCharacteristic
    |> Ash.Query.new()
    |> Ash.Query.filter_input(instance_id: instance_id, name: pool)
    |> Ash.Query.load(assigned_values: [thing: thing])
    |> Ash.read_one(domain: Diffo.Provider)
  end
end
