# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Test.Instance.CardInstance do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  Card - Card Resource Instance
  """
  alias Diffo.Provider.BaseInstance
  alias Diffo.Provider.Assignment
  alias Diffo.Provider.Changes
  alias Diffo.Test.Servo
  alias Diffo.Test.Characteristic.CardCharacteristic

  use Ash.Resource,
    fragments: [BaseInstance],
    domain: Servo

  resource do
    description "An Ash Resource representing a Card"
    plural_name :Cards
  end

  provider do
    specification do
      id "cd29956f-6c68-44cc-bf54-705eb8d2f754"
      name "card"
      type :resourceSpecification
      description "A Card Resource Instance"
      category "Network Resource"
    end

    characteristics do
      characteristic :card, CardCharacteristic
    end

    pools do
      pool :ports, :port
    end

    relationships do
      target :all
    end

    behaviour do
      actions do
        create :build
      end
    end
  end

  actions do
    create :build do
      description "creates a new Card resource instance for build"
      accept [:id, :name, :type, :which]
      argument :relationships, {:array, :struct}
      argument :places, {:array, :struct}
      argument :parties, {:array, :struct}

      change set_attribute(:type, :resource)
      change load [:href]
      upsert? false
    end

    update :define do
      description "defines the card"
      argument :characteristic_value_updates, {:array, :term}
      change Changes.Define
    end

    update :relate do
      description "relates the card with other instances"
      argument :relationships, {:array, :struct}
      change Changes.Relate
    end

    update :assign_port do
      description "relates the card with an instance by assigning a port"
      argument :assignment, :struct, constraints: [instance_of: Assignment]
      change {Changes.Assign, pool: :ports}
    end
  end
end
