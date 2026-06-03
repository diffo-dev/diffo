# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Extension.InheritedPartyDeclaration do
  @moduledoc """
  DSL entity for an `inherited_party` declaration inside `parties do` on an Instance resource.

  Generates an Ash calculation of the same name as `role` that walks the instance graph to
  inherit a party from a reached instance. The calculation is injected by
  `TransformInheritedRefs` at compile time — no `PartyRef` edge is created on the consuming
  instance itself.

  ## Fields

  - `role` — atom; the name of the generated calculation (and the party slot name from the
    consumer's perspective — the surfaced `PartyRef` carries this role).
  - `source_role` — atom; the `PartyRef` role to read on each reached instance
    (e.g. `:provider`). Required. This terminal deref is **not** a `via:` hop — `via:`
    reaches the instance; routing *through* a party (the ref graph) is calc territory
    (see #227).
  - `via` — the hop chain to the instance holding the ref, in the unified #213 grammar
    (shared with `inherited_characteristic`): a bare atom is `{:reverse, assignment: alias}`
    shorthand; tuples are `{:forward | :reverse, assignment: alias}` or
    `{:forward | :reverse, relationship: type | [type: t, alias: a]}`. When `nil`, defaults
    to `[role]`. See `Diffo.Provider.Extension.Traversal`.
  - `collapse` — `:first` or `:last`; collapses the consumer-ordered result list (the refs
    at `source_role` across reached instances) to that end. When set, the calc returns a
    single party or `nil` rather than a list.

  ## Example

      parties do
        inherited_party :provider, source_role: :provider
        inherited_party :nni_owner, via: [:uplink], source_role: :owner
        # forward relationship hop + collapse to a single owner
        inherited_party :circuit_owner,
          via: [{:forward, relationship: [alias: :circuit]}],
          source_role: :owner,
          collapse: :first
      end
  """
  defstruct [:role, :via, :source_role, :collapse, __spark_metadata__: nil]

  defimpl String.Chars do
    def to_string(struct), do: inspect(struct)
  end
end
