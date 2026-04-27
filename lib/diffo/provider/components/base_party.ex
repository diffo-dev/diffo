# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.BaseParty do
  @moduledoc """
  Ash Resource Fragment which is a the point of extension for your TMF Party

  `BaseParty` is the foundation for domain-specific Party kinds such as Organization or Person.
  Include it as a fragment on an `Ash.Resource` to get common Party attributes, Neo4j graph
  wiring, and the `Diffo.Provider.Party.Extension` DSL.

  `Diffo.Provider.Party` uses `BaseParty` directly as the out-of-the-box TMF Party resource.
  Domain-specific resources extend it for richer domain identity.

  ## Attributes

  - `id` — string primary key, defaults to a generated uuid4. Can be set by the domain to any
    meaningful string (e.g. an ABN or a data centre identifier).
  - `href` — optional URI for the party.
  - `name` — the party name.
  - `type` — TMF `@type`. Defaults to `:PartyRef`. One of `:PartyRef`, `:Individual`,
    `:Organization`, `:Entity`. When `referred_type` is present, `type` must be `:PartyRef`.
  - `referred_type` — TMF `@referredType`. One of `:Individual`, `:Organization`, `:Entity`.
    When present, indicates this is a reference to a party of that kind; `type` must be `:PartyRef`.

  ## Party Extension DSL

  The `Diffo.Provider.Party.Extension` DSL provides two compile-time declaration blocks.
  Role names are domain-specific nouns from the party's perspective — timeless, camelCase
  when multi-word.

  `instances do` — declares the roles this Party kind plays with respect to Instances:

      instances do
        role :operator, MyApp.Cluster
        role :dataCentre, MyApp.Facility
      end

  `parties do` — declares the roles this Party kind plays with respect to other Parties:

      parties do
        role :employer, MyApp.Organization
      end

  Both blocks are introspectable via `Diffo.Provider.Party.Extension.Info`.

  ## Usage

      defmodule MyApp.RSP do
        use Ash.Resource, fragments: [BaseParty], domain: MyApp.Domain

        resource do
          description "A Retail Service Provider"
          plural_name :rsps
        end

        jason do
          pick [:id, :name, :type]
          compact true
        end

        outstanding do
          expect [:id, :name, :type]
        end

        actions do
          create :build do
            accept [:id, :href, :name]
            change set_attribute(:referred_type, :Organization)
          end
        end

        instances do
          role :provider, MyApp.AccessService
        end
      end

  ## TMF type and referred_type

  The `type` and `referred_type` attributes map to the TMF `@type` and `@referredType` JSON
  fields via the jason layer. Use the `build` action to declare the TMF identity of your
  domain party — this is also the contract for how the party appears in TMF serialisation
  of `relatedParty` on instances.

  - `type: :Organization` — this party IS an Organization (direct).
  - `referred_type: :Organization` — this is a PartyRef pointing to an Organization.
  """
  use Spark.Dsl.Fragment,
    of: Ash.Resource,
    otp_app: :diffo,
    domain: Diffo.Provider,
    data_layer: AshNeo4j.DataLayer,
    extensions: [
      AshOutstanding.Resource,
      AshJason.Resource,
      Diffo.Provider.Party.Extension
    ]

  neo4j do
    relate [
      {:party_refs, :RELATES, :incoming, :PartyRef},
      {:external_identifiers, :OWNS, :outgoing, :ExternalIdentifier},
      {:notes, :AUTHORS, :outgoing, :Note}
    ]

    guard [
      {:OWNS, :outgoing, :ExternalIdentifier}
    ]

    label :Party
  end

  attributes do
    attribute :id, :string do
      description "the id of this party, domain-assigned or a generated uuid4 by default"
      primary_key? true
      allow_nil? false
      public? true
      default &Diffo.Uuid.uuid4/0
      source :key
    end

    attribute :href, :string do
      description "the href of this party"
      allow_nil? true
      public? true
    end

    attribute :name, :string do
      description "the name of this party"
      allow_nil? true
      public? true
    end

    attribute :type, :atom do
      description "the type of the party"
      allow_nil? false
      public? true
      default :PartyRef
      constraints one_of: [:PartyRef, :Individual, :Organization, :Entity]
    end

    attribute :referred_type, :atom do
      description "the type of the party"
      allow_nil? true
      public? true
      constraints one_of: [:Individual, :Organization, :Entity]
    end

    create_timestamp :created_at

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
      description "creates a party of this kind"
      accept [:id, :href, :name, :type, :referred_type]
      upsert? true
    end

    update :update do
      description "updates the party name"
      accept [:href, :name, :type, :referred_type]
    end

    read :list do
      description "lists all parties of this kind"
    end

    read :find_by_id do
      description "finds parties by id"
      get? false

      argument :query, :ci_string do
        description "Return only parties with id's including the given value."
      end

      filter expr(contains(id, ^arg(:query)))
    end

    read :find_by_name do
      description "finds parties by name"
      get? false

      argument :query, :ci_string do
        description "Return only parties with names including the given value."
      end

      filter expr(contains(name, ^arg(:query)))
    end
  end

  validations do
    validate {Diffo.Validations.HrefEndsWithId, id: :id, href: :href} do
      where [present(:id), present(:href)]
    end

    validate attribute_equals(:type, :PartyRef) do
      where present(:referred_type)
      message "when referred_type is present, type must be PartyRef"
    end

    validate attribute_does_not_equal(:type, :PartyRef) do
      where absent(:referred_type)
      message "when referred_type is absent, type must be not be PartyRef"
    end
  end

  preparations do
    prepare build(sort: [id: :asc, name: :asc])
  end
end
