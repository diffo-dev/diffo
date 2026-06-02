# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Calculations.InheritedCharacteristic do
  @moduledoc """
  Backing calculation for `inherited_characteristic` DSL declarations.

  Walks the graph along a normalised `via:` hop chain (assignment and/or relationship
  edges, in either direction — see `Diffo.Provider.Calculations.Traversal`), reads the
  typed characteristic at the declared `read` role on each reached instance, optionally
  renames it (`as`) and collapses the result to one end (`collapse`).

  Injected automatically by `TransformInheritedRefs` — do not reference this module
  directly; use the `inherited_characteristic` DSL entity inside `characteristics do`.

  ## Cross-world resolution

  Unlike `inherited_place` / `inherited_party` (which query universal `PlaceRef` /
  `PartyRef`), the typed characteristic module varies per reached resource. This calc
  resolves it at runtime via `AshNeo4j.worlds/1` on each struct and
  `Diffo.Provider.Extension.Info.provider_characteristics/1` on its outermost resource.
  Late-binding by design — the reached resource may not exist at the consumer's compile
  time.

  ## Result shape

  Without `collapse`, a list per input record — one entry per reached instance. Each entry
  is:

  - A `BaseCharacteristic`-derived record (or a list of such records when the reached
    resource's characteristic declaration is `{:array, M}`).
  - `%Diffo.Unknown{}` when the instance can't be projected to a loadable resource module,
    or its module declares no characteristic at the `read` role.

  With `collapse: :first | :last`, a single such entry or `nil` (empty result).

  When `as` is set, each `BaseCharacteristic` record is renamed to that name (both the
  loaded value and, via surfacing, the encoded TMF entry); `%Diffo.Unknown{}` sentinels are
  left untouched.

  ## Reason vocabulary (local to this world)

  - `:no_concrete_world` — `AshNeo4j.worlds/1` returned `[]`; the reached struct has no
    labels resolvable to a loaded `AshNeo4j.DataLayer` resource. `:context` carries
    `%{source_id: id}`.
  - `:role_not_declared` — the outermost world's resource exists but its
    `provider_characteristics/1` has no entry for the `read` role. `:context` carries
    `%{source_id: id, resource: module, role: atom}`.

  Per the **Cross-domain lookups** AGENTS.md section, reasons are world-local — consumers in
  other worlds should treat them as opaque and (if composing) wrap via `:inner_unknown`.
  """
  use Ash.Resource.Calculation

  alias Diffo.Provider.Calculations.Traversal

  @impl true
  def load(_query, _opts, _context), do: []

  @impl true
  def calculate(records, opts, _context) do
    hops = opts[:hops]
    read = opts[:read]
    as = opts[:as]
    world = opts[:world]
    collapse = opts[:collapse]

    Enum.map(records, fn record ->
      record.id
      |> Traversal.walk(hops)
      |> Enum.flat_map(&resolve_instance(&1, read, world))
      |> rename(as)
      |> collapse(collapse)
    end)
  end

  defp resolve_instance(instance_id, role, world) do
    case Ash.get(Diffo.Provider.Instance, instance_id, domain: Diffo.Provider) do
      {:error, _} ->
        []

      {:ok, instance} ->
        case AshNeo4j.worlds(instance) do
          [{_domain, resource} | _] ->
            read_characteristic(resource, instance_id, role, world)

          [] ->
            [
              %Diffo.Unknown{
                world: world,
                reason: :no_concrete_world,
                context: %{source_id: instance_id, role: role}
              }
            ]
        end
    end
  end

  defp read_characteristic(resource, instance_id, role, world) do
    case find_characteristic_entity(resource, role) do
      nil ->
        [
          %Diffo.Unknown{
            world: world,
            reason: :role_not_declared,
            context: %{source_id: instance_id, resource: resource, role: role}
          }
        ]

      %{value_type: {:array, char_module}} ->
        query_records(char_module, instance_id)

      %{value_type: char_module} when is_atom(char_module) ->
        query_records(char_module, instance_id)
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

  # Rename the surfaced characteristic. Concrete records get the new name; Unknown
  # sentinels (a diagnostic surface, dropped before the wire) are left as-is.
  defp rename(entries, nil), do: entries

  defp rename(entries, as) do
    Enum.map(entries, fn
      %Diffo.Unknown{} = unknown -> unknown
      record -> %{record | name: as}
    end)
  end

  # Collapse the consumer-ordered list to one end. nil collapse leaves the list.
  defp collapse(entries, nil), do: entries
  defp collapse(entries, :first), do: List.first(entries)
  defp collapse(entries, :last), do: List.last(entries)
end
