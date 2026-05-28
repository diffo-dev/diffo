# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Calculations.ReverseInheritedCharacteristic do
  @moduledoc """
  Backing calculation for `reverse_inherited_characteristic` DSL declarations.

  Traverses `AssignmentRelationship` **outward** (this instance is the source;
  follow to assignees) filtered by alias, then reads the named typed characteristic
  on each assignee.

  Where `inherited_characteristic` follows the assignee's natural view (turtles up
  to the assigner), this calc follows the assigner's view (turtles down to
  assignees). The "reverse" in the name is reverse-of-the-natural-inherited-
  direction. Useful when the assigner wants to compose its assignees' characteristics
  into its own view (e.g. a shelf surfacing the typed characteristic of every card
  assigned to its slot pool).

  Injected automatically by `TransformInheritedRefs` — do not reference this module
  directly; use the `reverse_inherited_characteristic` DSL entity inside
  `characteristics do`.

  ## Cross-world resolution

  Same as `Diffo.Provider.Calculations.InheritedCharacteristic` — the typed
  characteristic module is resolved at runtime per assignee via `AshNeo4j.worlds/1`
  on the assignee struct and `Diffo.Provider.Extension.Info.provider_characteristics/1`
  on its outermost resource. Late-binding by design.

  ## Result shape

  A list per input record. Each entry corresponds to one assignee reached by the
  outgoing-assignment traversal at the declared alias. Same shape as the forward
  calc: a typed characteristic record (or list of records for `{:array, _}` declared
  values), or `%Diffo.Unknown{}`.

  ## Reason vocabulary (local to this world)

  Same atoms as `InheritedCharacteristic` — `:no_concrete_world` and
  `:role_not_declared` — with `:context` carrying `:assignee_id` instead of
  `:source_id` to reflect the traversal direction.
  """
  use Ash.Resource.Calculation

  @impl true
  def load(_query, _opts, _context), do: []

  @impl true
  def calculate(records, opts, _context) do
    assignment_alias = opts[:assignment_alias]
    characteristic_role = opts[:characteristic]
    world = opts[:world]

    Enum.map(records, fn record ->
      record.id
      |> assignee_ids(assignment_alias)
      |> Enum.flat_map(&resolve_assignee(&1, characteristic_role, world))
    end)
  end

  defp assignee_ids(source_id, assignment_alias) do
    Diffo.Provider.AssignmentRelationship
    |> Ash.Query.filter_input(source_id: source_id, alias: assignment_alias)
    |> Ash.read!(domain: Diffo.Provider)
    |> Enum.map(& &1.target_id)
  end

  defp resolve_assignee(assignee_id, role, world) do
    case Ash.get(Diffo.Provider.Instance, assignee_id, domain: Diffo.Provider) do
      {:error, _} ->
        []

      {:ok, assignee} ->
        case AshNeo4j.worlds(assignee) do
          [{_domain, resource} | _] ->
            read_characteristic(resource, assignee_id, role, world)

          [] ->
            [
              %Diffo.Unknown{
                world: world,
                reason: :no_concrete_world,
                context: %{assignee_id: assignee_id, role: role}
              }
            ]
        end
    end
  end

  defp read_characteristic(resource, assignee_id, role, world) do
    case find_characteristic_entity(resource, role) do
      nil ->
        [
          %Diffo.Unknown{
            world: world,
            reason: :role_not_declared,
            context: %{assignee_id: assignee_id, resource: resource, role: role}
          }
        ]

      %{value_type: {:array, char_module}} ->
        query_records(char_module, assignee_id)

      %{value_type: char_module} when is_atom(char_module) ->
        query_records(char_module, assignee_id)
    end
  end

  defp find_characteristic_entity(resource, role) do
    resource
    |> Diffo.Provider.Extension.Info.provider_characteristics()
    |> Enum.find(fn entity -> entity.name == role end)
  end

  defp query_records(char_module, instance_id) do
    domain = Ash.Resource.Info.domain(char_module)

    char_module
    |> Ash.Query.filter_input(instance_id: instance_id)
    |> Ash.read!(domain: domain)
  end
end
