# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Relationship do
  @moduledoc """

  Ash Resource for a TMF Service or Resource Relationship
  """
  use Ash.Resource,
    fragments: [Diffo.Provider.BaseRelationship],
    extensions: [AshOutstanding.Resource],
    otp_app: :diffo,
    domain: Diffo.Provider

  resource do
    description "An Ash Resource for a TMF Service or Resource Relationship"
    plural_name :relationships
  end

  neo4j do
    relate [
      {:source, :RELATES, :incoming, :Instance},
      {:target, :RELATES, :outgoing, :Instance},
      {:characteristics, :HAS, :outgoing, :Characteristic}
    ]

    guard [
      {:HAS, :outgoing, :Characteristic}
    ]
  end

  jason do
    pick [:alias, :type, :characteristics]

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
      |> Diffo.Util.suppress_rename(:characteristics, list_name)
      |> Diffo.Util.suppress(:alias)
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

  outstanding do
    expect [:alias, :type, :target, :characteristics]
  end

  actions do
    create :create do
      description "creates a relationship between a source and target instance"
      accept [:source_id, :target_id, :type, :alias]

      argument :source_id, :uuid
      argument :target_id, :string
      argument :characteristics, {:array, :uuid}

      change manage_relationship(:source_id, :source, type: :append)
      change manage_relationship(:target_id, :target, type: :append)
      change manage_relationship(:characteristics, type: :append)
      change Diffo.Changes.DetailRelationship
      change load [:characteristics]
    end

    read :list do
      description "lists all relationships"
    end

    read :list_service_relationships_from do
      description "lists service relationships from the instance"
      argument :instance_id, :uuid
      filter expr(source_id == ^arg(:instance_id) and target.type == :service)
    end

    read :list_resource_relationships_from do
      description "lists resource relationships from the instance"
      argument :instance_id, :uuid
      filter expr(source_id == ^arg(:instance_id) and target.type == :resource)
    end

    update :update do
      description "updates the relationship type and/or alias"
      accept [:alias, :type]
    end

    update :relate_characteristics do
      description "relates characteristics to the relationship"
      argument :characteristics, {:array, :uuid}
      change manage_relationship(:characteristics, type: :append)
    end

    update :unrelate_characteristics do
      description "unrelates characteristic from the relationship"
      argument :characteristics, {:array, :uuid}
      change manage_relationship(:characteristics, type: :remove)
    end
  end

  attributes do
    attribute :alias, :atom do
      description "the alias of this relationship, used for supporting service or resource"
      allow_nil? true
      public? true
    end
  end

  relationships do
    has_many :characteristics, Diffo.Provider.Characteristic do
      description "the relationship's collection of defining characteristics"
      public? true
    end
  end

  identities do
    identity :unique_source_and_target, [:source_id, :target_id]
  end

  preparations do
    prepare build(
              load: [:characteristics],
              sort: [alias: :asc, type: :asc, created_at: :asc]
            )
  end

  @doc """
  Derives the instance relationship name from the instance type
  ## Examples
    iex> Diffo.Provider.Relationship.derive_relationship_name(:service)
    :serviceRelationship

    iex> Diffo.Provider.Relationship.derive_relationship_name(:resource)
    :resourceRelationship

  """
  def derive_relationship_name(instance_type) do
    case instance_type do
      :service -> :serviceRelationship
      :resource -> :resourceRelationship
      _ -> nil
    end
  end

  @doc """
  Derives the instance relationship characteristic list name from the instance type
  ## Examples
    iex> Diffo.Provider.Relationship.derive_relationship_characteristic_list_name(:service)
    :serviceRelationshipCharacteristic

    iex> Diffo.Provider.Relationship.derive_relationship_characteristic_list_name(:resource)
    :resourceRelationshipCharacteristic

  """
  def derive_relationship_characteristic_list_name(instance_type) do
    case instance_type do
      :service -> :serviceRelationshipCharacteristic
      :resource -> :resourceRelationshipCharacteristic
      _ -> nil
    end
  end
end
