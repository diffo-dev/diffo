# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Test.Organization do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  Organization - Organization Party
  """

  alias Diffo.Provider.BaseParty
  alias Diffo.Test.Nbn

  use Ash.Resource,
    fragments: [BaseParty],
    domain: Nbn

  resource do
    description "An Organization"
    plural_name :organizations
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
      change set_attribute(:type, :Organization)
    end
  end

  instances do
    role :facilitator, Diffo.Provider.Instance
  end

  parties do
    role :employer, Diffo.Test.Person
  end

  places do
    role :headquarters, Diffo.Provider.Place
  end
end
