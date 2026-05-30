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

  TMF639's `lifecycleState` (`resource_state`: planning → installing → operating →
  retiring) is a plain atom, set via the `lifecycle` action — no state machine, as
  resources have no single linear transition constraint. The orthogonal TMF639
  status axes (administrative / operational / usage / resourceStatus) land in
  Phase B as further plain enums.
  """
  use Spark.Dsl.Fragment,
    of: Ash.Resource,
    extensions: [AshOutstanding.Resource, AshJason.Resource]

  alias Diffo.Util, as: Util
  alias Diffo.Provider.Instance.Util, as: Instance

  attributes do
    attribute :resource_state, :atom do
      description "the TMF639 lifecycleState for resource instances: planning, installing, operating, or retiring"
      allow_nil? true
      public? true
      default nil
      constraints one_of: [:planning, :installing, :operating, :retiring]
    end
  end

  actions do
    update :lifecycle do
      description "sets the TMF lifecycleState for a resource instance"
      require_atomic? false
      validate attribute_equals(:type, :resource)
      accept [:resource_state]
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
    expect [:specification, :type, :resource_state]
  end
end
