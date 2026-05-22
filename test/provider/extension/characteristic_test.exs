# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Extension.CharacteristicTest do
  @moduledoc false
  use ExUnit.Case, async: true
  @moduletag :domain_extended
  alias Diffo.Test.Parties
  alias Diffo.Test.Servo

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

  # Regression coverage for issue #62 — invalid keys or invalid value types
  # supplied to a typed characteristic update must surface an error rather than
  # being silently dropped or persisted as-is.
  describe "typed characteristic update validation (#62)" do
    test "valid update succeeds" do
      {:ok, shelf} = Parties.build_shelf_with_installer()

      updates = [shelf: [family: :ISAM, model: "EBLT48", technology: :adsl2Plus]]

      assert {:ok, _} = Servo.define_shelf(shelf, %{characteristic_value_updates: updates})
    end

    test "unknown field is rejected" do
      {:ok, shelf} = Parties.build_shelf_with_installer()

      updates = [shelf: [family: :ISAM, cvc_id: "CVC-POI-SYD-001"]]

      assert {:error, _} = Servo.define_shelf(shelf, %{characteristic_value_updates: updates})
    end

    test "invalid value type is rejected" do
      {:ok, shelf} = Parties.build_shelf_with_installer()

      # :family is :atom — a bare map cannot be cast to an atom
      updates = [shelf: [family: %{not: :an_atom}]]

      assert {:error, _} = Servo.define_shelf(shelf, %{characteristic_value_updates: updates})
    end
  end
end
