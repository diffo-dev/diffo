# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Extension.ReverseInheritedCharacteristicDeclaration do
  @moduledoc """
  DSL entity for a `reverse_inherited_characteristic` declaration inside
  `characteristics do` on an Instance resource.

  Generates an Ash calculation that traverses the assignment graph **outward** (this
  instance as source → assignee instances), optionally filtered by alias, then reads
  the named typed characteristic value on each assignee. The calculation is injected
  by `TransformInheritedRefs` at compile time.

  Where `inherited_characteristic` follows the assignee's natural view (turtles up
  to the assigner — incoming AssignmentRelationship), `reverse_inherited_characteristic`
  follows the assigner's view (turtles down to assignees — outgoing
  AssignmentRelationship). The "reverse" in the name is reverse-of-the-natural-
  inherited-direction.

  The reverse case has three independent axes (vs the single-axis forward case):

  - the **calc name** (how it surfaces on this resource)
  - the **`assignment_alias`** (which outgoing assignment slot to follow — assignment
    fan-out is common, so consumers want to narrow by alias). Named
    `assignment_alias` rather than `alias` because `alias` is an Elixir special form
    and can't appear as a DSL option keyword.
  - the **characteristic role** (which characteristic to read on the assignee — may
    differ from the calc name on this resource since assignees can have characteristics
    of any name)

  Per-assignee the typed characteristic module is resolved at runtime via
  `AshNeo4j.worlds/1` + `Diffo.Provider.Extension.Info.provider_characteristics/1`.

  ## Fields

  - `name` — atom; the name of the generated calculation on this resource.
  - `assignment_alias` — atom; the outgoing `AssignmentRelationship` alias to follow.
    Required. (Named `assignment_alias` because `alias` is an Elixir special form
    and would collide with the generated option-importer module.)
  - `characteristic` — atom; the characteristic role to look up on each reached
    assignee (the assignee's `characteristic :role, MyApp.SomeCharacteristic`
    declaration). The typed module is found at runtime per assignee.

  ## Example

      characteristics do
        reverse_inherited_characteristic :unis,
          assignment_alias: :port,
          characteristic: :uni
      end

  ## Result shape

  Same as `inherited_characteristic` — a list of entries, one per assignee reached.
  Each entry is the typed characteristic record (or list for `{:array, _}` values), or
  `%Diffo.Unknown{}` when the assignee can't be projected back to a loadable resource
  module, or its module doesn't declare a characteristic at the named role. See
  `Diffo.Provider.Calculations.ReverseInheritedCharacteristic` for the local reason
  vocabulary.
  """
  defstruct [:name, :assignment_alias, :characteristic, __spark_metadata__: nil]

  defimpl String.Chars do
    def to_string(struct), do: inspect(struct)
  end
end
