# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Test.GeographicSite do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  GeographicSite - test fixture for Place Extension DSL
  """

  alias Diffo.Provider.BasePlace
  alias Diffo.Test.Nbn

  use Ash.Resource,
    fragments: [BasePlace],
    domain: Nbn

  resource do
    description "A Geographic Site"
    plural_name :geographic_sites
  end

  jason do
    pick [:id, :href, :name, :type]
    compact true
    rename type: "@type"
  end

  outstanding do
    expect [:id, :name, :type]
  end

  actions do
    create :build do
      accept [:id, :href, :name]
      change set_attribute(:type, :GeographicSite)
    end
  end

  provider do
    instances do
      role :installed_at, Diffo.Provider.Instance
    end

    parties do
      role :managed_by, Diffo.Test.Organization
    end

    places do
      role :contained_in, Diffo.Provider.Place
    end
  end
end
