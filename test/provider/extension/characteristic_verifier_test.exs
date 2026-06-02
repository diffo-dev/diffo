# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Extension.CharacteristicVerifierTest do
  @moduledoc false
  use ExUnit.Case, async: true, async: false
  @moduletag :domain_extended
  import ExUnit.CaptureIO
  alias Diffo.Test.Util

  describe "characteristics verifier" do
    # Regression for #201 — VerifyCharacteristics iterated every entity in the
    # :characteristics section and read &1.name / &1.value_type. An
    # inherited_characteristic declaration carries no :value_type, so the verifier
    # raised `KeyError key :value_type` on the declaration rather than compiling.
    # The filter now skips those declarations.
    test "inherited_characteristic declarations do not crash the verifier (#201)" do
      output =
        capture_io(:stderr, fn ->
          defmodule InheritedCharacteristicsCompile do
            alias Diffo.Provider.BaseInstance
            alias Diffo.Test.Characteristic.ShelfCharacteristic
            use Ash.Resource, fragments: [BaseInstance], domain: Diffo.Test.Servo

            resource do
              description "resource declaring inherited characteristics"
            end

            provider do
              specification do
                id "b1f0c2a3-4d5e-4f6a-8b9c-0d1e2f3a4b5c"
                name "inheritedCharacteristics"
                type :resourceSpecification
              end

              characteristics do
                characteristic :shelf, ShelfCharacteristic
                inherited_characteristic :uni, via: [:port]
                inherited_characteristic :unis, via: [{:forward, assignment: :port}], read: :uni
              end
            end
          end
        end)

      # The #201 signature — the verifier KeyError'ing on a declaration's missing
      # key. The verifier still runs (the DslError tests below prove that); it just
      # no longer chokes on the inherited_characteristic declarations.
      refute output =~ "key :name not found"
      refute output =~ "key :value_type not found"
    end

    # The filter that skips the inherited declarations must not disable the real
    # name-uniqueness check for plain `characteristic` entities — even when an
    # inherited declaration sits alongside them in the same section.
    test "duplicate characteristic name warns DslError on compilation" do
      Util.assert_compile_time_warning(
        Spark.Error.DslError,
        "characteristics: name :shelf is declared more than once",
        fn ->
          defmodule DuplicateCharacteristicName do
            alias Diffo.Provider.BaseInstance
            alias Diffo.Test.Characteristic.ShelfCharacteristic
            use Ash.Resource, fragments: [BaseInstance], domain: Diffo.Test.Servo

            resource do
              description "resource with duplicate characteristic name"
            end

            provider do
              specification do
                id "c2a1b0f3-5e4d-4a6b-9c8d-1e0f2a3b4c5d"
                name "duplicateCharacteristic"
                type :resourceSpecification
              end

              characteristics do
                characteristic :shelf, ShelfCharacteristic
                characteristic :shelf, ShelfCharacteristic
                inherited_characteristic :uni, via: [:port]
              end
            end
          end
        end
      )
    end

    # The value_type existence check must still fire on plain entities.
    test "non-existent value_type warns DslError on compilation" do
      Util.assert_compile_time_warning(
        Spark.Error.DslError,
        "characteristics: value_type NonExistent.CharacteristicModule does not exist",
        fn ->
          defmodule InvalidCharacteristicValueType do
            alias Diffo.Provider.BaseInstance
            use Ash.Resource, fragments: [BaseInstance], domain: Diffo.Test.Servo

            resource do
              description "resource with non-existent characteristic value_type"
            end

            provider do
              specification do
                id "d3b2c1a0-6f5e-4b7c-8d9e-2f1a0b3c4d5e"
                name "invalidValueType"
                type :resourceSpecification
              end

              characteristics do
                characteristic :bad, NonExistent.CharacteristicModule
                inherited_characteristic :uni, via: [:port]
              end
            end
          end
        end
      )
    end

    # The BaseCharacteristic-extension check must still fire on plain entities — a
    # module that exists but isn't a characteristic (here a Party) is rejected.
    test "value_type not extending BaseCharacteristic warns DslError on compilation" do
      Util.assert_compile_time_warning(
        Spark.Error.DslError,
        "characteristics: value_type Diffo.Test.Party.Enterprise does not extend BaseCharacteristic",
        fn ->
          defmodule WrongCharacteristicValueType do
            alias Diffo.Provider.BaseInstance
            use Ash.Resource, fragments: [BaseInstance], domain: Diffo.Test.Servo

            resource do
              description "resource with a party as characteristic value_type"
            end

            provider do
              specification do
                id "e4c3d2b1-7a6f-4c8d-9e0f-3a2b1c0d4e5f"
                name "wrongValueType"
                type :resourceSpecification
              end

              characteristics do
                characteristic :bad, Diffo.Test.Party.Enterprise
                inherited_characteristic :uni, via: [:port]
              end
            end
          end
        end
      )
    end
  end
end
