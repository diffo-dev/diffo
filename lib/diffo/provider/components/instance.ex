# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Instance do
  @moduledoc """
  The generic TMF Service Instance, and the abstract reader for the
  Service/Resource cascade.

  Composes `[BaseInstance, Service]`, so it is a concrete Service (carries the
  service lifecycle state machine) usable directly. It also doubles as the
  abstract reader that `Diffo.Provider.get_instance_by_id!/1` and friends load
  through, projecting each record to its outermost concrete world (a consumer
  Service/Resource leaf) via `AshNeo4j.worlds/1` before returning.

  An instance is **exactly one** of Service or Resource. Concrete Resource
  instances compose `[BaseInstance, Resource]` on their own leaf — the generic
  `Diffo.Provider.ResourceInstance`, or a consumer leaf like `MyApp.Card`; they
  carry no service lifecycle.

  See `Diffo.Provider.BaseInstance` for the shared base, `Diffo.Provider.Service`
  and `Diffo.Provider.Resource` for the subtype fragments.
  """
  alias Diffo.Provider.BaseInstance
  alias Diffo.Provider.Service

  use Ash.Resource,
    fragments: [BaseInstance, Service],
    domain: Diffo.Provider

  resource do
    description "An Ash Resource for a TMF Service Instance"
    plural_name :instances
  end
end
