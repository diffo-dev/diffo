# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Extension.PartyVerifierTest do
  @moduledoc false
  use ExUnit.Case, async: true, async: false
  alias Diffo.Test.Util

  describe "instances verifier" do
    test "duplicate instance role warns DslError on compilation" do
      Util.assert_compile_time_warning(
        Spark.Error.DslError,
        "instances: role :operator is declared more than once",
        fn ->
          defmodule DuplicateInstanceRole do
            alias Diffo.Provider.BaseParty
            use Ash.Resource, fragments: [BaseParty], domain: Diffo.Test.Nbn

            resource do
              description "resource with duplicate instance role"
            end

            provider do
              instances do
                role :operator, Diffo.Provider.Instance
                role :operator, Diffo.Provider.Instance
              end
            end
          end
        end
      )
    end

    test "non-existent instance_type warns DslError on compilation" do
      Util.assert_compile_time_warning(
        Spark.Error.DslError,
        "instances: instance_type NonExistent.InstanceModule does not exist",
        fn ->
          defmodule InvalidInstanceType do
            alias Diffo.Provider.BaseParty
            use Ash.Resource, fragments: [BaseParty], domain: Diffo.Test.Nbn

            resource do
              description "resource with non-existent instance type"
            end

            provider do
              instances do
                role :operator, NonExistent.InstanceModule
              end
            end
          end
        end
      )
    end

    test "instance_type not extending BaseInstance warns DslError on compilation" do
      Util.assert_compile_time_warning(
        Spark.Error.DslError,
        "instances: instance_type Diffo.Test.Organization does not extend BaseInstance",
        fn ->
          defmodule WrongInstanceType do
            alias Diffo.Provider.BaseParty
            use Ash.Resource, fragments: [BaseParty], domain: Diffo.Test.Nbn

            resource do
              description "resource with party as instance type"
            end

            provider do
              instances do
                role :operator, Diffo.Test.Organization
              end
            end
          end
        end
      )
    end
  end

  describe "parties verifier" do
    test "duplicate party role warns DslError on compilation" do
      Util.assert_compile_time_warning(
        Spark.Error.DslError,
        "parties: role :employer is declared more than once",
        fn ->
          defmodule DuplicatePartyRole do
            alias Diffo.Provider.BaseParty
            use Ash.Resource, fragments: [BaseParty], domain: Diffo.Test.Nbn

            resource do
              description "resource with duplicate party role"
            end

            provider do
              parties do
                role :employer, Diffo.Test.Organization
                role :employer, Diffo.Test.Organization
              end
            end
          end
        end
      )
    end

    test "non-existent party_type warns DslError on compilation" do
      Util.assert_compile_time_warning(
        Spark.Error.DslError,
        "parties: party_type NonExistent.PartyModule does not exist",
        fn ->
          defmodule InvalidPartyRoleType do
            alias Diffo.Provider.BaseParty
            use Ash.Resource, fragments: [BaseParty], domain: Diffo.Test.Nbn

            resource do
              description "resource with non-existent party type"
            end

            provider do
              parties do
                role :employer, NonExistent.PartyModule
              end
            end
          end
        end
      )
    end

    test "party_type not extending BaseParty warns DslError on compilation" do
      Util.assert_compile_time_warning(
        Spark.Error.DslError,
        "parties: party_type Diffo.Provider.Instance does not extend BaseParty",
        fn ->
          defmodule WrongPartyRoleType do
            alias Diffo.Provider.BaseParty
            use Ash.Resource, fragments: [BaseParty], domain: Diffo.Test.Nbn

            resource do
              description "resource with instance as party type"
            end

            provider do
              parties do
                role :employer, Diffo.Provider.Instance
              end
            end
          end
        end
      )
    end
  end

  describe "places verifier" do
    test "duplicate place role warns DslError on compilation" do
      Util.assert_compile_time_warning(
        Spark.Error.DslError,
        "places: role :headquarters is declared more than once",
        fn ->
          defmodule DuplicatePlaceRole do
            alias Diffo.Provider.BaseParty
            use Ash.Resource, fragments: [BaseParty], domain: Diffo.Test.Nbn

            resource do
              description "resource with duplicate place role"
            end

            provider do
              places do
                role :headquarters, Diffo.Provider.Place
                role :headquarters, Diffo.Provider.Place
              end
            end
          end
        end
      )
    end

    test "non-existent place_type warns DslError on compilation" do
      Util.assert_compile_time_warning(
        Spark.Error.DslError,
        "places: place_type NonExistent.PlaceModule does not exist",
        fn ->
          defmodule InvalidPlaceRoleType do
            alias Diffo.Provider.BaseParty
            use Ash.Resource, fragments: [BaseParty], domain: Diffo.Test.Nbn

            resource do
              description "resource with non-existent place type"
            end

            provider do
              places do
                role :headquarters, NonExistent.PlaceModule
              end
            end
          end
        end
      )
    end

    test "place_type not extending BasePlace warns DslError on compilation" do
      Util.assert_compile_time_warning(
        Spark.Error.DslError,
        "places: place_type Diffo.Test.Organization does not extend BasePlace",
        fn ->
          defmodule WrongPlaceRoleType do
            alias Diffo.Provider.BaseParty
            use Ash.Resource, fragments: [BaseParty], domain: Diffo.Test.Nbn

            resource do
              description "resource with party as place type"
            end

            provider do
              places do
                role :headquarters, Diffo.Test.Organization
              end
            end
          end
        end
      )
    end
  end
end
