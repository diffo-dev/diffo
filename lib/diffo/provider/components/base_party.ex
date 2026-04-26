# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.BaseParty do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  BaseParty - Ash Resource Fragment of a TMF Party

  `BaseParty` is the foundation for domain-specific Party kinds such as RSP or Person.
  It provides common Party attributes and the `Diffo.Provider.Party.Extension` DSL, which
  allows a Party kind to declare the roles it plays with respect to Instances and other Parties.

  ## Usage

      defmodule MyApp.Organisation do
        use Ash.Resource, fragments: [BaseParty], domain: MyApp.Domain

        resource do
          description "An Organisation"
          plural_name :organisations
        end

        instance do
          role :facilitates, MyApp.AccessService
        end
      end

  ## Action pattern

  Domain-specific Party resources should finish their `create` action with a reload via
  their own domain's `get_xxx_by_id` to pick up extended fields:

      create :create do
        accept [:name]
        change after_action(fn _changeset, result, _context ->
          MyApp.Domain.get_organisation_by_id(result.id)
        end)
      end
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
      {:party_refs, :RELATES, :incoming, :PartyRef}
    ]

    label :Party
  end

  jason do
    pick [:id, :name, :kind]
    compact true
  end

  outstanding do
    expect [:id, :name, :kind]
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

    attribute :name, :string do
      description "the name of this party"
      allow_nil? true
      public? true
    end

    attribute :kind, :atom do
      description "the kind of this party, either individual or organization"
      allow_nil? false
      public? true
      constraints one_of: [:individual, :organization]
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
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      description "creates a party of this kind"
      accept [:id, :name, :kind]
      upsert? true
    end

    update :update do
      description "updates the party name"
      accept [:name]
    end

    read :list do
      description "lists all parties of this kind"
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
end
