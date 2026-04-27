# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.InstanceExtension.VerifierTest do
  @moduledoc false
  use ExUnit.Case, async: false
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

            specification do
              id "ef016d85-9dbd-429c-04da-1df56cc7dda5"
              name "invalid"
            end
          end
        end
      )
    end
  end

  describe "characteristics verifier" do
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

            specification do
              id "cd29956f-6c68-44cc-bf54-705eb8d2f754"
              name "invalid"
            end

            characteristics do
              characteristic :foo, NonExistent.CharValue
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

            specification do
              id "cd29956f-6c68-44cc-bf54-705eb8d2f754"
              name "invalid"
            end

            characteristics do
              characteristic :bar, {:array, NonExistent.ArrayValue}
            end
          end
        end
      )
    end
  end

  describe "features verifier" do
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

            specification do
              id "cd29956f-6c68-44cc-bf54-705eb8d2f754"
              name "invalid"
            end

            parties do
              party :operator, NonExistent.PartyModule
            end
          end
        end
      )
    end
  end
end
