# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Extension.PoolVerifierTest do
  @moduledoc false
  use ExUnit.Case, async: true, async: false
  @moduletag :domain_extended
  alias Diffo.Test.Util

  describe "pools verifier" do
    test "duplicate pool name warns DslError on compilation" do
      Util.assert_compile_time_warning(
        Spark.Error.DslError,
        "pools: name :slots is declared more than once",
        fn ->
          defmodule DuplicatePoolName do
            alias Diffo.Provider.BaseInstance
            use Ash.Resource, fragments: [BaseInstance], domain: Diffo.Test.Servo

            resource do
              description "resource with duplicate pool name"
            end

            provider do
              specification do
                id "a0b1c2d3-4e5f-4a6b-8c9d-0e1f2a3b4c5d"
                name "duplicatePool"
                type :resourceSpecification
              end

              pools do
                pool :slots, :slot
                pool :slots, :slot
              end
            end
          end
        end
      )
    end
  end
end
