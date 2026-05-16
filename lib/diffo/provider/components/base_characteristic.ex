# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.BaseCharacteristic do
  @moduledoc """
  Ash Resource Fragment which is the point of extension for typed TMF Characteristics.

  `BaseCharacteristic` is the foundation for domain-specific Characteristic kinds.
  Include it as a fragment on an `Ash.Resource` to get a typed characteristic node
  in Neo4j with real Ash attributes — no `Ash.Type.Dynamic` required.

  `Diffo.Provider.Characteristic` remains available as the generic dynamic option
  (storing values via `Diffo.Type.Value`); it includes `Characteristic.Extension` so
  the DSL verifier accepts it alongside typed resources.

  ## Usage

      defmodule MyApp.CircuitCharacteristic do
        use Ash.Resource, fragments: [BaseCharacteristic], domain: MyApp.Domain

        attributes do
          attribute :bandwidth_mbps, :integer, public?: true
          attribute :technology, :atom, public?: true
        end

        actions do
          create :create do
            accept [:name, :bandwidth_mbps, :technology]
            argument :instance_id, :uuid
            argument :feature_id, :uuid
          end

          update :update do
            accept [:bandwidth_mbps, :technology]
          end
        end

        calculations do
          calculate :value, Diffo.Type.CharacteristicValue, Diffo.Provider.Calculations.CharacteristicValue do
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

  ## DSL declaration

      provider do
        characteristics do
          characteristic :circuit, MyApp.CircuitCharacteristic
        end
      end

  At build time a `CircuitCharacteristic` node is created and connected to the
  instance via an `:HAS` edge. The `name` attribute (e.g. `:circuit`) identifies
  the characteristic's role on the instance.

  ## Typed vs dynamic

  | Style | DSL target | Neo4j node | Value storage |
  |-------|-----------|------------|---------------|
  | Typed | `BaseCharacteristic`-derived | per-type label (e.g. `:CircuitCharacteristic`) | direct Ash attributes |
  | Dynamic | `Diffo.Provider.Characteristic` | `:Characteristic` | `Diffo.Type.Value` dynamic |
  """
  use Spark.Dsl.Fragment,
    of: Ash.Resource,
    otp_app: :diffo,
    domain: Diffo.Provider,
    data_layer: AshNeo4j.DataLayer,
    extensions: [
      AshJason.Resource,
      Diffo.Provider.Characteristic.Extension
    ]


  neo4j do
    relate [
      {:instance, :HAS, :incoming, :Instance},
      {:feature, :HAS, :incoming, :Feature}
    ]

    guard [
      {:HAS, :incoming, :Instance},
      {:HAS, :incoming, :Feature}
    ]
  end

  attributes do
    uuid_primary_key :id do
      public? false
    end

    attribute :name, :atom do
      description "the role name of this characteristic on the owning instance or feature"
      allow_nil? false
      public? true
    end

    create_timestamp :created_at
    update_timestamp :updated_at
  end

  relationships do
    belongs_to :instance, Diffo.Provider.Instance do
      allow_nil? true
      public? true
    end

    belongs_to :feature, Diffo.Provider.Feature do
      allow_nil? true
      public? true
    end
  end

  validations do
    validate present([:instance_id, :feature_id], at_most: 1) do
      message "characteristic must belong to at most one of an instance or feature"
    end
  end

  actions do
    defaults [:read, :destroy]
  end
end
