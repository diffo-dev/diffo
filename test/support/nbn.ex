# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Test.Nbn do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  Nbn - a lightweight example domain for testing BaseParty and Party DSL
  """
  use Ash.Domain,
    otp_app: :diffo,
    validate_config_inclusion?: false,
    fragments: [Diffo.Provider.DomainFragment]

  alias Diffo.Test.Party.Enterprise
  alias Diffo.Test.Party.Person
  alias Diffo.Test.Party.Carrier
  alias Diffo.Test.Place.GeographicSite
  alias Diffo.Test.Place.ExchangeBuilding
  alias Diffo.Test.Place.CellSite

  domain do
    description "NBN party and place domain"
  end

  resources do
    resource Enterprise do
      define :create_enterprise, action: :build
      define :get_enterprise_by_id, action: :read, get_by: :id
      define :list_enterprises, action: :list
    end

    resource Person do
      define :create_person, action: :build
      define :get_person_by_id, action: :read, get_by: :id
      define :list_persons, action: :list
    end

    resource Carrier do
      define :create_carrier, action: :build
      define :get_carrier_by_id, action: :read, get_by: :id
    end

    resource GeographicSite do
      define :create_geographic_site, action: :build
      define :get_geographic_site_by_id, action: :read, get_by: :id
    end

    resource ExchangeBuilding do
      define :create_exchange_building, action: :build
      define :get_exchange_building_by_id, action: :read, get_by: :id
    end

    resource CellSite do
      define :build_cell_site, action: :build
      define :get_cell_site_by_id, action: :read, get_by: :id
    end
  end
end
