# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.InstanceExtension.SpecificationTest do
  @moduledoc false
  use ExUnit.Case
  alias Diffo.Test.Servo
  alias Diffo.Test.Shelf

  setup_all do
    AshNeo4j.BoltyHelper.start()
  end

  setup do
    on_exit(fn ->
      AshNeo4j.Neo4jHelper.delete_all()
    end)
  end

  describe "specification" do
    test "description declared in specification DSL roundtrips to the persisted specification" do
      spec_id = Shelf.specification()[:id]
      description = Shelf.specification()[:description]

      Servo.build_shelf(%{name: "s"})

      {:ok, specification} = Diffo.Provider.get_specification_by_id(spec_id)
      assert specification.description == description
    end

    test "minor_version declared in specification DSL roundtrips to the persisted specification" do
      Servo.build_shelf(%{name: "s"})

      {:ok, specification} = Diffo.Provider.get_specification_by_id(Shelf.specification()[:id])
      assert specification.minor_version == Shelf.specification()[:minor_version]
    end

    test "patch_version declared in specification DSL roundtrips to the persisted specification" do
      Servo.build_shelf(%{name: "s"})

      {:ok, specification} = Diffo.Provider.get_specification_by_id(Shelf.specification()[:id])
      assert specification.patch_version == Shelf.specification()[:patch_version]
    end

    test "tmf_version declared in specification DSL roundtrips to the persisted specification" do
      Servo.build_shelf(%{name: "s"})

      {:ok, specification} = Diffo.Provider.get_specification_by_id(Shelf.specification()[:id])
      assert specification.tmf_version == Shelf.specification()[:tmf_version]
    end
  end
end
