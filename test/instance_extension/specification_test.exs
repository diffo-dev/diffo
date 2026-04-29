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
    test "create resource fails when specification id not uuid v4" do
      {:error, error} = Servo.build_invalid_specification(%{})
      %Ash.Error.Invalid{errors: errors} = error
      assert hd(errors).message == "must be a uuid v4 or nil"
    end

    test "description declared in specification DSL roundtrips to the persisted specification" do
      spec_id = Shelf.specification()[:id]
      description = Shelf.specification()[:description]

      Servo.build_shelf(%{name: "s"})

      {:ok, specification} = Diffo.Provider.get_specification_by_id(spec_id)
      assert specification.description == description
    end
  end
end
