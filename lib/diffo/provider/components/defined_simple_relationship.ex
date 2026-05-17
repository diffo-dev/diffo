# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.DefinedSimpleRelationship do
  @moduledoc """
  Ash Resource for a relationship with an optional single embedded characteristic,
  set at creation and never changed.

  Extends `BaseRelationship` (source, target, type, timestamps). Optionally carries
  one `DefinedCharacteristic` — a name/value pair stored directly on the Neo4j node.
  The value is a `Diffo.Type.Primitive`, covering string, integer, float, boolean,
  and temporal types.

  Actions: **create** and **destroy** only. No update, no relate/unrelate. Once
  defined, the characteristic is closed — that is the commitment.

  Contrast with `Provider.Relationship` which allows mutable graph-based `Characteristic`
  nodes to be added, removed, and updated over time.

  `DefinedSimpleRelationship` is a general Provider primitive for any relationship
  whose characteristic is a commitment or promise made at creation time.
  """
  use Ash.Resource,
    fragments: [Diffo.Provider.BaseRelationship],
    otp_app: :diffo,
    domain: Diffo.Provider

  resource do
    description "An Ash Resource for a relationship with a single optional characteristic, defined at creation and closed thereafter"
    plural_name :defined_simple_relationships
  end

  neo4j do
    relate [
      {:source, :RELATES, :incoming, :Instance},
      {:target, :RELATES, :outgoing, :Instance}
    ]
  end

  jason do
    pick [:alias, :type]

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
      |> Diffo.Util.suppress(:alias)
      |> then(fn r ->
        case Map.get(record, :characteristic) do
          nil -> r
          char -> Diffo.Util.set(r, list_name, [char])
        end
      end)
    end

    order [
      :alias,
      :type,
      :service,
      :resource,
      :serviceRelationshipCharacteristic,
      :resourceRelationshipCharacteristic
    ]
  end

  actions do
    create :create do
      description "creates a defined simple relationship between a source and target instance"
      accept [:alias, :type, :characteristic]

      argument :source_id, :uuid
      argument :target_id, :string

      change manage_relationship(:source_id, :source, type: :append)
      change manage_relationship(:target_id, :target, type: :append)
      change Diffo.Changes.DetailRelationship
    end
  end

  attributes do
    attribute :alias, :atom do
      description "an optional alias for this relationship"
      allow_nil? true
      public? true
    end

    attribute :characteristic, Diffo.Type.NameValuePrimitive do
      description "an optional single defining characteristic, set at creation and closed thereafter"
      allow_nil? true
      public? true
    end
  end

  preparations do
    prepare build(sort: [created_at: :asc])
  end
end
