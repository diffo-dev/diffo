# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.InstanceExtension.CharacteristicTest do
  @moduledoc false
  use ExUnit.Case
  alias Diffo.Test.Servo
  alias Diffo.Test.Parties

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

    test "create resource with array characteristic - success" do
      {:ok, shelf} = Parties.build_shelf_with_installer()

      shelves = Enum.find(shelf.characteristics, fn c -> c.name == :shelves end)
      assert shelves.is_array == true
      assert shelves.values == []
      assert Diffo.Unwrap.unwrap(shelves) == []
    end
  end
end
