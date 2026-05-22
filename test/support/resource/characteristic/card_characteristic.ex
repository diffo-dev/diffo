# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Test.Characteristic.CardCharacteristic do
  @moduledoc "Typed characteristic for a Card's identity."
  use Ash.Resource,
    fragments: [Diffo.Provider.BaseCharacteristic],
    domain: Diffo.Test.Servo

  resource do
    description "Typed characteristic carrying card identity fields"
    plural_name :card_values
  end

  attributes do
    attribute :family, :atom, public?: true, description: "the card family name"
    attribute :model, :string, public?: true, description: "the card model name"
    attribute :technology, :atom, public?: true, description: "the card technology"
  end

  calculations do
    calculate :value,
              Diffo.Type.CharacteristicValue,
              Diffo.Provider.Calculations.CharacteristicValue do
      public? true
    end
  end

  preparations do
    prepare build(load: [:value])
  end

  jason do
    pick [:name, :value]
    compact true
  end
end
