# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Extension.InstanceVerifierTest do
  @moduledoc false
  use ExUnit.Case, async: true, async: false
  alias Diffo.Test.Util

  describe "specification verifier" do
    test "invalid UUID4 in specification id warns DslError on compilation" do
      Util.assert_compile_time_warning(
        Spark.Error.DslError,
        "specification: id must be a valid UUID4",
        fn ->
          defmodule InvalidSpecId do
            alias Diffo.Provider.BaseInstance
            use Ash.Resource, fragments: [BaseInstance], domain: Diffo.Test.Servo

            resource do
              description "resource with invalid spec id"
            end

            provider do
              specification do
                id "ef016d85-9dbd-429c-04da-1df56cc7dda5"
                name "invalid"
              end
            end
          end
        end
      )
    end

    test "name not matching camelCase pattern warns DslError on compilation" do
      Util.assert_compile_time_warning(
        Spark.Error.DslError,
        "specification: name",
        fn ->
          defmodule InvalidSpecName do
            alias Diffo.Provider.BaseInstance
            use Ash.Resource, fragments: [BaseInstance], domain: Diffo.Test.Servo

            resource do
              description "resource with non-camelCase specification name"
            end

            provider do
              specification do
                id "cd29956f-6c68-44cc-bf54-705eb8d2f754"
                name "not camel case"
              end
            end
          end
        end
      )
    end

    test "type not in allowed set warns DslError on compilation" do
      Util.assert_compile_time_warning(
        Spark.Error.DslError,
        "specification: type",
        fn ->
          defmodule InvalidSpecType do
            alias Diffo.Provider.BaseInstance
            use Ash.Resource, fragments: [BaseInstance], domain: Diffo.Test.Servo

            resource do
              description "resource with invalid specification type"
            end

            provider do
              specification do
                id "cd29956f-6c68-44cc-bf54-705eb8d2f754"
                name "invalid"
                type :badType
              end
            end
          end
        end
      )
    end

    test "negative major_version warns DslError on compilation" do
      Util.assert_compile_time_warning(
        Spark.Error.DslError,
        "specification: major_version",
        fn ->
          defmodule InvalidSpecMajorVersion do
            alias Diffo.Provider.BaseInstance
            use Ash.Resource, fragments: [BaseInstance], domain: Diffo.Test.Servo

            resource do
              description "resource with negative major_version"
            end

            provider do
              specification do
                id "cd29956f-6c68-44cc-bf54-705eb8d2f754"
                name "invalid"
                major_version -1
              end
            end
          end
        end
      )
    end

    test "tmf_version below minimum warns DslError on compilation" do
      Util.assert_compile_time_warning(
        Spark.Error.DslError,
        "specification: tmf_version",
        fn ->
          defmodule InvalidSpecTmfVersion do
            alias Diffo.Provider.BaseInstance
            use Ash.Resource, fragments: [BaseInstance], domain: Diffo.Test.Servo

            resource do
              description "resource with tmf_version below minimum"
            end

            provider do
              specification do
                id "cd29956f-6c68-44cc-bf54-705eb8d2f754"
                name "invalid"
                tmf_version 0
              end
            end
          end
        end
      )
    end
  end

  describe "characteristics verifier" do
    test "duplicate characteristic name warns DslError on compilation" do
      Util.assert_compile_time_warning(
        Spark.Error.DslError,
        "characteristics: name :foo is declared more than once",
        fn ->
          defmodule DuplicateCharName do
            alias Diffo.Provider.BaseInstance
            use Ash.Resource, fragments: [BaseInstance], domain: Diffo.Test.Servo

            resource do
              description "resource with duplicate characteristic name"
            end

            provider do
              specification do
                id "cd29956f-6c68-44cc-bf54-705eb8d2f754"
                name "invalid"
              end

              characteristics do
                characteristic :foo, Diffo.Test.ShelfValue
                characteristic :foo, Diffo.Test.ShelfValue
              end
            end
          end
        end
      )
    end

    test "non-existent value_type module warns DslError on compilation" do
      Util.assert_compile_time_warning(
        Spark.Error.DslError,
        "characteristics: value_type NonExistent.CharValue does not exist",
        fn ->
          defmodule InvalidCharValueType do
            alias Diffo.Provider.BaseInstance
            use Ash.Resource, fragments: [BaseInstance], domain: Diffo.Test.Servo

            resource do
              description "resource with non-existent characteristic value_type"
            end

            provider do
              specification do
                id "cd29956f-6c68-44cc-bf54-705eb8d2f754"
                name "invalid"
              end

              characteristics do
                characteristic :foo, NonExistent.CharValue
              end
            end
          end
        end
      )
    end

    test "non-existent array value_type module warns DslError on compilation" do
      Util.assert_compile_time_warning(
        Spark.Error.DslError,
        "characteristics: value_type NonExistent.ArrayValue does not exist",
        fn ->
          defmodule InvalidArrayCharValueType do
            alias Diffo.Provider.BaseInstance
            use Ash.Resource, fragments: [BaseInstance], domain: Diffo.Test.Servo

            resource do
              description "resource with non-existent array characteristic value_type"
            end

            provider do
              specification do
                id "cd29956f-6c68-44cc-bf54-705eb8d2f754"
                name "invalid"
              end

              characteristics do
                characteristic :bar, {:array, NonExistent.ArrayValue}
              end
            end
          end
        end
      )
    end
  end

  describe "features verifier" do
    test "duplicate feature name warns DslError on compilation" do
      Util.assert_compile_time_warning(
        Spark.Error.DslError,
        "features: name :my_feature is declared more than once",
        fn ->
          defmodule DuplicateFeatureName do
            alias Diffo.Provider.BaseInstance
            use Ash.Resource, fragments: [BaseInstance], domain: Diffo.Test.Servo

            resource do
              description "resource with duplicate feature names"
            end

            provider do
              specification do
                id "cd29956f-6c68-44cc-bf54-705eb8d2f754"
                name "invalid"
              end

              features do
                feature :my_feature do
                end

                feature :my_feature do
                end
              end
            end
          end
        end
      )
    end

    test "duplicate feature characteristic name warns DslError on compilation" do
      Util.assert_compile_time_warning(
        Spark.Error.DslError,
        "features: characteristic name :baz is declared more than once in :my_feature",
        fn ->
          defmodule DuplicateFeatureCharName do
            alias Diffo.Provider.BaseInstance
            use Ash.Resource, fragments: [BaseInstance], domain: Diffo.Test.Servo

            resource do
              description "resource with duplicate feature characteristic names"
            end

            provider do
              specification do
                id "cd29956f-6c68-44cc-bf54-705eb8d2f754"
                name "invalid"
              end

              features do
                feature :my_feature do
                  characteristic :baz, Diffo.Test.ShelfValue
                  characteristic :baz, Diffo.Test.ShelfValue
                end
              end
            end
          end
        end
      )
    end

    test "non-existent feature characteristic value_type warns DslError on compilation" do
      Util.assert_compile_time_warning(
        Spark.Error.DslError,
        "features: characteristic value_type NonExistent.FeatureValue does not exist",
        fn ->
          defmodule InvalidFeatureCharValueType do
            alias Diffo.Provider.BaseInstance
            use Ash.Resource, fragments: [BaseInstance], domain: Diffo.Test.Servo

            resource do
              description "resource with non-existent feature characteristic value_type"
            end

            provider do
              specification do
                id "cd29956f-6c68-44cc-bf54-705eb8d2f754"
                name "invalid"
              end

              features do
                feature :my_feature do
                  characteristic :baz, NonExistent.FeatureValue
                end
              end
            end
          end
        end
      )
    end
  end

  describe "parties verifier" do
    test "duplicate party role names warns DslError on compilation" do
      Util.assert_compile_time_warning(
        Spark.Error.DslError,
        "parties: role :operator is declared more than once",
        fn ->
          defmodule DuplicatePartyRole do
            alias Diffo.Provider.BaseInstance
            alias Diffo.Test.Shelf
            use Ash.Resource, fragments: [BaseInstance], domain: Diffo.Test.Servo

            resource do
              description "resource with duplicate party roles"
            end

            provider do
              specification do
                id "cd29956f-6c68-44cc-bf54-705eb8d2f754"
                name "invalid"
              end

              parties do
                party :operator, Shelf
                party :operator, Shelf
              end
            end
          end
        end
      )
    end

    test "non-existent party_type module warns DslError on compilation" do
      Util.assert_compile_time_warning(
        Spark.Error.DslError,
        "parties: party_type NonExistent.PartyModule does not exist",
        fn ->
          defmodule InvalidPartyType do
            alias Diffo.Provider.BaseInstance
            use Ash.Resource, fragments: [BaseInstance], domain: Diffo.Test.Servo

            resource do
              description "resource with non-existent party_type"
            end

            provider do
              specification do
                id "cd29956f-6c68-44cc-bf54-705eb8d2f754"
                name "invalid"
              end

              parties do
                party :operator, NonExistent.PartyModule
              end
            end
          end
        end
      )
    end

    test "party_type not extending BaseParty warns DslError on compilation" do
      Util.assert_compile_time_warning(
        Spark.Error.DslError,
        "parties: party_type Diffo.Test.Shelf does not extend BaseParty",
        fn ->
          defmodule InvalidPartyBaseType do
            alias Diffo.Provider.BaseInstance
            use Ash.Resource, fragments: [BaseInstance], domain: Diffo.Test.Servo

            resource do
              description "resource with party_type that is not a BaseParty"
            end

            provider do
              specification do
                id "cd29956f-6c68-44cc-bf54-705eb8d2f754"
                name "invalid"
              end

              parties do
                party :operator, Diffo.Test.Shelf
              end
            end
          end
        end
      )
    end
  end

  describe "behaviour verifier" do
    test "undeclared create action name warns DslError on compilation" do
      Util.assert_compile_time_warning(
        Spark.Error.DslError,
        "behaviour: create :nonexistent does not exist as a create action on this resource",
        fn ->
          defmodule BehaviourMissingCreate do
            alias Diffo.Provider.BaseInstance
            use Ash.Resource, fragments: [BaseInstance], domain: Diffo.Test.Servo

            resource do
              description "resource with behaviour referencing a missing create action"
            end

            provider do
              specification do
                id "cd29956f-6c68-44cc-bf54-705eb8d2f754"
                name "invalid"
              end

              behaviour do
                actions do
                  create :nonexistent
                end
              end
            end
          end
        end
      )
    end

    test "undeclared update action name warns DslError on compilation" do
      Util.assert_compile_time_warning(
        Spark.Error.DslError,
        "behaviour: update :nonexistent does not exist as an update action on this resource",
        fn ->
          defmodule BehaviourMissingUpdate do
            alias Diffo.Provider.BaseInstance
            use Ash.Resource, fragments: [BaseInstance], domain: Diffo.Test.Servo

            resource do
              description "resource with behaviour referencing a missing update action"
            end

            provider do
              specification do
                id "cd29956f-6c68-44cc-bf54-705eb8d2f754"
                name "invalid"
              end

              behaviour do
                actions do
                  update :nonexistent
                end
              end
            end
          end
        end
      )
    end
  end
end
