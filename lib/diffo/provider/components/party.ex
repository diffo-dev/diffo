defmodule Diffo.Provider.Party do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  Party - Ash Resource for a TMF Party
  """
  use Ash.Resource,
    otp_app: :diffo,
    domain: Diffo.Provider,
    data_layer: AshNeo4j.DataLayer,
    extensions: [AshOutstanding.Resource, AshJason.Resource]

  resource do
    description "An Ash Resource for a TMF Party"
    plural_name :parties
  end

  neo4j do
    translate id: :key
    relate([
      {:party_refs, :INVOLVES, :incoming, :PartyRef},
      {:external_identifiers, :OWNS, :outgoing, :ExternalIdentifier},
      {:notes, :AUTHORS, :outgoing, :Note}
    ])

    guard([
      {:OWNS, :outgoing, :ExternalIdentifier}
    ])
  end

  jason do
    pick([:id, :href, :name, :referredType, :type])
    rename(referredType: "@referredType", type: "@type")
  end

  outstanding do
    expect([:id, :name, :referredType, :type])
  end

  attributes do
    attribute :id, :string do
      description "the unique id of the party"
      primary_key? true
      allow_nil? false
      public? true
    end

    attribute :href, :string do
      description "the href of the party"
      allow_nil? true
      public? true
    end

    attribute :name, :string do
      description "the name of the party"
      allow_nil? true
      public? true
      constraints match: ~r/^[a-zA-Z0-9\s._-]+$/
    end

    attribute :type, :atom do
      description "the type of the party"
      allow_nil? false
      public? true
      default :PartyRef
      constraints one_of: [:PartyRef, :Individual, :Organization, :Entity]
    end

    attribute :referredType, :atom do
      description "the type of the party"
      allow_nil? true
      public? true
      constraints one_of: [:Individual, :Organization, :Entity]
    end

    create_timestamp :inserted_at

    update_timestamp :updated_at
  end

  relationships do
    has_many :party_refs, Diffo.Provider.PartyRef do
      description "the party refs relating this party to instances"
      destination_attribute :party_id
      public? true
    end

    has_many :external_identifiers, Diffo.Provider.ExternalIdentifier do
      description "the external identifiers owned by this party"
      destination_attribute :owner_id
      public? true
    end

    has_many :notes, Diffo.Provider.Note do
      description "the notes authored by this party"
      destination_attribute :note_id
      public? true
    end
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      description "creates a party"
      accept [:id, :href, :name, :type, :referredType]
      upsert? true
    end

    read :find_by_id do
      description "finds party by id"
      get? false

      argument :query, :ci_string do
        description "Return only parties with id's including the given value."
      end

      filter expr(contains(id, ^arg(:query)))
    end

    read :find_by_name do
      description "finds party by name"
      get? false

      argument :query, :ci_string do
        description "Return only parties with names including the given value."
      end

      filter expr(contains(name, ^arg(:query)))
    end

    read :list do
      description "lists all parties"
    end

    update :update do
      description "updates the party"
      accept [:href, :name, :type, :referredType]
    end
  end

  preparations do
    prepare build(sort: [id: :asc, name: :asc])
  end

  validations do
    validate {Diffo.Validations.HrefEndsWithId, id: :id, href: :href} do
      where [present(:id), present(:href)]
    end

    validate attribute_equals(:type, :PartyRef) do
      where present(:referredType)
      message "when referredType is present, type must be PartyRef"
    end

    validate attribute_does_not_equal(:type, :PartyRef) do
      where absent(:referredType)
      message "when referredType is absent, type must be not be PartyRef"
    end
  end

  @doc """
  Compares two party, by ascending id
  ## Examples
    iex> Diffo.Provider.Party.compare(%{id: "a"}, %{id: "a"})
    :eq
    iex> Diffo.Provider.Party.compare(%{id: "b"}, %{id: "a"})
    :gt
    iex> Diffo.Provider.Party.compare(%{id: "a"}, %{id: "b"})
    :lt

  """
  def compare(%{id: id0}, %{id: id1}), do: Diffo.Util.compare(id0, id1)
end
