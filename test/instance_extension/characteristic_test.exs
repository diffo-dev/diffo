# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.InstanceExtension.CharacteristicTest do
  @moduledoc false
  use ExUnit.Case
  alias Diffo.Test.Parties

  setup do
    AshNeo4j.Sandbox.checkout()
    on_exit(&AshNeo4j.Sandbox.rollback/0)
  end

  describe "characteristic" do
    test "create resource with array characteristic - success" do
      {:ok, shelf} = Parties.build_shelf_with_installer()

      shelves = Enum.find(shelf.characteristics, fn c -> c.name == :shelves end)
      assert shelves.is_array == true
      assert shelves.values == []
      assert Diffo.Unwrap.unwrap(shelves) == []
    end
  end
end
