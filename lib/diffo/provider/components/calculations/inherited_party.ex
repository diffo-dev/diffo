# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Calculations.InheritedParty do
  @moduledoc """
  Backing calculation for `inherited_party` DSL declarations.

  Traverses `AssignmentRelationship` by alias to reach source instances, then reads
  their `PartyRef` records for the declared `source_role`. Injected automatically by
  `TransformInheritedRefs` — do not reference this module directly; use the
  `inherited_party` DSL entity instead.

  See `Diffo.Provider.Extension.InheritedPartyDeclaration` for the DSL options.

  ## Result shape

  A list per input record. Each entry corresponds to one source instance reached
  by the traversal:

  - One or more `Diffo.Provider.Party` values when the source has matching
    `PartyRef` records at `source_role`.
  - `%Diffo.Unknown{}` when the source is reached but carries no `PartyRef`
    at `source_role`.

  When no sources are reached at all (e.g. no assignment), the result is `[]`.
  Unknown is reserved for "we got here but the role isn't declared" — the
  X-state from the AGENTS.md `Diffo.Unknown` discipline.

  ## Reason vocabulary

  Only one reason is possible here — `PartyRef` is a universal indirection so
  no cross-world dispatch is needed (which is why this calc is cleaner than the
  characteristic equivalents):

  - `:role_not_declared` — source instance reached but its `PartyRef` records
    carry no entry at `source_role`. `:context` is `%{source_id: id, role: source_role}`.

  ## `:world` stamping

  `TransformInheritedRefs` passes the consumer's resource as `:world` at compile
  time. Each emitted `%Diffo.Unknown{}` stamps it.
  """
  use Ash.Resource.Calculation

  @impl true
  def load(_query, _opts, _context), do: []

  @impl true
  def calculate(records, opts, _context) do
    via = opts[:via]
    source_role = opts[:source_role]
    world = opts[:world]

    Enum.map(records, fn record ->
      final_ids =
        Enum.reduce(via, [record.id], fn alias_step, ids ->
          Enum.flat_map(ids, fn id ->
            Diffo.Provider.AssignmentRelationship
            |> Ash.Query.filter_input(target_id: id, alias: alias_step)
            |> Ash.read!(domain: Diffo.Provider)
            |> Enum.map(& &1.source_id)
          end)
        end)

      Enum.flat_map(final_ids, fn id ->
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
      end)
    end)
  end
end
