# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Extension.PlaceVerifierTest do
  @moduledoc false
  use ExUnit.Case, async: true, async: false
  alias Diffo.Test.Util

  describe "instances verifier" do
    test "duplicate instance role warns DslError on compilation" do
      Util.assert_compile_time_warning(
        Spark.Error.DslError,
        "instances: role :site_for is declared more than once",
        fn ->
          defmodule DuplicatePlaceInstanceRole do
            alias Diffo.Provider.BasePlace
            use Ash.Resource, fragments: [BasePlace], domain: Diffo.Test.Nbn

            resource do
              description "place with duplicate instance role"
            end

            provider do
              instances do
                role :site_for, Diffo.Provider.Instance
                role :site_for, Diffo.Provider.Instance
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
          defmodule InvalidPlaceInstanceType do
            alias Diffo.Provider.BasePlace
            use Ash.Resource, fragments: [BasePlace], domain: Diffo.Test.Nbn

            resource do
              description "place with non-existent instance type"
            end

            provider do
              instances do
                role :site_for, NonExistent.InstanceModule
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
          defmodule WrongPlaceInstanceType do
            alias Diffo.Provider.BasePlace
            use Ash.Resource, fragments: [BasePlace], domain: Diffo.Test.Nbn

            resource do
              description "place with party as instance type"
            end

            provider do
              instances do
                role :site_for, Diffo.Test.Organization
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
        "parties: role :managed_by is declared more than once",
        fn ->
          defmodule DuplicatePlacePartyRole do
            alias Diffo.Provider.BasePlace
            use Ash.Resource, fragments: [BasePlace], domain: Diffo.Test.Nbn

            resource do
              description "place with duplicate party role"
            end

            provider do
              parties do
                role :managed_by, Diffo.Test.Organization
                role :managed_by, Diffo.Test.Organization
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
          defmodule InvalidPlacePartyType do
            alias Diffo.Provider.BasePlace
            use Ash.Resource, fragments: [BasePlace], domain: Diffo.Test.Nbn

            resource do
              description "place with non-existent party type"
            end

            provider do
              parties do
                role :managed_by, NonExistent.PartyModule
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
          defmodule WrongPlacePartyType do
            alias Diffo.Provider.BasePlace
            use Ash.Resource, fragments: [BasePlace], domain: Diffo.Test.Nbn

            resource do
              description "place with instance as party type"
            end

            provider do
              parties do
                role :managed_by, Diffo.Provider.Instance
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
        "places: role :contained_in is declared more than once",
        fn ->
          defmodule DuplicatePlacePlaceRole do
            alias Diffo.Provider.BasePlace
            use Ash.Resource, fragments: [BasePlace], domain: Diffo.Test.Nbn

            resource do
              description "place with duplicate place role"
            end

            provider do
              places do
                role :contained_in, Diffo.Provider.Place
                role :contained_in, Diffo.Provider.Place
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
          defmodule InvalidPlacePlaceType do
            alias Diffo.Provider.BasePlace
            use Ash.Resource, fragments: [BasePlace], domain: Diffo.Test.Nbn

            resource do
              description "place with non-existent place type"
            end

            provider do
              places do
                role :contained_in, NonExistent.PlaceModule
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
          defmodule WrongPlacePlaceType do
            alias Diffo.Provider.BasePlace
            use Ash.Resource, fragments: [BasePlace], domain: Diffo.Test.Nbn

            resource do
              description "place with party as place type"
            end

            provider do
              places do
                role :contained_in, Diffo.Test.Organization
              end
            end
          end
        end
      )
    end
  end
end
