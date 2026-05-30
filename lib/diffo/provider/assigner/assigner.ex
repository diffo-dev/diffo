# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Assigner do
  @moduledoc """
  Helper to perform Assignment using `Diffo.Provider.AssignmentRelationship`.

  Each assignment is stored as an `AssignmentRelationship` with top-level `pool`,
  `thing`, and `value` attributes. This makes them filterable at the Cypher level
  and usable in aggregate expressions.
  """
  alias Diffo.Provider.AssignableCharacteristic
  alias Diffo.Provider.AssignmentRelationship

  @assignable_resource_states [:planned, :installed]
  @assignable_service_states [:feasibilityChecked, :reserved, :inactive, :active, :suspended]

  @doc """
  The resource lifecycle states from which an instance may make assignments.
  """
  def assignable_resource_states, do: @assignable_resource_states

  @doc """
  The service lifecycle states from which an instance may make assignments.
  """
  def assignable_service_states, do: @assignable_service_states

  @doc """
  Assign a thing using the pool declared via `pools do` on the instance module.
  The thing name is looked up from the pool declaration.
  """
  def assign(result, changeset, pool_name)
      when is_struct(result) and is_struct(changeset, Ash.Changeset) and is_atom(pool_name) do
    with :ok <- assignable_state?(result) do
      case result.__struct__.pool(pool_name) do
        nil -> {:error, "pool #{pool_name} not declared on #{result.__struct__}"}
        pool -> assign(result, changeset, pool_name, pool.thing)
      end
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
    alias_name = Map.get(assignment, :alias)

    case assignee_id do
      nil ->
        {:error, "assignment not valid"}

      _ ->
        case Map.get(assignment, :operation, :auto_assign) do
          :auto_assign ->
            with {:ok, value} <- next(result, pool, thing) do
              create_assignment(result, pool, thing, value, assignee_id, alias_name)
            end

          :assign ->
            if assignable?(result, pool, thing, assignment.id) do
              create_assignment(result, pool, thing, assignment.id, assignee_id, alias_name)
            else
              {:error, "#{thing} #{assignment.id} is not assignable"}
            end

          :unassign ->
            destroy_assignment(result, pool, thing, assignment.id, assignee_id)
        end
    end
  end

  @doc """
  Returns `:ok` if the instance is in a lifecycle state that permits assignment,
  otherwise `{:error, reason}`.
  """
  def assignable_state?(%{type: :resource, lifecycle_state: state})
      when state not in @assignable_resource_states,
      do:
        {:error,
         "cannot assign: resource lifecycle state is #{inspect(state)}, must be one of #{inspect(@assignable_resource_states)}"}

  def assignable_state?(%{type: :service, state: state})
      when state not in @assignable_service_states,
      do:
        {:error,
         "cannot assign: service state is #{inspect(state)}, must be one of #{inspect(@assignable_service_states)}"}

  def assignable_state?(_), do: :ok

  defp create_assignment(result, pool, thing, value, assignee_id, alias_name)
       when is_struct(result) and is_atom(pool) and is_atom(thing) and is_integer(value) and
              is_bitstring(assignee_id) do
    with {:ok, _} <-
           Diffo.Provider.create_assignment_relationship(%{
             alias: alias_name,
             pool: pool,
             thing: thing,
             value: value,
             source_id: result.id,
             target_id: assignee_id
           }) do
      {:ok, result}
    end
  end

  defp destroy_assignment(result, pool, thing, value, assignee_id)
       when is_struct(result) and is_atom(pool) and is_atom(thing) and is_integer(value) and
              is_bitstring(assignee_id) do
    case find_assignment(result.id, assignee_id, pool, thing, value) do
      {:ok, nil} ->
        {:error, "#{thing} #{value} is not assigned to assignee #{assignee_id}"}

      {:ok, assignment} ->
        with :ok <- Ash.destroy(assignment, domain: Diffo.Provider) do
          {:ok, result}
        end

      {:error, error} ->
        {:error, error}
    end
  end

  defp find_assignment(source_id, target_id, pool, thing, value) do
    AssignmentRelationship
    |> Ash.Query.filter_input(
      source_id: source_id,
      target_id: target_id,
      pool: pool,
      thing: thing,
      value: value
    )
    |> Ash.read_one(domain: Diffo.Provider)
  end

  defp next(instance, pool, thing)
       when is_struct(instance) and is_atom(pool) and is_atom(thing) do
    case pool_characteristic(instance.id, pool) do
      {:ok, nil} ->
        {:error, "pool #{pool} not found on instance #{instance.id}"}

      {:ok, char} ->
        assigned = assigned_values_for(instance.id, thing)
        free = Enum.to_list(char.first..char.last) -- assigned

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
      {:ok, nil} ->
        false

      {:ok, char} ->
        assigned = assigned_values_for(instance.id, thing)
        value in (Enum.to_list(char.first..char.last) -- assigned)

      {:error, _} ->
        false
    end
  end

  defp assigned_values_for(instance_id, thing) do
    AssignmentRelationship
    |> Ash.Query.filter_input(source_id: instance_id, thing: thing)
    |> Ash.read!(domain: Diffo.Provider)
    |> Enum.map(& &1.value)
  end

  defp pool_characteristic(instance_id, pool) do
    AssignableCharacteristic
    |> Ash.Query.new()
    |> Ash.Query.filter_input(instance_id: instance_id, name: pool)
    |> Ash.read_one(domain: Diffo.Provider)
  end
end
