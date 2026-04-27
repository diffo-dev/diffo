# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Test.InvalidFeatureCharacteristic do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  InvalidFeatureCharacteristic - Resource Instance with an Invalid Feature Characteristic
  """

  alias Diffo.Provider.BaseInstance
  alias Diffo.Provider.Instance.ActionHelper

  use Ash.Resource,
    fragments: [BaseInstance],
    domain: Diffo.Test.Servo

  resource do
    description "Ash Resource with an invalid feature characteristic"
  end

  specification do
    id "1f2402ca-82da-428e-a58b-5405a5431386"
    name "invalidFeatureCharacteristic"
    type :resourceSpecification
    category "Network Resource"
  end

  features do
    feature :invalid_feature_characteristic do
      is_enabled? true
      characteristic :invalid, InvalidValue
    end
  end

  actions do
    create :build do
      description "creates a new InvalidFeatureCharacteristic resource instance for build"
      accept [:id, :name, :type, :which]
      argument :specified_by, :uuid, public?: false
      argument :relationships, {:array, :struct}
      argument :features, {:array, :uuid}, public?: false
      argument :characteristics, {:array, :uuid}, public?: false
      argument :places, {:array, :struct}
      argument :parties, {:array, :struct}

      change set_attribute(:type, :resource)

      change before_action(fn changeset, _context ->
               ActionHelper.build_before(changeset)
             end)

      change after_action(fn changeset, result, _context ->
               ActionHelper.build_after(changeset, result)
             end)

      change load [:href]
      upsert? false
    end
  end
end
