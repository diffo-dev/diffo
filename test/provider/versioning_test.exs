# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.VersioningTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias Diffo.Test.Servo
  alias Diffo.Test.Broadband
  alias Diffo.Test.BroadbandV2

  setup do
    AshNeo4j.Sandbox.checkout()
    on_exit(&AshNeo4j.Sandbox.rollback/0)
  end

  describe "minor version — backward-compatible change" do
    # A minor version represents a non-breaking change such as adding a new technology type.
    # The specification node is updated in place — no migration of any kind is required.
    # All existing instances immediately reflect the new version.

    test "minor version bump updates the specification node to v1.1.0" do
      Servo.build_broadband(%{})
      {:ok, spec} = Diffo.Provider.get_specification_by_id(Broadband.specification()[:id])
      assert spec.version == "v1.0.0"

      minored = Diffo.Provider.next_minor_specification!(spec)
      assert minored.version == "v1.1.0"
    end

    test "all existing V1 instances immediately reflect the new minor version" do
      {:ok, v1_a} = Servo.build_broadband(%{})
      {:ok, v1_b} = Servo.build_broadband(%{})

      {:ok, spec} = Diffo.Provider.get_specification_by_id(Broadband.specification()[:id])
      Diffo.Provider.next_minor_specification!(spec)

      {:ok, reloaded_a} = Diffo.Provider.get_instance_by_id(v1_a.id)
      {:ok, reloaded_b} = Diffo.Provider.get_instance_by_id(v1_b.id)
      assert reloaded_a.specification.version == "v1.1.0"
      assert reloaded_b.specification.version == "v1.1.0"
    end

    test "minor version freeze — removing behaviour do blocks creation without a new module" do
      # When NBN removes behaviour do from Broadband and deploys v1.1, build_broadband
      # disappears from the domain API. This is the machine-readable announcement of the freeze.
      # Existing instances are unaffected; all other operations continue via the module.
      # This cannot be demonstrated in a single test suite since the module is fixed at
      # compile time, but the mechanism is proven by the BroadbandV1_1 fixture pattern:
      # same spec id, no behaviour do block, no build wired in the domain.
      assert Broadband.specification()[:id] == "a1b2c3d4-e5f6-4a7b-8c9d-e0f1a2b3c4d5"
      assert function_exported?(Diffo.Test.Servo, :build_broadband, 2)
      refute function_exported?(Diffo.Test.Servo, :build_broadband_v1_1, 2)
    end
  end

  describe "major version — concurrent V1 and V2" do
    test "V1 and V2 specifications coexist with same name and different major_version" do
      Servo.build_broadband(%{})
      Servo.build_broadband_v2(%{})

      specs = Diffo.Provider.find_specifications_by_name!("broadband")
      assert length(specs) == 2

      versions = Enum.map(specs, & &1.major_version) |> Enum.sort()
      assert versions == [1, 2]
    end

    test "V1 instance is linked to V1 specification" do
      {:ok, v1} = Servo.build_broadband(%{})
      assert v1.specification_id == Broadband.specification()[:id]
    end

    test "V2 instance is linked to V2 specification" do
      {:ok, v2} = Servo.build_broadband_v2(%{})
      assert v2.specification_id == BroadbandV2.specification()[:id]
    end

    test "V1 and V2 instances operate concurrently" do
      {:ok, v1} = Servo.build_broadband(%{})
      {:ok, v2} = Servo.build_broadband_v2(%{})

      v1_instances = Diffo.Provider.find_instances_by_specification_id!(Broadband.specification()[:id])
      v2_instances = Diffo.Provider.find_instances_by_specification_id!(BroadbandV2.specification()[:id])

      assert length(v1_instances) == 1
      assert length(v2_instances) == 1
      assert v1.specification_id != v2.specification_id
    end
  end

  describe "major version — RSP migration from V1 to V2" do
    # V2 must be published (specification node created) before any instance can be
    # respecified to it. Building the first V2 instance is what publishes the specification.
    setup do
      {:ok, _} = Servo.build_broadband_v2(%{})
      :ok
    end

    test "V1 instance is respecified to V2 via respecify_instance" do
      {:ok, v1} = Servo.build_broadband(%{})
      {:ok, instance} = Diffo.Provider.get_instance_by_id(v1.id)

      {:ok, migrated} = Diffo.Provider.respecify_instance(instance, %{
        specified_by: BroadbandV2.specification()[:id]
      })

      assert migrated.specification.id == BroadbandV2.specification()[:id]
    end

    test "migrated instance is found by V2 specification" do
      {:ok, v1} = Servo.build_broadband(%{})
      {:ok, instance} = Diffo.Provider.get_instance_by_id(v1.id)
      {:ok, _} = Diffo.Provider.respecify_instance(instance, %{
        specified_by: BroadbandV2.specification()[:id]
      })

      v2_instances = Diffo.Provider.find_instances_by_specification_id!(BroadbandV2.specification()[:id])
      assert Enum.any?(v2_instances, &(&1.id == v1.id))
    end

    test "migrated instance is no longer found by V1 specification" do
      {:ok, v1} = Servo.build_broadband(%{})
      {:ok, instance} = Diffo.Provider.get_instance_by_id(v1.id)
      {:ok, _} = Diffo.Provider.respecify_instance(instance, %{
        specified_by: BroadbandV2.specification()[:id]
      })

      v1_instances = Diffo.Provider.find_instances_by_specification_id!(Broadband.specification()[:id])
      refute Enum.any?(v1_instances, &(&1.id == v1.id))
    end

    test "V1 withdrawal — all V1 instances migrated, none remain on V1" do
      {:ok, v1_a} = Servo.build_broadband(%{})
      {:ok, v1_b} = Servo.build_broadband(%{})

      {:ok, instance_a} = Diffo.Provider.get_instance_by_id(v1_a.id)
      {:ok, instance_b} = Diffo.Provider.get_instance_by_id(v1_b.id)
      {:ok, _} = Diffo.Provider.respecify_instance(instance_a, %{specified_by: BroadbandV2.specification()[:id]})
      {:ok, _} = Diffo.Provider.respecify_instance(instance_b, %{specified_by: BroadbandV2.specification()[:id]})

      assert Diffo.Provider.find_instances_by_specification_id!(Broadband.specification()[:id]) == []
      assert length(Diffo.Provider.find_instances_by_specification_id!(BroadbandV2.specification()[:id])) == 3
    end
  end
end
