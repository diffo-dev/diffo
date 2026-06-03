# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Calculations.InheritedParty do
  @moduledoc """
  Backing calculation for `inherited_party` DSL declarations.

  Walks the instance graph along the `via:` hop chain (the shared
  `Diffo.Provider.Calculations.Traversal` — `:forward`/`:reverse` over `assignment` /
  `relationship` edges), then reads each reached instance's `PartyRef` records at the
  declared `source_role`, optionally collapsing the result to one end. Injected
  automatically by `TransformInheritedRefs` — do not reference this module directly; use the
  `inherited_party` DSL entity instead.

  `via:` reaches the *instance* that holds the ref; the `source_role` deref is a fixed
  terminal step, **not** a `via:` hop. Routing *through* a party — the ref graph — is a
  calculation concern, not a `via:` capability (see #227).

  See `Diffo.Provider.Extension.InheritedPartyDeclaration` for the DSL options.

  ## Result shape

  Without `collapse`, a list per input record — one or more `Diffo.Provider.Party` values
  per reached instance that carries a `PartyRef` at `source_role`, or `%Diffo.Unknown{}`
  when an instance is reached but has no `PartyRef` there. With `collapse: :first | :last`,
  a single value (or `nil`). When no instance is reached at all, `[]` (or `nil` when
  collapsing).

  ## Reason vocabulary

  `PartyRef` is a universal indirection (no cross-world dispatch), so only one reason:

  - `:role_not_declared` — instance reached but its `PartyRef` records carry no entry at
    `source_role`. `:context` is `%{source_id: id, role: source_role}`.

  ## `:world` stamping

  `TransformInheritedRefs` passes the consumer's resource as `:world` at compile time; each
  emitted `%Diffo.Unknown{}` stamps it.
  """
  use Ash.Resource.Calculation

  alias Diffo.Provider.Calculations.Traversal

  @impl true
  def load(_query, _opts, _context), do: []

  @impl true
  def calculate(records, opts, _context) do
    hops = opts[:hops]
    source_role = opts[:source_role]
    world = opts[:world]
    collapse = opts[:collapse]

    Enum.map(records, fn record ->
      record.id
      |> Traversal.walk(hops)
      |> Enum.flat_map(&resolve_parties(&1, source_role, world))
      |> collapse(collapse)
    end)
  end

  defp resolve_parties(id, source_role, world) do
    parties =
      Diffo.Provider.PartyRef
      |> Ash.Query.filter_input(instance_id: id, role: source_role)
      |> Ash.Query.load(:party)
      |> Ash.read!(domain: Diffo.Provider)
      |> Enum.map(& &1.party)

    case parties do
      [] ->
        [
          %Diffo.Unknown{
            world: world,
            reason: :role_not_declared,
            context: %{source_id: id, role: source_role}
          }
        ]

      _ ->
        parties
    end
  end

  defp collapse(entries, nil), do: entries
  defp collapse(entries, :first), do: List.first(entries)
  defp collapse(entries, :last), do: List.last(entries)
end
