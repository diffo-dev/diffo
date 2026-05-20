# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.AssignmentRelationship do
  @moduledoc """
  Ash Resource for a pool assignment relationship.

  Stores a single pool assignment as a direct Neo4j relationship between a source
  (the pool-owning instance) and a target (the assignee instance). `pool`, `thing`,
  and `value` are top-level scalar attributes, making them filterable at the Cypher
  level and usable in aggregate filters via AshNeo4j #253.

  Contrast with `DefinedSimpleRelationship`, which stores its characteristic as an
  embedded `NameValuePrimitive` — suitable as a general primitive but opaque to the
  data layer for filtering purposes.

  Actions: **create** and **destroy** only. Assignments are commitments; to change
  an assignment, destroy and recreate.
  """
  use Ash.Resource,
    fragments: [Diffo.Provider.BaseRelationship],
    otp_app: :diffo,
    domain: Diffo.Provider

  resource do
    description "A pool assignment relationship between a source and target instance"
    plural_name :assignment_relationships
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
      reference = %Diffo.Provider.Reference{
        id: record.target_id,
        href: record.target_href
      }

      list_name =
        Diffo.Provider.Relationship.derive_relationship_characteristic_list_name(
          record.target_type
        )

      characteristics =
        [%{name: record.thing, value: record.value}]
        |> then(fn chars ->
          case record.alias do
            nil -> chars
            a -> chars ++ [%{name: :alias, value: a}]
          end
        end)

      result
      |> Diffo.Util.set(record.target_type, reference)
      |> Diffo.Util.set(list_name, characteristics)
    end

    order [
      :type,
      :resource,
      :service,
      :resourceRelationshipCharacteristic,
      :serviceRelationshipCharacteristic
    ]
  end

  actions do
    create :create do
      description "creates a pool assignment relationship between a source and target instance"
      accept [:alias, :pool, :thing, :value]

      argument :source_id, :uuid
      argument :target_id, :string

      change set_attribute(:type, :assignedTo)
      change manage_relationship(:source_id, :source, type: :append)
      change manage_relationship(:target_id, :target, type: :append)
      change Diffo.Changes.DetailRelationship
    end
  end

  attributes do
    attribute :alias, :atom do
      description "the alias of this assignment, used by the consuming instance to name the slot"
      allow_nil? true
      public? true
    end

    attribute :pool, :atom do
      description "the pool name this assignment belongs to (e.g. :ports)"
      allow_nil? false
      public? true
    end

    attribute :thing, :atom do
      description "the kind of thing being assigned (e.g. :port)"
      allow_nil? false
      public? true
    end

    attribute :value, :integer do
      description "the assigned integer value"
      allow_nil? false
      public? true
      constraints min: 0
    end
  end

  identities do
    identity :unique_assignment, [:source_id, :pool, :thing, :value] do
      pre_check? true
    end

    identity :unique_alias, [:target_id, :alias] do
      pre_check? true
    end
  end

  preparations do
    prepare build(sort: [created_at: :asc])
  end
end
