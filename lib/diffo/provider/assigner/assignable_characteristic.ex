# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.AssignableCharacteristic do
  @moduledoc """
  Typed characteristic carrying pool bounds and assignment algorithm.

  Replaces the `AssignableValue` TypedStruct. Stored as a proper Neo4j node
  via `BaseCharacteristic`, with direct attributes rather than a wrapped
  `Diffo.Type.Value` dynamic. The `free` count is not stored here — it is
  derived from the count of `assignedTo` Relationship records (Phase 4).
  """
  use Ash.Resource,
    fragments: [Diffo.Provider.BaseCharacteristic],
    domain: Diffo.Provider

  resource do
    description "Typed characteristic carrying pool assignment bounds and algorithm"
    plural_name :assignable_characteristics
  end

  attributes do
    attribute :first, :integer do
      description "the first assignable value in the pool"
      public? true
      default 1
      constraints min: 0
    end

    attribute :last, :integer do
      description "the last assignable value in the pool"
      public? true
      default 1
      constraints min: 0
    end

    attribute :assignable_type, :string do
      description "the type label of the assignable thing (e.g. \"ADSL2+\")"
      public? true
      allow_nil? true
    end

    attribute :algorithm, :atom do
      description "the selection algorithm for auto-assign"
      public? true
      default :lowest
      constraints one_of: [:lowest, :highest, :random]
    end

    attribute :thing, :atom do
      description "the kind of item being assigned (e.g. :slot, :port); set from the pool declaration at build time"
      public? true
      allow_nil? true
    end
  end

  calculations do
    calculate :value, Diffo.Type.CharacteristicValue,
              Diffo.Provider.Calculations.CharacteristicValue do
      public? true
    end

    calculate :assigned_values, {:array, :integer},
              Diffo.Provider.Calculations.AssignedValues do
      public? true
      argument :thing, :atom, allow_nil?: false
    end

    calculate :free, :integer, Diffo.Provider.Calculations.FreeValues do
      public? true
    end
  end

  actions do
    create :create do
      accept [:name, :first, :last, :assignable_type, :algorithm, :thing]
      argument :instance_id, :uuid
      argument :feature_id, :uuid
      change manage_relationship(:instance_id, :instance, type: :append)
      change manage_relationship(:feature_id, :feature, type: :append)
    end

    update :update do
      accept [:first, :last, :assignable_type, :algorithm]
    end
  end

  preparations do
    prepare build(load: [:value, :free])
  end

  jason do
    pick [:name, :value]
    compact true
  end
end
