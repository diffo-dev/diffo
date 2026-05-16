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
    validate_config_inclusion?: false

  alias Diffo.Test.Party.Organization
  alias Diffo.Test.Party.Person
  alias Diffo.Test.Party.Carrier
  alias Diffo.Test.Place.GeographicSite
  alias Diffo.Test.Place.ExchangeBuilding

  domain do
    description "NBN party and place domain"
  end

  resources do
    resource Organization do
      define :create_organization, action: :build
      define :get_organization_by_id, action: :read, get_by: :id
      define :list_organizations, action: :list
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
  end
end
