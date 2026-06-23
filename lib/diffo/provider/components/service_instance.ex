# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.ServiceInstance do
  @moduledoc """
  The generic TMF Service Instance — composes `[BaseInstance, Service]`, so it
  carries the service lifecycle state machine, the `state` / `operating_status`
  attributes, the service lifecycle actions, and the TMF638-shaped jason wire form.

  The Service counterpart to `Diffo.Provider.ResourceInstance` (the generic
  Resource). `Diffo.Provider.create_instance!/1` dispatches here when the referenced
  specification is a `:serviceSpecification`.

  Reads go through the abstract reader `Diffo.Provider.Instance`, which projects each
  record to its outermost concrete world via `AshNeo4j.worlds/1` — a `ServiceInstance`
  node (or a consumer Service leaf) — before returning.

  See `Diffo.Provider.Service` for the service subtype fragment and
  `Diffo.Provider.BaseInstance` for the shared base.
  """
  alias Diffo.Provider.BaseInstance
  alias Diffo.Provider.Service

  use Ash.Resource,
    fragments: [BaseInstance, Service],
    domain: Diffo.Provider

  resource do
    description "An Ash Resource for a TMF Service Instance"
    plural_name :service_instances
  end
end
