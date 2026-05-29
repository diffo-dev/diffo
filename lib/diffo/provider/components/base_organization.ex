# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.BaseOrganization do
  @moduledoc """
  Ash Resource Fragment for TMF632 Organization — a Party representing a group
  of people identified by shared interests or purpose (business, department,
  enterprise).

  Compose with `BaseParty` on a concrete leaf to get the TMF632 Organization
  attribute set, TMF camelCase jason wire shape, and organization-shaped
  outstanding signature.

  `Diffo.Provider.Organization` uses this fragment directly as the
  out-of-the-box TMF Organization resource. Domain extenders compose the same
  two fragments on their own leaf for richer domain identity:

      defmodule MyApp.Carrier do
        use Ash.Resource,
          fragments: [Diffo.Provider.BaseParty, Diffo.Provider.BaseOrganization],
          domain: MyApp.Domain

        attributes do
          attribute :carrier_code, :string, public?: true
        end

        actions do
          create :build do
            accept [:id, :href, :name, :trading_name, :organization_type, :carrier_code]
            change set_attribute(:type, :Organization)
          end
        end
      end

  ## Attributes

  All organization attributes are permissive (`allow_nil? true`) — tighten on
  your derived leaf if your domain requires e.g. an organization_type.

  - `trading_name` — name the organization trades under.
  - `name_type` — type of the name (Co, Inc, Ltd, etc.).
  - `organization_type` — type of organization (company, department, …).
  - `is_legal_entity` — boolean; true when the organization is a legal entity
    known by a national referential.
  - `is_head_office` — boolean; true when this is the head office.

  Deferred from this fragment (TMF632 v5 fields landing in follow-up tickets):

  - `existsDuring` (TimePeriod), `status` (OrganizationStateType — pairs with
    Specification state-machine work)
  - `otherName[]`, `organizationIdentification[]` (nested resources)
  - `organizationChildRelationship[]` / `organizationParentRelationship` (modeled
    via the existing PartyRef machinery)

  ## Wire shape (TMF632)

  `jason.pick` selects base + organization fields and renames to TMF camelCase
  (`tradingName`, `nameType`, `organizationType`, `isLegalEntity`,
  `isHeadOffice`).
  """
  use Spark.Dsl.Fragment,
    of: Ash.Resource,
    extensions: [AshOutstanding.Resource, AshJason.Resource]

  attributes do
    attribute :trading_name, :string do
      description "the name the organization trades under"
      allow_nil? true
      public? true
    end

    attribute :name_type, :string do
      description "the type of the name (Co, Inc, Ltd, etc.)"
      allow_nil? true
      public? true
    end

    attribute :organization_type, :string do
      description "the type of organization (company, department, ...)"
      allow_nil? true
      public? true
    end

    attribute :is_legal_entity, :boolean do
      description "true when the organization is a legal entity known by a national referential"
      allow_nil? true
      public? true
    end

    attribute :is_head_office, :boolean do
      description "true when this is the head office"
      allow_nil? true
      public? true
    end
  end

  jason do
    pick [
      :id,
      :href,
      :name,
      :type,
      :trading_name,
      :name_type,
      :organization_type,
      :is_legal_entity,
      :is_head_office
    ]

    compact true

    rename type: "@type",
           trading_name: "tradingName",
           name_type: "nameType",
           organization_type: "organizationType",
           is_legal_entity: "isLegalEntity",
           is_head_office: "isHeadOffice"
  end

  outstanding do
    expect [:id, :name, :type]
  end
end
