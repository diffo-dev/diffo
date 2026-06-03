# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Extension.InheritedPlacePartyTraversalTest do
  @moduledoc """
  #226 — `inherited_place` / `inherited_party` adopt the unified #213 `via:` grammar
  (forward relationship hops) plus `collapse`, over the shared `Traversal.walk`. `via:`
  reaches the instance; `source_role` is the terminal `PlaceRef` / `PartyRef` deref.
  """
  use ExUnit.Case, async: true
  @moduletag :domain_extended

  alias Diffo.Test.Servo

  setup do
    AshNeo4j.Sandbox.checkout()
    on_exit(&AshNeo4j.Sandbox.rollback/0)
  end

  describe "inherited_place via a forward relationship hop (#226)" do
    test "reaches each contained card and reads its :location PlaceRef" do
      probe = probe!()
      c1 = card!("card-1")
      c2 = card!("card-2")
      contains!(probe, c1)
      contains!(probe, c2)
      p1 = place_on!(c1, :location, "LOC-1", "Loc 1")
      p2 = place_on!(c2, :location, "LOC-2", "Loc 2")

      probe = Ash.load!(probe, [:contained_locations], domain: Servo)

      assert probe.contained_locations |> Enum.map(& &1.id) |> Enum.sort() ==
               Enum.sort([p1.id, p2.id])
    end

    test "collapse :first / :last pick an end of the reached places" do
      probe = probe!()
      c1 = card!("card-1")
      c2 = card!("card-2")
      contains!(probe, c1)
      contains!(probe, c2)
      p1 = place_on!(c1, :location, "LOC-1", "Loc 1")
      p2 = place_on!(c2, :location, "LOC-2", "Loc 2")

      probe = Ash.load!(probe, [:first_location, :last_location], domain: Servo)

      refute is_list(probe.first_location)
      assert probe.first_location.id == p1.id
      assert probe.last_location.id == p2.id
    end

    test "collapse returns nil when nothing is reached" do
      probe = probe!() |> Ash.load!([:first_location], domain: Servo)
      assert probe.first_location == nil
    end
  end

  describe "inherited_party via a forward relationship hop (#226)" do
    test "reaches each contained card and reads its :provider PartyRef" do
      probe = probe!()
      c1 = card!("card-1")
      c2 = card!("card-2")
      contains!(probe, c1)
      contains!(probe, c2)
      a = party_on!(c1, :provider, "ORG-1", "Org 1")
      b = party_on!(c2, :provider, "ORG-2", "Org 2")

      probe = Ash.load!(probe, [:contained_providers], domain: Servo)

      assert probe.contained_providers |> Enum.map(& &1.id) |> Enum.sort() ==
               Enum.sort([a.id, b.id])
    end

    test "collapse :first picks one provider in reached order" do
      probe = probe!()
      c1 = card!("card-1")
      c2 = card!("card-2")
      contains!(probe, c1)
      contains!(probe, c2)
      a = party_on!(c1, :provider, "ORG-1", "Org 1")
      _b = party_on!(c2, :provider, "ORG-2", "Org 2")

      probe = Ash.load!(probe, [:first_provider], domain: Servo)

      refute is_list(probe.first_provider)
      assert probe.first_provider.id == a.id
    end
  end

  defp probe!(name \\ "probe") do
    {:ok, probe} = Servo.build_traversal_probe(%{name: name})
    probe
  end

  defp card!(name) do
    {:ok, card} = Servo.build_card(%{name: name})
    card
  end

  defp contains!(source, target) do
    Diffo.Provider.create_defined_simple_relationship!(%{
      type: :contains,
      source_id: source.id,
      target_id: target.id
    })
  end

  defp place_on!(instance, role, id, name) do
    place = Diffo.Provider.create_place!(:GeographicSite, %{id: id, name: name})
    Diffo.Provider.create_place_ref!(%{instance_id: instance.id, role: role, place_id: place.id})
    place
  end

  defp party_on!(instance, role, id, name) do
    party = Diffo.Provider.create_party!(:Organization, %{id: id, name: name})
    Diffo.Provider.create_party_ref!(%{instance_id: instance.id, role: role, party_id: party.id})
    party
  end
end
