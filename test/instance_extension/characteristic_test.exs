# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.InstanceExtension.CharacteristicTest do
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

  describe "characteristic" do
    test "create resource fails when characteristic value type invalid" do
      {:error, error} = Servo.build_invalid_characteristic(%{})
      %Ash.Error.Invalid{errors: errors} = error

      assert hd(errors).message ==
               "couldn't create characteristic with value of unknown type Elixir.InvalidValue"
    end
  end
end
