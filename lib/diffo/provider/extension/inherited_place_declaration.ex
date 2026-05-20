# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Extension.InheritedPlaceDeclaration do
  @moduledoc """
  DSL entity for an `inherited_place` declaration inside `places do` on an Instance resource.

  Generates an Ash calculation of the same name as `role` that traverses the assignment
  graph to inherit a place from a related source instance. The calculation is injected
  by `TransformInheritedRefs` at compile time — no `PlaceRef` edge is created on the
  consuming instance itself.

  ## Fields

  - `role` — atom; the name of the generated calculation (and the place slot name from
    the consumer's perspective).
  - `source_role` — atom; the `PlaceRef` role to read from the resolved source instance
    (e.g. `:location`). Required.
  - `via` — optional list of alias atoms for multi-hop traversal. When nil the role name
    is used as the single alias step (single-hop default). When provided, each step
    filters `AssignmentRelationship` by that alias atom before following `source_id` to
    the next set of instances.

  ## Example

      places do
        inherited_place :installation_site, source_role: :location
        inherited_place :exchange, via: [:primary, :uplink], source_role: :location
      end
  """
  defstruct [:role, :via, :source_role, __spark_metadata__: nil]

  defimpl String.Chars do
    def to_string(struct), do: inspect(struct)
  end
end
