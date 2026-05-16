# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Test.Characteristic.DeploymentClass do
  @moduledoc "Typed characteristic for a deployment class within a spectral management feature."
  use Ash.Resource,
    fragments: [Diffo.Provider.BaseCharacteristic],
    domain: Diffo.Test.Servo

  resource do
    description "Typed characteristic carrying deployment class fields"
    plural_name :deployment_class_values
  end

  attributes do
    attribute :class, :string, public?: true, description: "the deployment class"
    attribute :mask, :string, public?: true, description: "the mask name"
  end

  calculations do
    calculate :value, Diffo.Type.CharacteristicValue, Diffo.Provider.Calculations.CharacteristicValue do
      public? true
    end
  end

  actions do
    create :create do
      accept [:name, :class, :mask]
      argument :instance_id, :uuid
      argument :feature_id, :uuid
      change manage_relationship(:instance_id, :instance, type: :append)
      change manage_relationship(:feature_id, :feature, type: :append)
    end

    update :update do
      accept [:class, :mask]
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
