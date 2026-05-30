# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Resource do
  @moduledoc """
  Ash Resource Fragment for the Resource half of the Instance cascade (TMF639).

  Compose with `Diffo.Provider.BaseInstance` on a concrete Resource leaf to get the
  resource lifecycle state, the `lifecycle` action, and the TMF639-shaped jason
  wire form:

      defmodule MyApp.Card do
        use Ash.Resource,
          fragments: [Diffo.Provider.BaseInstance, Diffo.Provider.Resource],
          domain: MyApp.Domain

        provider do
          specification do
            id "..."
            name "card"
            type :resourceSpecification
          end
          # characteristics / features / parties / places / behaviour ...
        end
      end

  `BaseInstance` carries everything shared with Services. This fragment carries
  only what is resource-specific.

  ## Resource state

  Two layers, both ITU-grounded:

  - **`lifecycle_state`** — the resource lifecycle, from ITU-T M.3701. TMF639 v4
    omitted a lifecycle field, so this began as a near-universal customization;
    **TMF639 v5 standardised it as `lifecycleState`** (the wire key emitted here)
    with values `planned` / `installed` / `pendingRemoval` — the resting-state
    (milestone) form: you reach `planned` by *finishing* planning. `nil` is both the
    initial and the removed/terminal state (no explicit cancelled/terminated). For a
    resource, `installed` is the equivalent of a service "operating" — present and
    usable, just not as actively stateful as a service.
  - **`administrative_state` / `operational_state` / `usage_state` /
    `resource_status`** — the TMF639 v4 status attributes from the ITU-T X.731 /
    M.3100 state-management model. They are **orthogonal** — any axis moves
    independently — so they are plain enums, not a state machine. (v5 decomposes the
    single `resource_status` into alarm/availability/procedural/control/standby
    status; `resource_status` is kept `allow_nil?` as a v4 back-compat escape hatch.)

  `lifecycle_state` is a genuine ordered lifecycle and is the natural candidate for
  an `AshStateMachine` (symmetric with `Service.state`) — deferred to #189 so its
  transition rules land with the other state machines, and to avoid widening
  ash_neo4j#284 across Resource leaves before that upstream fix.
  """
  use Spark.Dsl.Fragment,
    of: Ash.Resource,
    extensions: [AshOutstanding.Resource, AshJason.Resource]

  alias Diffo.Util, as: Util
  alias Diffo.Provider.Instance.Util, as: Instance

  attributes do
    attribute :lifecycle_state, :atom do
      description "the TMF639 v5 lifecycleState for resource instances: planned, installed, or pendingRemoval (nil is both the initial and the removed/terminal state)"
      allow_nil? true
      public? true
      default nil
      constraints one_of: [:planned, :installed, :pendingRemoval]
    end

    attribute :resource_version, :string do
      description "the TMF639 resourceVersion identifier"
      allow_nil? true
      public? true
    end

    # TMF639's status axes are orthogonal — any axis can move to any value at any
    # time, so they are plain enums, not a state machine.
    attribute :administrative_state, :atom do
      description "the TMF639 administrativeState"
      allow_nil? true
      public? true
      constraints one_of: [:locked, :unlocked, :shutdown]
    end

    attribute :operational_state, :atom do
      description "the TMF639 operationalState"
      allow_nil? true
      public? true
      constraints one_of: [:enabled, :disabled]
    end

    attribute :usage_state, :atom do
      description "the TMF639 usageState"
      allow_nil? true
      public? true
      constraints one_of: [:idle, :active, :busy]
    end

    attribute :resource_status, :atom do
      description "the TMF639 resourceStatus"
      allow_nil? true
      public? true
      constraints one_of: [:standby, :alarm, :available, :reserved, :suspended]
    end
  end

  actions do
    update :lifecycle do
      description "sets the TMF639 lifecycleState and orthogonal status axes for a resource instance"
      require_atomic? false
      validate attribute_equals(:type, :resource)

      accept [
        :lifecycle_state,
        :resource_version,
        :administrative_state,
        :operational_state,
        :usage_state,
        :resource_status
      ]
    end
  end

  jason do
    pick [
      :id,
      :href,
      :name,
      :external_identifiers,
      :specification,
      :process_statuses,
      :forward_relationships,
      :assignments,
      :features,
      :characteristics,
      :entities,
      :places,
      :parties,
      :type
    ]

    compact true

    customize fn result, record ->
      result
      |> Instance.category(record)
      |> Instance.description(record)
      |> Util.suppress_rename(:external_identifiers, :externalIdentifier)
      |> Instance.resource_dates(record)
      |> Instance.resource_states(record)
      |> Instance.relationships()
      |> Util.rename(:specification, record.specification.type)
      |> Util.suppress_rename(:process_statuses, :processStatus)
      |> Util.suppress_rename(:features, :activationFeature)
      |> Instance.merge_typed_and_pool_characteristics(record)
      |> Util.suppress_rename(:characteristics, :resourceCharacteristic)
      |> Util.suppress_rename(:entities, :relatedEntity)
      |> Util.suppress_rename(:notes, :note)
      |> Util.suppress_rename(:places, :place)
      |> Util.suppress_rename(:parties, :relatedParty)
    end

    order [
      :id,
      :href,
      :category,
      :description,
      :name,
      :externalIdentifier,
      :resourceSpecification,
      :resourceVersion,
      :startOperatingDate,
      :endOperatingDate,
      :lifecycleState,
      :administrativeState,
      :operationalState,
      :resourceStatus,
      :usageState,
      :processStatus,
      :serviceRelationship,
      :resourceRelationship,
      :supportingService,
      :supportingResource,
      :activationFeature,
      :resourceCharacteristic,
      :relatedEntity,
      :notes,
      :place,
      :relatedParty
    ]
  end

  outstanding do
    expect [:specification, :type, :lifecycle_state]
  end
end
