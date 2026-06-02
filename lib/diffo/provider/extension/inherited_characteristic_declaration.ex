# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Extension.InheritedCharacteristicDeclaration do
  @moduledoc """
  DSL entity for an `inherited_characteristic` declaration inside `characteristics do`
  on an Instance resource.

  Generates an Ash calculation that derives a typed characteristic by walking the graph
  along a `via:` hop chain, reading the characteristic at a role on the final node(s), and
  optionally renaming and collapsing the result. The calculation is injected by
  `TransformInheritedRefs` at compile time — no direct edge or characteristic record is
  created on the consuming instance itself.

  Unlike `inherited_place` / `inherited_party` (which read against universal `PlaceRef` /
  `PartyRef`), the typed characteristic module **varies per reached resource** and is
  resolved at runtime via `AshNeo4j.worlds/1` on each struct and
  `Diffo.Provider.Extension.Info.provider_characteristics/1` on its outermost resource.
  Late-binding by design.

  ## Traversal grammar

  `via:` is an ordered list of hops; each walks one edge in one direction (see
  `Diffo.Provider.Extension.Traversal` for the full grammar and
  `Diffo.Provider.Calculations.Traversal` for the runtime walk):

  - `alias` *(bare atom)* — shorthand for `{:reverse, assignment: alias}` (inherit from
    your assigner — the common case). An omitted `via:` defaults to `[name]`.
  - `{:forward | :reverse, assignment: alias}`
  - `{:forward | :reverse, relationship: type}` or
    `{:forward | :reverse, relationship: [type: t, alias: a]}`

  `:forward` means this instance is the edge `source` (`source_id = me`, follow to
  `target`); `:reverse` means this instance is the edge `target` (`target_id = me`, follow
  to `source`). Mechanism (`assignment` / `relationship`) and direction are independent, so
  chains of any length and any mix compose.

  ## Fields

  - `name` — atom; the name of the generated calculation (the Ash load/field handle), and
    the default `read` role.
  - `via` — the hop list (see grammar above). When `nil`, defaults to `[name]`.
  - `read` — atom; the characteristic role to look up on each reached instance. Defaults to
    `name`. (Per-reached-instance the typed module is found at runtime.)
  - `as` — atom; renames the surfaced characteristic to this name (both the loaded value
    and the encoded TMF entry). Defaults to the source characteristic's own name (no
    rename).
  - `collapse` — `:first` or `:last`; collapses the consumer-ordered result list to that
    end (`List.first/1` / `List.last/1`). When set, the calc returns a single record or
    `nil` rather than a list.

  ## Example

      characteristics do
        inherited_characteristic :card, via: [:primary]
        inherited_characteristic :nnis, via: [{:forward, relationship: :contains}]
        inherited_characteristic :cvc,
          via: [{:forward, relationship: [alias: :circuit]}, {:reverse, assignment: :cvlan}],
          read: :cvc, collapse: :first
      end

  ## Result shape

  Without `collapse`, a list of entries — one per reached instance carrying a
  characteristic at the `read` role (or a list of records for `{:array, _}` values). With
  `collapse`, a single such record or `nil`. `%Diffo.Unknown{}` entries appear when a
  reached struct can't be projected to a loadable resource or declares no characteristic at
  the role; see `Diffo.Provider.Calculations.InheritedCharacteristic` for the reason
  vocabulary.
  """
  defstruct [:name, :via, :read, :as, :collapse, __spark_metadata__: nil]

  defimpl String.Chars do
    def to_string(struct), do: inspect(struct)
  end
end
