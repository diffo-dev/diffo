# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Test.Instance.TraversalProbe do
  @moduledoc """
  Test instance exercising the unified `inherited_characteristic` traversal DSL (#213).

  Declares calcs covering forward `DefinedSimpleRelationship` traversal (plural and
  singular), a mixed relationship→assignment chain, `collapse` (`:first`/`:last`), an
  `as:` rename, and the 5-hop lawful-intercept showcase. Every calc reads the `:card`
  characteristic from the reached `CardInstance`s; structural intermediates (PRI / AVC /
  CVC / NNI Group) are modelled as generic graph nodes, and the NNIs as `CardInstance`s —
  the test wires the edges directly via `create_assignment_relationship!` /
  `create_defined_simple_relationship!`, so the probe itself needs no pools.
  """
  alias Diffo.Provider.BaseInstance
  alias Diffo.Provider.Service
  alias Diffo.Test.Servo

  use Ash.Resource,
    fragments: [BaseInstance, Service],
    domain: Servo

  resource do
    description "A test probe for inherited_characteristic graph traversal"
    plural_name :traversal_probes
  end

  provider do
    specification do
      id "f1e2d3c4-b5a6-4708-9c1d-2e3f4a5b6c7d"
      name "traversalProbe"
      type :serviceSpecification
      description "A test probe instance for graph traversal"
      category "Test"
    end

    characteristics do
      # #212-A forward relationship — plural (every contained card), and singular + collapse
      inherited_characteristic :contained_cards,
        via: [{:forward, relationship: :contains}],
        read: :card

      inherited_characteristic :owned_card,
        via: [{:forward, relationship: [alias: :circuit]}],
        read: :card,
        collapse: :first

      # #211 collapse over a forward-assignment fan-out
      inherited_characteristic :first_slot_card,
        via: [{:forward, assignment: :slot}],
        read: :card,
        collapse: :first

      inherited_characteristic :last_slot_card,
        via: [{:forward, assignment: :slot}],
        read: :card,
        collapse: :last

      # as: rename of the surfaced characteristic
      inherited_characteristic :tapped_cards,
        via: [{:forward, assignment: :slot}],
        read: :card,
        as: :tappedCard

      # #212-B mixed chain — forward relationship then reverse assignment
      inherited_characteristic :mixed_card,
        via: [{:forward, relationship: [alias: :circuit]}, {:reverse, assignment: :cvlan}],
        read: :card,
        collapse: :first

      # 5-hop lawful-intercept showcase: which NNIs could this (logical) UNI traverse?
      # UNI → its PRI → owned AVC → its CVC → its NNI Group → all contained NNIs.
      inherited_characteristic :intercept_nnis,
        via: [
          {:reverse, relationship: [type: :owns, alias: :port]},
          {:forward, relationship: [alias: :circuit]},
          {:reverse, assignment: :cvlan},
          {:reverse, assignment: :svlan},
          {:forward, relationship: :contains}
        ],
        read: :card
    end

    behaviour do
      actions do
        create :build
      end
    end
  end

  actions do
    create :build do
      accept [:id, :name, :type]
      change set_attribute(:type, :service)
      change load([:href])
      upsert? false
    end
  end
end
