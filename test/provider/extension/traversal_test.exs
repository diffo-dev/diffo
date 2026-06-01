# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Extension.TraversalTest do
  @moduledoc false
  use ExUnit.Case, async: true
  @moduletag :domain_extended

  alias Diffo.Provider.Assignment
  alias Diffo.Provider.Extension.Traversal, as: Normalize
  alias Diffo.Provider.Calculations.Traversal, as: Walk
  alias Diffo.Test.Servo

  describe "normalize/2 — hop grammar" do
    test "nil via defaults to a single reverse-assignment hop keyed by name" do
      assert Normalize.normalize(nil, :card) ==
               {:ok, [{:reverse, :assignment, %{alias: :card}}]}
    end

    test "bare atoms are reverse-assignment shorthand (back-compat for via: [:a, :b])" do
      assert Normalize.normalize([:primary], :x) ==
               {:ok, [{:reverse, :assignment, %{alias: :primary}}]}

      assert Normalize.normalize([:port, :slot], :x) ==
               {:ok,
                [
                  {:reverse, :assignment, %{alias: :port}},
                  {:reverse, :assignment, %{alias: :slot}}
                ]}
    end

    test "explicit forward / reverse assignment hops" do
      assert Normalize.normalize([{:forward, assignment: :slot}], :x) ==
               {:ok, [{:forward, :assignment, %{alias: :slot}}]}

      assert Normalize.normalize([{:reverse, assignment: :cvlan}], :x) ==
               {:ok, [{:reverse, :assignment, %{alias: :cvlan}}]}
    end

    test "relationship hops by bare type, by type+alias, and by alias only" do
      assert Normalize.normalize([{:forward, relationship: :contains}], :x) ==
               {:ok, [{:forward, :relationship, %{type: :contains, alias: nil}}]}

      assert Normalize.normalize([{:forward, relationship: [type: :owns, alias: :circuit]}], :x) ==
               {:ok, [{:forward, :relationship, %{type: :owns, alias: :circuit}}]}

      assert Normalize.normalize([{:reverse, relationship: [alias: :circuit]}], :x) ==
               {:ok, [{:reverse, :relationship, %{type: nil, alias: :circuit}}]}
    end

    test "mixed-mechanism, direction-changing chain normalises in order" do
      via = [{:forward, relationship: [alias: :circuit]}, {:reverse, assignment: :cvlan}]

      assert Normalize.normalize(via, :cvc) ==
               {:ok,
                [
                  {:forward, :relationship, %{type: nil, alias: :circuit}},
                  {:reverse, :assignment, %{alias: :cvlan}}
                ]}
    end

    test "errors on malformed hops" do
      assert {:error, {:invalid_via, "nope"}} = Normalize.normalize("nope", :x)
      assert {:error, {:invalid_hop, 123}} = Normalize.normalize([123], :x)
      assert {:error, {:invalid_hop, _}} = Normalize.normalize([{:sideways, assignment: :a}], :x)

      assert {:error, {:hop_missing_mechanism, _}} =
               Normalize.normalize([{:forward, foo: :bar}], :x)

      assert {:error, {:assignment_requires_alias, nil}} =
               Normalize.normalize([{:forward, assignment: nil}], :x)

      assert {:error, {:relationship_requires_type_or_alias, _}} =
               Normalize.normalize([{:forward, relationship: []}], :x)
    end
  end

  describe "walk/2 — graph traversal" do
    setup do
      AshNeo4j.Sandbox.checkout()
      on_exit(&AshNeo4j.Sandbox.rollback/0)
    end

    test "empty hop list returns the starting id" do
      {:ok, card} = Servo.build_card(%{})
      assert Walk.walk(card.id, []) == [card.id]
    end

    test "forward and reverse assignment hops, with fan-out and dedup" do
      {shelf, card_a, card_b} = shelf_with_two_assigned_cards()

      # forward assignment from the shelf fans out to both assigned cards
      assert Enum.sort(Walk.walk(shelf.id, [{:forward, :assignment, %{alias: :slot}}])) ==
               Enum.sort([card_a.id, card_b.id])

      # reverse assignment from a card climbs back to its assigner shelf
      assert Walk.walk(card_a.id, [{:reverse, :assignment, %{alias: :slot}}]) == [shelf.id]

      # two-hop fan-out then fan-in: both cards reverse to the same shelf → deduped to one
      hops = [{:forward, :assignment, %{alias: :slot}}, {:reverse, :assignment, %{alias: :slot}}]
      assert Walk.walk(shelf.id, hops) == [shelf.id]
    end

    test "forward and reverse relationship hops by type" do
      {:ok, shelf} = Diffo.Test.Parties.build_shelf_with_installer()
      {:ok, card} = Servo.build_card(%{})

      Diffo.Provider.create_defined_simple_relationship!(%{
        type: :contains,
        source_id: shelf.id,
        target_id: card.id
      })

      assert Walk.walk(shelf.id, [{:forward, :relationship, %{type: :contains, alias: nil}}]) ==
               [card.id]

      assert Walk.walk(card.id, [{:reverse, :relationship, %{type: :contains, alias: nil}}]) ==
               [shelf.id]
    end
  end

  defp shelf_with_two_assigned_cards do
    {:ok, shelf} = Diffo.Test.Parties.build_shelf_with_installer()

    shelf_updates = [
      shelf: [family: :ISAM, model: "EBLT48", technology: :adsl2Plus],
      slots: [first: 1, last: 16, assignable_type: "Slot"]
    ]

    {:ok, shelf} = Servo.define_shelf(shelf, %{characteristic_value_updates: shelf_updates})
    {:ok, shelf} = Servo.lifecycle_shelf(shelf, %{lifecycle_state: :installed})

    {:ok, card_a} = Servo.build_card(%{})
    {:ok, card_b} = Servo.build_card(%{})

    for card <- [card_a, card_b] do
      {:ok, _shelf} =
        Servo.assign_slot(shelf, %{
          assignment: %Assignment{
            assignee_id: card.id,
            operation: :auto_assign,
            alias: :slot
          }
        })
    end

    {shelf, card_a, card_b}
  end
end
