# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Organization do
  @moduledoc """
  Ash Resource for a TMF632 Organization.

  Out-of-the-box concrete leaf derived from `BaseParty` + `BaseOrganization`.
  Sets `type: :Organization` on the `:build` action; accepts the union of base
  Party + organization-specific fields.

  See `Diffo.Provider.BaseOrganization` for the attribute set and TMF wire
  shape. See `Diffo.Provider.BaseParty` for the base attributes, validations,
  and Neo4j wiring inherited via fragment composition.

  ## Cross-world consumers

  Domain extenders compose the same two fragments on their own leaf rather than
  extending this one — Ash resources are leaves, not hierarchies. See the
  `BaseOrganization` docstring for an example.
  """
  alias Diffo.Provider.BaseParty
  alias Diffo.Provider.BaseOrganization

  use Ash.Resource,
    fragments: [BaseParty, BaseOrganization],
    domain: Diffo.Provider

  resource do
    description "An Ash Resource for a TMF632 Organization"
    plural_name :organizations
  end

  actions do
    create :build do
      description "creates a typed organization"

      accept [
        :id,
        :href,
        :name,
        :trading_name,
        :name_type,
        :organization_type,
        :is_legal_entity,
        :is_head_office
      ]

      change set_attribute(:type, :Organization)
      upsert? true
    end

    update :define do
      description "defines fields on an organization (base + organization-specific)"

      accept [
        :name,
        :href,
        :trading_name,
        :name_type,
        :organization_type,
        :is_legal_entity,
        :is_head_office
      ]
    end
  end
end
