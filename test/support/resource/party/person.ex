# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Test.Party.Person do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  Person - Person Party
  """

  alias Diffo.Provider.BaseParty
  alias Diffo.Test.Nbn

  use Ash.Resource,
    fragments: [BaseParty],
    domain: Nbn

  resource do
    description "A Person"
    plural_name :persons
  end

  jason do
    pick [:id, :name, :type]
    compact true
  end

  outstanding do
    expect [:id, :name, :type]
  end

  actions do
    create :build do
      accept [:id, :href, :name]
      change set_attribute(:type, :Individual)
    end
  end

  provider do
    instances do
      role :overseer, Diffo.Provider.Instance
    end

    parties do
      role :manager, Diffo.Test.Party.Person
    end

    places do
      role :residence, Diffo.Provider.Place
    end
  end
end
