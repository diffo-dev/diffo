# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Extension.FieldViaRelationshipTest do
  @moduledoc false
  use ExUnit.Case, async: true
  @moduletag :domain_extended

  alias Diffo.Test.Parties
  alias Diffo.Test.Servo

  setup do
    AshNeo4j.Sandbox.checkout()
    on_exit(&AshNeo4j.Sandbox.rollback/0)
  end

  describe "FieldViaRelationship — aliased" do
    test "returns field from target instance reached via alias" do
      {:ok, shelf} = Parties.build_shelf_with_installer()
      {:ok, card} = Servo.build_card(%{name: "target-card"})

      Diffo.Provider.create_defined_simple_relationship!(%{
        type: :assignedTo,
        alias: :link,
        source_id: shelf.id,
        target_id: card.id
      })

      shelf = Ash.load!(shelf, [:linked_target_name], domain: Servo)

      assert shelf.linked_target_name == ["target-card"]
    end

    test "returns empty list when no matching relationship exists" do
      {:ok, shelf} = Parties.build_shelf_with_installer()

      shelf = Ash.load!(shelf, [:linked_target_name], domain: Servo)

      assert shelf.linked_target_name == []
    end

    test "alias filters to only the matching target" do
      {:ok, shelf} = Parties.build_shelf_with_installer()
      {:ok, card_a} = Servo.build_card(%{name: "target-a"})
      {:ok, card_b} = Servo.build_card(%{name: "target-b"})

      Diffo.Provider.create_defined_simple_relationship!(%{
        type: :assignedTo,
        alias: :link,
        source_id: shelf.id,
        target_id: card_a.id
      })

      Diffo.Provider.create_defined_simple_relationship!(%{
        type: :assignedTo,
        alias: :other,
        source_id: shelf.id,
        target_id: card_b.id
      })

      shelf = Ash.load!(shelf, [:linked_target_name], domain: Servo)

      assert shelf.linked_target_name == ["target-a"]
    end
  end

  describe "FieldViaRelationship — type filter" do
    test "type filters to only relationships of the matching type" do
      {:ok, shelf} = Parties.build_shelf_with_installer()
      {:ok, card_a} = Servo.build_card(%{name: "target-a"})
      {:ok, card_b} = Servo.build_card(%{name: "target-b"})

      Diffo.Provider.create_defined_simple_relationship!(%{
        type: :assignedTo,
        alias: :link,
        source_id: shelf.id,
        target_id: card_a.id
      })

      Diffo.Provider.create_defined_simple_relationship!(%{
        type: :reliesOn,
        alias: :link,
        source_id: shelf.id,
        target_id: card_b.id
      })

      shelf = Ash.load!(shelf, [:assigned_linked_name], domain: Servo)

      assert shelf.assigned_linked_name == ["target-a"]
    end
  end
end
