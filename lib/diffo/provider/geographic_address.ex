# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.GeographicAddress do
  @moduledoc """
  Ash Resource for a TMF674 GeographicAddress.

  Out-of-the-box concrete leaf derived from `BasePlace` + `BaseGeographicAddress`.
  Sets `type: :GeographicAddress` on the `:create` action; accepts the union of
  base Place + address-specific fields.

  See `Diffo.Provider.BaseGeographicAddress` for the attribute set and TMF wire
  shape. See `Diffo.Provider.BasePlace` for the base attributes, validations,
  and Neo4j wiring inherited via fragment composition.

  ## Cross-world consumers

  Domain extenders compose the same two fragments on their own leaf rather than
  extending this one — Ash resources are leaves, not hierarchies. See the
  `BaseGeographicAddress` docstring for an example.
  """
  alias Diffo.Provider.BasePlace
  alias Diffo.Provider.BaseGeographicAddress

  use Ash.Resource,
    fragments: [BasePlace, BaseGeographicAddress],
    domain: Diffo.Provider

  resource do
    description "An Ash Resource for a TMF674 GeographicAddress"
    plural_name :geographic_addresses
  end

  actions do
    create :build do
      description "creates a typed geographic address"

      accept [
        :id,
        :href,
        :name,
        :street_name,
        :street_nr,
        :locality,
        :state_or_province,
        :country,
        :postcode
      ]

      change set_attribute(:type, :GeographicAddress)
      upsert? true
    end

    update :define do
      description "defines fields on a geographic address (base + address-specific)"

      accept [
        :name,
        :href,
        :street_name,
        :street_nr,
        :locality,
        :state_or_province,
        :country,
        :postcode
      ]
    end
  end
end
