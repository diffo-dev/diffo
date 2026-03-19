# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.InstanceExtension.SpecificationTest do
  @moduledoc false
  use ExUnit.Case
  alias Diffo.Test.Servo

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
  end
end
