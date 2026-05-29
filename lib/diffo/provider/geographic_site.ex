# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.GeographicSite do
  @moduledoc """
  Ash Resource for a TMF675 GeographicSite.

  Out-of-the-box concrete leaf derived from `BasePlace` + `BaseGeographicSite`.
  Sets `type: :GeographicSite` on the `:build` action; accepts the union of
  base Place + site-specific fields.

  See `Diffo.Provider.BaseGeographicSite` for the attribute set, the projected
  `:address` calc, and TMF wire shape. See `Diffo.Provider.BasePlace` for the
  base attributes inherited via fragment composition.

  ## Cross-world consumers

  Domain extenders compose the same two fragments on their own leaf rather than
  extending this one. See the `BaseGeographicSite` docstring for an example.
  """
  alias Diffo.Provider.BasePlace
  alias Diffo.Provider.BaseGeographicSite

  use Ash.Resource,
    fragments: [BasePlace, BaseGeographicSite],
    domain: Diffo.Provider

  resource do
    description "An Ash Resource for a TMF675 GeographicSite"
    plural_name :geographic_sites
  end

  actions do
    create :build do
      description "creates a typed geographic site"
      accept [:id, :href, :name, :site_type, :site_code, :address_id]
      change set_attribute(:type, :GeographicSite)
      upsert? true
    end

    update :define do
      description "defines fields on a geographic site (base + site-specific)"
      accept [:name, :href, :site_type, :site_code, :address_id]
    end
  end
end
