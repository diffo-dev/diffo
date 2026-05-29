# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Test.Instance.AccessService do
  @moduledoc """
  Minimal test service instance that declares an inherited_place.
  Used by inherited_refs_test.exs to verify assignment alias traversal.
  """
  alias Diffo.Provider.BaseInstance
  alias Diffo.Test.Servo

  use Ash.Resource,
    fragments: [BaseInstance],
    domain: Servo

  resource do
    description "A test access service with an inherited place via assignment alias"
    plural_name :access_services
  end

  provider do
    specification do
      id "c4e7a2b1-3d5f-4a6b-8c9d-0e1f2a3b4c5d"
      name "accessService"
      type :serviceSpecification
      description "A test access service instance"
      category "Access"
    end

    places do
      inherited_place :primary, source_role: :location
    end

    parties do
      inherited_party :owner, via: [:primary], source_role: :provider
    end

    characteristics do
      # Inherit the source instance's :card characteristic by traversing
      # the :primary assignment alias inward (this service is the assignee
      # of a card's port assignment). Per-source the typed module is
      # resolved at runtime via AshNeo4j.worlds/1 — late-binding by design.
      inherited_characteristic :card, via: [:primary]
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
      change load [:href]
      upsert? false
    end
  end

  calculations do
    calculate :assigner_name,
              {:array, :string},
              {Diffo.Provider.Calculations.FieldViaAssignedRelationship,
               [via: [:primary], field: :name]}

    calculate :assigner_names,
              {:array, :string},
              {Diffo.Provider.Calculations.FieldViaAssignedRelationship, [field: :name]}

    calculate :assigned_port,
              {:array, :integer},
              {Diffo.Provider.Calculations.FieldFromAssignment, [alias: :primary, field: :value]}

    calculate :all_assignment_values,
              {:array, :integer},
              {Diffo.Provider.Calculations.FieldFromAssignment, [field: :value]}
  end
end
