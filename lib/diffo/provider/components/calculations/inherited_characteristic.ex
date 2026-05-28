# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Calculations.InheritedCharacteristic do
  @moduledoc """
  Backing calculation for `inherited_characteristic` DSL declarations.

  Traverses `AssignmentRelationship` by alias **inward** (this instance is the
  target; follow to the source) to reach source instances, then reads each source's
  typed characteristic at the declared role.

  Injected automatically by `TransformInheritedRefs` — do not reference this module
  directly; use the `inherited_characteristic` DSL entity inside `characteristics do`.

  ## Cross-world resolution

  Unlike `inherited_place` / `inherited_party` (which query universal `PlaceRef` /
  `PartyRef`), the typed characteristic module varies per source resource. This calc
  resolves it at runtime via `AshNeo4j.worlds/1` on the source struct and
  `Diffo.Provider.Extension.Info.provider_characteristics/1` on the source's
  outermost resource. Late-binding by design — the source resource may not exist at
  the consumer's compile time.

  ## Result shape

  A list per input record. Each entry corresponds to one source instance reached by
  the traversal. The entry is:

  - A `BaseCharacteristic`-derived record (or a list of such records when the
    source's characteristic declaration is `{:array, M}`).
  - `%Diffo.Unknown{}` when the source can't be projected to a loadable resource
    module, or its module declares no characteristic at this role.

  ## Reason vocabulary (local to this world)

  This calc emits `%Diffo.Unknown{}` with one of:

  - `:no_concrete_world` — `AshNeo4j.worlds/1` returned `[]`; the source struct
    has no labels resolvable to a loaded `AshNeo4j.DataLayer` resource. The
    `:context` carries `%{source_id: id}`.
  - `:role_not_declared` — the outermost world's resource exists but its
    `provider_characteristics/1` has no entry for the declared role. The
    `:context` carries `%{source_id: id, resource: module, role: atom}`.

  Per the **Cross-domain lookups** AGENTS.md section, reasons are world-local —
  consumers in other worlds should treat them as opaque and (if composing) wrap
  via `:inner_unknown`.
  """
  use Ash.Resource.Calculation

  @impl true
  def load(_query, _opts, _context), do: []

  @impl true
  def calculate(records, opts, _context) do
    via = opts[:via]
    role = opts[:role]
    world = opts[:world]

    Enum.map(records, fn record ->
      record.id
      |> traverse_via(via)
      |> Enum.flat_map(&resolve_source(&1, role, world))
    end)
  end

  defp traverse_via(starting_id, via) do
    Enum.reduce(via, [starting_id], fn alias_step, ids ->
      Enum.flat_map(ids, fn id ->
        Diffo.Provider.AssignmentRelationship
        |> Ash.Query.filter_input(target_id: id, alias: alias_step)
        |> Ash.read!(domain: Diffo.Provider)
        |> Enum.map(& &1.source_id)
      end)
    end)
  end

  defp resolve_source(source_id, role, world) do
    case Ash.get(Diffo.Provider.Instance, source_id, domain: Diffo.Provider) do
      {:error, _} ->
        []

      {:ok, source} ->
        case AshNeo4j.worlds(source) do
          [{_domain, resource} | _] ->
            read_characteristic(resource, source_id, role, world)

          [] ->
            [
              %Diffo.Unknown{
                world: world,
                reason: :no_concrete_world,
                context: %{source_id: source_id, role: role}
              }
            ]
        end
    end
  end

  defp read_characteristic(resource, source_id, role, world) do
    case find_characteristic_entity(resource, role) do
      nil ->
        [
          %Diffo.Unknown{
            world: world,
            reason: :role_not_declared,
            context: %{source_id: source_id, resource: resource, role: role}
          }
        ]

      %{value_type: {:array, char_module}} ->
        query_records(char_module, source_id)

      %{value_type: char_module} when is_atom(char_module) ->
        query_records(char_module, source_id)
    end
  end

  defp find_characteristic_entity(resource, role) do
    resource
    |> Diffo.Provider.Extension.Info.provider_characteristics()
    |> Enum.find(fn entity -> entity.name == role end)
  end

  defp query_records(char_module, source_id) do
    domain = Ash.Resource.Info.domain(char_module)

    char_module
    |> Ash.Query.filter_input(instance_id: source_id)
    |> Ash.read!(domain: domain)
  end
end
