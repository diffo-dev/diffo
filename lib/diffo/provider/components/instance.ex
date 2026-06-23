# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Instance do
  @moduledoc """
  Abstract Instance reader — plumbing, not a TMF subtype recommendation.

  An instance is **exactly one** of Service or Resource; the concrete leaves are
  `Diffo.Provider.ServiceInstance` (`[BaseInstance, Service]` — the service lifecycle
  state machine) and `Diffo.Provider.ResourceInstance` (`[BaseInstance, Resource]`), or a
  consumer leaf composed from `BaseInstance` + the matching subtype fragment (e.g.
  `MyApp.Card`). Use those, or the `Diffo.Provider.create_instance!/1` dispatcher, for any
  **new** instance.

  This resource composes only `[BaseInstance]` and is kept in core to serve as the
  **abstract reader / projection bootstrap**: `Diffo.Provider.get_instance_by_id!/1` and
  friends load via this resource so `AshNeo4j.worlds/1` can project the loaded node to its
  outermost concrete world (a `ServiceInstance` / `ResourceInstance` / consumer leaf) before
  returning. Symmetric with `Diffo.Provider.Place` and `Diffo.Provider.Party`.

  See `Diffo.Provider.BaseInstance` for the shared base, and `Diffo.Provider.Service` /
  `Diffo.Provider.Resource` for the subtype fragments.
  """
  alias Diffo.Provider.BaseInstance

  use Ash.Resource,
    fragments: [BaseInstance],
    domain: Diffo.Provider

  resource do
    description "An Ash Resource for a TMF Instance"
    plural_name :instances
  end

  jason do
    pick [:id, :href, :name, :type]
    compact true
  end

  outstanding do
    expect [:id, :name, :type]
  end
end
