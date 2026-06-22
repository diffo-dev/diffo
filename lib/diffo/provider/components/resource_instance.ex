# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.ResourceInstance do
  @moduledoc """
  The generic TMF Resource Instance — the resource-flavoured counterpart to
  `Diffo.Provider.Instance` (the generic Service).

  Composes `[BaseInstance, Resource]`, so it is a concrete Resource carrying the
  resource lifecycle (`lifecycle_state` and the TMF639 status attributes), usable
  directly. `Diffo.Provider.create_instance!/1` dispatches here when the referenced
  specification is a `:resourceSpecification`.

  An instance is **exactly one** of Service or Resource: this leaf carries the
  resource lifecycle, not the service state machine. Reads still go through the
  abstract reader `Diffo.Provider.Instance`, which projects each record to its
  outermost concrete world via `AshNeo4j.worlds/1`.

  See `Diffo.Provider.Resource` for the resource subtype fragment and
  `Diffo.Provider.BaseInstance` for the shared base.
  """
  alias Diffo.Provider.BaseInstance
  alias Diffo.Provider.Resource

  use Ash.Resource,
    fragments: [BaseInstance, Resource],
    domain: Diffo.Provider

  resource do
    description "An Ash Resource for a TMF Resource Instance"
    plural_name :resource_instances
  end
end
