# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Extension.InheritedCharacteristicDeclaration do
  @moduledoc """
  DSL entity for an `inherited_characteristic` declaration inside `characteristics do`
  on an Instance resource.

  Generates an Ash calculation that traverses the assignment graph **inward** (this
  instance as target → source instances), then reads the typed characteristic value
  declared at the given role on each source. The calculation is injected by
  `TransformInheritedRefs` at compile time — no direct edge or characteristic record
  is created on the consuming instance itself.

  Unlike `inherited_place` / `inherited_party` (which read against universal `PlaceRef` /
  `PartyRef`), the typed characteristic module **varies per source resource**. The
  resolution happens at runtime via `AshNeo4j.worlds/1` on the source struct and
  `Diffo.Provider.Extension.Info.provider_characteristics/1` on the source's outermost
  resource module. This is late-binding by design — the source resource may not exist
  at the consumer's compile time.

  ## Fields

  - `role` — atom; the name of the generated calculation **and** the characteristic
    role to look up on each source instance (the source's
    `characteristic :role, MyApp.SomeCharacteristic` declaration). Per-source the
    `MyApp.SomeCharacteristic` module is found at runtime.
  - `via` — optional list of alias atoms for multi-hop traversal. When nil the role
    name is used as the single alias step (single-hop default). When provided, each
    step filters `AssignmentRelationship` by that alias atom before following
    `source_id` to the next set of instances.

  ## Example

      characteristics do
        inherited_characteristic :uni
        inherited_characteristic :upstream_ntd, via: [:port, :uplink]
      end

  ## Result shape

  The injected calculation returns a list of entries, one per source instance reached
  by the traversal. Each entry is one of:

  - the typed characteristic record (or list of records for `{:array, _}` characteristic
    values), when the source carries a characteristic at the declared role.
  - `%Diffo.Unknown{}` when the source can't be projected back to a loadable resource
    module, or its module doesn't declare a characteristic at this role. See
    `Diffo.Provider.Calculations.InheritedCharacteristic` for the local reason
    vocabulary.
  """
  defstruct [:role, :via, __spark_metadata__: nil]

  defimpl String.Chars do
    def to_string(struct), do: inspect(struct)
  end
end
