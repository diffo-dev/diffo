# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Extension.InheritedCharacteristicTraversalTest do
  @moduledoc """
  Exercises the new traversal capabilities of the unified `inherited_characteristic`
  DSL (#213): forward `DefinedSimpleRelationship` traversal, mixed
  relationship→assignment chains, `collapse` (`:first`/`:last`), `as:` rename, and the
  5-hop lawful-intercept showcase. All declarations live on
  `Diffo.Test.Instance.TraversalProbe` and read the `:card` characteristic from reached
  `CardInstance`s; edges are wired directly.
  """
  use ExUnit.Case, async: true
  @moduletag :domain_extended

  alias Diffo.Test.Characteristic.CardCharacteristic
  alias Diffo.Test.Servo

  setup do
    AshNeo4j.Sandbox.checkout()
    on_exit(&AshNeo4j.Sandbox.rollback/0)
  end

  describe "forward relationship traversal (#212-A)" do
    test "contained_cards returns the :card of every card contained via :contains" do
      probe = probe!()
      c1 = defined_card!("card-1")
      c2 = defined_card!("card-2")

      relate!(probe, c1, type: :contains)
      relate!(probe, c2, type: :contains)

      probe = Ash.load!(probe, [:contained_cards], domain: Servo)

      assert is_list(probe.contained_cards)
      assert Enum.all?(probe.contained_cards, &is_struct(&1, CardCharacteristic))

      assert probe.contained_cards |> Enum.map(& &1.instance_id) |> Enum.sort() ==
               Enum.sort([c1.id, c2.id])
    end

    test "contained_cards also follows a general Relationship :contains edge (#222)" do
      # The standard :relate action stores a mutable Diffo.Provider.Relationship, not a
      # DefinedSimpleRelationship — a relationship: hop must still reach it.
      probe = probe!()
      card = defined_card!("rel-card")

      Diffo.Provider.create_relationship!(%{
        type: :contains,
        source_id: probe.id,
        target_id: card.id
      })

      probe = Ash.load!(probe, [:contained_cards], domain: Servo)

      assert [%CardCharacteristic{instance_id: instance_id}] = probe.contained_cards
      assert instance_id == card.id
    end

    test "owned_card collapses the single card owned via :circuit to a raw record" do
      probe = probe!()
      card = defined_card!("owned")
      relate!(probe, card, type: :owns, alias: :circuit)

      probe = Ash.load!(probe, [:owned_card], domain: Servo)

      refute is_list(probe.owned_card)
      assert %CardCharacteristic{instance_id: instance_id} = probe.owned_card
      assert instance_id == card.id
    end

    test "owned_card is nil when nothing is owned" do
      probe = probe!() |> Ash.load!([:owned_card], domain: Servo)
      assert probe.owned_card == nil
    end
  end

  describe "collapse :first / :last over a forward-assignment fan-out (#211)" do
    test "first/last pick the ends of the (created_at-ordered) assignment list" do
      probe = probe!()
      card_a = defined_card!("A")
      card_b = defined_card!("B")

      assign!(probe, card_a, :slot, 1)
      assign!(probe, card_b, :slot, 2)

      probe = Ash.load!(probe, [:first_slot_card, :last_slot_card], domain: Servo)

      refute is_list(probe.first_slot_card)
      refute is_list(probe.last_slot_card)
      assert probe.first_slot_card.instance_id == card_a.id
      assert probe.last_slot_card.instance_id == card_b.id
    end

    test "collapse returns nil when there are no assignees" do
      probe = probe!() |> Ash.load!([:first_slot_card], domain: Servo)
      assert probe.first_slot_card == nil
    end
  end

  describe "as: rename" do
    test "tapped_cards renames the surfaced characteristic in the loaded value and on the wire" do
      probe = probe!()
      card = defined_card!("tapped")
      assign!(probe, card, :slot, 1)

      probe = Ash.load!(probe, [:tapped_cards], domain: Servo)

      assert [%CardCharacteristic{name: :tappedCard}] = probe.tapped_cards

      encoded = probe |> Jason.encode!() |> Jason.decode!()
      assert [%{"name" => "tappedCard", "value" => value}] = encoded["serviceCharacteristic"]
      assert value["family"] == "ISAM"
    end
  end

  describe "mixed relationship → assignment chain (#212-B)" do
    test "mixed_card follows forward :circuit then reverse :cvlan to the CVC" do
      probe = probe!()
      avc = node!("AVC")
      cvc = defined_card!("CVC")

      relate!(probe, avc, type: :owns, alias: :circuit)
      assign!(cvc, avc, :cvlan, 100)

      probe = Ash.load!(probe, [:mixed_card], domain: Servo)

      refute is_list(probe.mixed_card)
      assert probe.mixed_card.instance_id == cvc.id
    end
  end

  describe "5-hop lawful-intercept chain (UNI → PRI → AVC → CVC → NNI Group → NNIs)" do
    test "intercept_nnis returns every NNI the logical UNI could traverse" do
      probe = probe!("UNI")
      pri = node!("PRI")
      avc = node!("AVC")
      cvc = node!("CVC")
      nni_group = node!("NNI-Group")
      nni_a = defined_card!("NNI-A")
      nni_b = defined_card!("NNI-B")

      relate!(pri, probe, type: :owns, alias: :port)
      relate!(pri, avc, type: :owns, alias: :circuit)
      assign!(cvc, avc, :cvlan, 100)
      assign!(nni_group, cvc, :svlan, 200)
      relate!(nni_group, nni_a, type: :contains)
      relate!(nni_group, nni_b, type: :contains)

      probe = Ash.load!(probe, [:intercept_nnis], domain: Servo)

      assert is_list(probe.intercept_nnis)
      assert Enum.all?(probe.intercept_nnis, &is_struct(&1, CardCharacteristic))

      assert probe.intercept_nnis |> Enum.map(& &1.instance_id) |> Enum.sort() ==
               Enum.sort([nni_a.id, nni_b.id])
    end
  end

  # ── fixtures ──────────────────────────────────────────────────────────────

  defp probe!(name \\ "probe") do
    {:ok, probe} = Servo.build_traversal_probe(%{name: name})
    probe
  end

  # A bare instance node — just somewhere to hang edges.
  defp node!(name) do
    {:ok, node} = Servo.build_card(%{name: name})
    node
  end

  # A card with its :card characteristic populated (so there is something to read).
  defp defined_card!(name) do
    {:ok, card} = Servo.build_card(%{name: name})

    updates = [
      card: [family: :ISAM, model: "EBLT48", technology: :adsl2Plus],
      ports: [first: 1, last: 48, assignable_type: "ADSL2+"]
    ]

    {:ok, card} = Servo.define_card(card, %{characteristic_value_updates: updates})
    {:ok, card} = Servo.lifecycle_card(card, %{lifecycle_state: :installed})
    card
  end

  defp relate!(source, target, opts) do
    attrs = Enum.into(opts, %{source_id: source.id, target_id: target.id})
    Diffo.Provider.create_defined_simple_relationship!(attrs)
  end

  defp assign!(source, target, alias, value) do
    Diffo.Provider.create_assignment_relationship!(%{
      source_id: source.id,
      target_id: target.id,
      alias: alias,
      pool: :test,
      thing: :vlan,
      value: value
    })
  end
end
