# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.AssignedToRelationship do
  @moduledoc """
  Ash Resource for a pool assignment relationship.

  Carries the assignment attributes (`pool`, `thing`, `assigned`) that link a
  source instance to an assignee instance. Stored as an `:AssignedToRelationship`
  Neo4j node, distinct from the `:Relationship` nodes used for TMF service/resource
  relationships. Accessible on an instance via `instance.assignments`.

  Created by `Diffo.Provider.Assigner` via `Diffo.Provider.create_assigned_to_relationship/1`.
  """
  use Ash.Resource,
    fragments: [Diffo.Provider.BaseRelationship],
    otp_app: :diffo,
    domain: Diffo.Provider

  resource do
    description "An Ash Resource for a pool assignment relationship"
    plural_name :assigned_to_relationships
  end

  neo4j do
    relate [
      {:source, :RELATES, :incoming, :Instance},
      {:target, :RELATES, :outgoing, :Instance}
    ]
  end

  jason do
    pick [:type]

    customize fn result, record ->
      target_type = Map.get(record, :target_type)

      reference = %Diffo.Provider.Reference{
        id: record.target_id,
        href: Map.get(record, :target_href)
      }

      list_name =
        Diffo.Provider.Relationship.derive_relationship_characteristic_list_name(target_type)

      result
      |> Diffo.Util.set(target_type, reference)
      |> Diffo.Util.set(list_name, [%{name: record.thing, value: record.assigned}])
    end

    order [
      :type,
      :service,
      :resource,
      :serviceRelationshipCharacteristic,
      :resourceRelationshipCharacteristic
    ]
  end

  actions do
    create :create_assignment do
      description "creates an assignedTo relationship with pool/thing/assigned attributes"
      accept [:pool, :thing, :assigned]

      argument :source_id, :uuid
      argument :target_id, :string

      change set_attribute(:type, :assignedTo)
      change manage_relationship(:source_id, :source, type: :append)
      change manage_relationship(:target_id, :target, type: :append)
      change Diffo.Changes.DetailRelationship
    end
  end

  attributes do
    attribute :pool, :atom do
      description "the pool name on the source instance"
      allow_nil? true
      public? true
    end

    attribute :thing, :atom do
      description "the kind of thing being assigned within the pool"
      allow_nil? true
      public? true
    end

    attribute :assigned, :integer do
      description "the assigned value from the pool"
      allow_nil? true
      public? true
    end
  end

  identities do
    identity :unique_assignment, [:source_id, :target_id, :pool, :thing, :assigned]
  end

  preparations do
    prepare build(sort: [created_at: :asc])
  end
end
