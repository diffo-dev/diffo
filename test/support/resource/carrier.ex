# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Test.Carrier do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  Carrier - a telecommunications carrier with domain-specific attributes,
  demonstrating the complex BaseParty pattern.
  """

  alias Diffo.Provider.BaseParty
  alias Diffo.Test.Nbn

  use Ash.Resource,
    fragments: [BaseParty],
    domain: Nbn

  resource do
    description "A Telecommunications Carrier"
    plural_name :carriers
  end

  actions do
    create :build do
      accept [:id, :href, :name, :abn, :trading_name]
      change set_attribute(:type, :Organization)
    end
  end

  jason do
    pick [:id, :name, :type, :abn, :trading_name]
    compact true
  end

  outstanding do
    expect [:id, :name, :type]
  end

  attributes do
    attribute :abn, :string do
      description "Australian Business Number"
      allow_nil? true
      public? true
    end

    attribute :trading_name, :string do
      description "Trading name, distinct from legal name"
      allow_nil? true
      public? true
    end
  end

  instances do
    role :provider, Diffo.Provider.Instance
  end

  places do
    role :exchange, Diffo.Provider.Place
  end
end
