# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Test.InvalidCharacteristic do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  InvalidCharacteristic - Resource Instance with an Invalid Characteristic
  """

  alias Diffo.Provider.BaseInstance

  use Ash.Resource,
    fragments: [BaseInstance],
    domain: Diffo.Test.Servo

  resource do
    description "Ash Resource with an invalid characteristic"
  end

  structure do
    specification do
      id "3caf29b9-0b91-4b8f-8568-2960131b1feb"
      name "invalidCharacteristic"
      type :resourceSpecification
      category "Network Resource"
    end

    characteristics do
      characteristic :invalid, InvalidValue
    end
  end

  actions do
    create :build do
      description "creates a new InvalidCharacteristic resource instance for build"
      accept [:id, :name, :type, :which]
      change set_attribute(:type, :resource)
      change load [:href]
      upsert? false
    end
  end
end
