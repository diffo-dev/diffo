# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.GeographicLocation do
  @moduledoc """
  Ash Resource for a TMF675 GeographicLocation.

  Out-of-the-box concrete leaf derived from `BasePlace` + `BaseGeographicLocation`.
  Sets `type: :GeographicLocation` on the `:build` action; requires `location` or
  `bounds` per `BaseGeographicLocation`'s validation.

  See `Diffo.Provider.BaseGeographicLocation` for attribute and validation
  details, and `Diffo.Provider.BasePlace` for the geometry attributes and
  TMF675 GeoJson wire encoding.

  ## Cross-world consumers

  Domain extenders compose the same two fragments on their own leaf.
  """
  alias Diffo.Provider.BasePlace
  alias Diffo.Provider.BaseGeographicLocation

  use Ash.Resource,
    fragments: [BasePlace, BaseGeographicLocation],
    domain: Diffo.Provider

  resource do
    description "An Ash Resource for a TMF675 GeographicLocation"
    plural_name :geographic_locations
  end

  actions do
    create :build do
      description "creates a typed geographic location"
      accept [:id, :href, :name, :location, :bounds, :accuracy]
      change set_attribute(:type, :GeographicLocation)
      upsert? true
    end

    update :define do
      description "defines fields on a geographic location (base + location-specific)"
      accept [:name, :href, :location, :bounds, :accuracy]
    end
  end
end
