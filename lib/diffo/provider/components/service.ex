# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Service do
  @moduledoc """
  Ash Resource Fragment for the Service half of the Instance cascade (TMF638).

  Compose with `Diffo.Provider.BaseInstance` on a concrete Service leaf to get the
  service lifecycle state machine, the `state` / `operating_status` attributes, the
  service lifecycle actions, and the TMF638-shaped jason wire form:

      defmodule MyApp.Broadband do
        use Ash.Resource,
          fragments: [Diffo.Provider.BaseInstance, Diffo.Provider.Service],
          domain: MyApp.Domain

        provider do
          specification do
            id "..."
            name "broadband"
            type :serviceSpecification
          end
          # characteristics / features / parties / places / behaviour ...
        end
      end

  `BaseInstance` carries everything shared with Resources (identity, the graph
  relationships, the `provider do` Extension DSL, build wiring, shared actions).
  This fragment carries only what is service-specific.

  ## State machine

  `state` (TMF638 `ServiceStateType`) is wrapped by `AshStateMachine`:
  `initial → feasibilityChecked → reserved → inactive → active → suspended →
  terminated`, plus `cancel`. A service **terminates** or **cancels** — it never
  "retires" (retirement is a Specification concept). `operating_status`
  (`ServiceOperatingStatusType`) is an orthogonal status, not part of the machine.

  See `Diffo.Provider.ServiceState` for the state / operating-status vocabulary.
  """
  use Spark.Dsl.Fragment,
    of: Ash.Resource,
    extensions: [AshStateMachine, AshOutstanding.Resource, AshJason.Resource]

  alias Diffo.Util, as: Util
  alias Diffo.Provider.Instance.Util, as: Instance

  state_machine do
    initial_states [:initial]
    default_initial_state :initial
    state_attribute :state

    transitions do
      transition action: :cancel,
                 from: [:initial, :feasibilityChecked, :reserved],
                 to: :cancelled

      transition action: :feasibilityCheck, from: :initial, to: :feasibilityChecked
      transition action: :reserve, from: [:initial, :feasibilityChecked], to: :reserved
      transition action: :deactivate, from: [:active, :reserved], to: [:inactive]

      transition action: :activate,
                 from: [
                   :initial,
                   :feasibilityChecked,
                   :reserved,
                   :inactive,
                   :suspended,
                   :terminated
                 ],
                 to: :active

      transition action: :suspend, from: :active, to: :suspended
      transition action: :terminate, from: [:active, :inactive, :suspended], to: :terminated
    end
  end

  attributes do
    attribute :state, :atom do
      description "the TMF638 service lifecycle state"
      allow_nil? false
      default Diffo.Provider.ServiceState.default_state()
      public? true
      constraints one_of: Diffo.Provider.ServiceState.states()
    end

    attribute :operating_status, :atom do
      description "the TMF638 service operating status"
      allow_nil? true
      public? true
      default nil
      constraints one_of: Diffo.Provider.ServiceState.operating_statuses()
    end
  end

  actions do
    update :cancel do
      description "cancels a service instance"
      require_atomic? false
      change transition_state(:cancelled)
      change set_attribute(:operating_status, :unknown)
      change set_attribute(:stopped_at, &DateTime.utc_now/0)
    end

    update :feasibilityCheck do
      description "feasibilityChecks a service instance"
      require_atomic? false
      accept [:operating_status]
      change transition_state(:feasibilityChecked)

      validate argument_in(:operating_status, [
                 nil,
                 :initial,
                 :pending,
                 :unknown,
                 :feasible,
                 :not_feasible
               ])
    end

    update :reserve do
      description "reserves a service instance"
      require_atomic? false
      change transition_state(:reserved)
      change set_attribute(:operating_status, :pending)
    end

    update :deactivate do
      description "deactivates a service instance"
      require_atomic? false
      change transition_state(:inactive)
      change set_attribute(:operating_status, :configured)
    end

    update :activate do
      description "activates a service instance"
      require_atomic? false
      change transition_state(:active)
      change set_attribute(:operating_status, :starting)
      change set_attribute(:started_at, &DateTime.utc_now/0)
    end

    update :suspend do
      description "suspends a service instance"
      require_atomic? false
      change transition_state(:suspended)
      change set_attribute(:operating_status, :limited)
    end

    update :terminate do
      description "terminates a service instance"
      require_atomic? false
      change transition_state(:terminated)
      change set_attribute(:operating_status, :stopping)
      change set_attribute(:stopped_at, &DateTime.utc_now/0)
    end

    update :status do
      description "updates the operating status of a service instance"
      require_atomic? false
      accept [:operating_status]
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
      |> Instance.service_dates(record)
      |> Instance.service_states(record)
      |> Instance.relationships()
      |> Util.rename(:specification, record.specification.type)
      |> Util.suppress_rename(:process_statuses, :processStatus)
      |> Util.suppress_rename(:features, :feature)
      |> Instance.merge_typed_and_pool_characteristics(record)
      |> Util.suppress_rename(:characteristics, :serviceCharacteristic)
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
      :serviceSpecification,
      :resourceSpecification,
      :serviceDate,
      :startDate,
      :endDate,
      :state,
      :operatingStatus,
      :processStatus,
      :serviceRelationship,
      :resourceRelationship,
      :supportingService,
      :supportingResource,
      :feature,
      :serviceCharacteristic,
      :relatedEntity,
      :notes,
      :place,
      :relatedParty
    ]
  end

  outstanding do
    expect [:specification, :type, :state, :operating_status]
  end
end
