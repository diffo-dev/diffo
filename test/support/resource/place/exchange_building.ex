# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Test.Place.ExchangeBuilding do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  ExchangeBuilding - an NBN exchange building with domain-specific attributes,
  demonstrating the complex BasePlace pattern.
  """

  alias Diffo.Provider.BasePlace
  alias Diffo.Test.Nbn

  use Ash.Resource,
    fragments: [BasePlace],
    domain: Nbn

  resource do
    description "An NBN Exchange Building"
    plural_name :exchange_buildings
  end

  actions do
    create :build do
      accept [:id, :href, :name, :nli, :access_type]
      change set_attribute(:type, :GeographicSite)
    end
  end

  jason do
    pick [:id, :href, :name, :type, :nli, :access_type]
    compact true
    rename type: "@type"
  end

  outstanding do
    expect [:id, :name, :type]
  end

  attributes do
    attribute :nli, :string do
      description "Network Location Identifier"
      allow_nil? true
      public? true
    end

    attribute :access_type, :atom do
      description "Access type for the exchange building"
      allow_nil? true
      public? true
      constraints one_of: [:attended, :unmanned, :restricted]
    end
  end

  provider do
    instances do
      role :host, Diffo.Provider.Instance
    end

    parties do
      role :operator, Diffo.Test.Party.Carrier
    end
  end
end
