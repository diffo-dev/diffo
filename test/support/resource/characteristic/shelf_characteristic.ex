# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Test.Characteristic.ShelfCharacteristic do
  @moduledoc "Typed characteristic for a Shelf's identity."
  use Ash.Resource,
    fragments: [Diffo.Provider.BaseCharacteristic],
    domain: Diffo.Test.Servo

  resource do
    description "Typed characteristic carrying shelf identity fields"
    plural_name :shelf_values
  end

  attributes do
    attribute :family, :atom, public?: true, description: "the shelf family name"
    attribute :model, :string, public?: true, description: "the shelf model name"
    attribute :technology, :atom, public?: true, description: "the shelf technology"
  end

  calculations do
    calculate :value, Diffo.Type.CharacteristicValue, Diffo.Provider.Calculations.CharacteristicValue do
      public? true
    end
  end

  actions do
    create :create do
      accept [:name, :family, :model, :technology]
      argument :instance_id, :uuid
      argument :feature_id, :uuid
      change manage_relationship(:instance_id, :instance, type: :append)
      change manage_relationship(:feature_id, :feature, type: :append)
    end

    update :update do
      accept [:family, :model, :technology]
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
