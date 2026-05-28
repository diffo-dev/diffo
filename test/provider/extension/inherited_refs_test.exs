# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Extension.InheritedRefsTest do
  @moduledoc false
  use ExUnit.Case, async: true
  @moduletag :domain_extended

  alias Diffo.Provider.Assignment
  alias Diffo.Test.Servo

  setup do
    AshNeo4j.Sandbox.checkout()
    on_exit(&AshNeo4j.Sandbox.rollback/0)
  end

  describe "inherited_place — single-hop via alias" do
    test "service inherits place from assigned card via :primary alias" do
      place =
        Diffo.Provider.create_place!(%{
          id: "LOC-TEST-INHERITED-001",
          name: "Test Exchange",
          type: :GeographicSite
        })

      {:ok, card} = Servo.build_card(%{})

      updates = [
        card: [family: :ISAM, model: "EBLT48", technology: :adsl2Plus],
        ports: [first: 1, last: 48, assignable_type: "ADSL2+"]
      ]

      {:ok, card} = Servo.define_card(card, %{characteristic_value_updates: updates})
      {:ok, card} = Servo.lifecycle_card(card, %{resource_state: :operating})

      Diffo.Provider.create_place_ref!(%{
        instance_id: card.id,
        role: :location,
        place_id: place.id
      })

      {:ok, service} = Servo.build_access_service(%{})

      {:ok, _card} =
        Servo.assign_port(card, %{
          assignment: %Assignment{
            assignee_id: service.id,
            operation: :auto_assign,
            alias: :primary
          }
        })

      service = Ash.load!(service, [:primary], domain: Servo)

      assert length(service.primary) == 1
      assert hd(service.primary).id == place.id
    end

    test "service with no assignment returns empty list for inherited place" do
      {:ok, service} = Servo.build_access_service(%{})

      service = Ash.load!(service, [:primary], domain: Servo)

      assert service.primary == []
    end

    test "service inherits only the place from the aliased assignment, not from unaliased ones" do
      place_a =
        Diffo.Provider.create_place!(%{
          id: "LOC-TEST-INHERITED-002",
          name: "Exchange A",
          type: :GeographicSite
        })

      place_b =
        Diffo.Provider.create_place!(%{
          id: "LOC-TEST-INHERITED-003",
          name: "Exchange B",
          type: :GeographicSite
        })

      {:ok, card_a} = Servo.build_card(%{})
      {:ok, card_b} = Servo.build_card(%{})

      updates = [
        card: [family: :ISAM, model: "EBLT48", technology: :adsl2Plus],
        ports: [first: 1, last: 48, assignable_type: "ADSL2+"]
      ]

      {:ok, card_a} = Servo.define_card(card_a, %{characteristic_value_updates: updates})
      {:ok, card_a} = Servo.lifecycle_card(card_a, %{resource_state: :operating})
      {:ok, card_b} = Servo.define_card(card_b, %{characteristic_value_updates: updates})
      {:ok, card_b} = Servo.lifecycle_card(card_b, %{resource_state: :operating})

      Diffo.Provider.create_place_ref!(%{
        instance_id: card_a.id,
        role: :location,
        place_id: place_a.id
      })

      Diffo.Provider.create_place_ref!(%{
        instance_id: card_b.id,
        role: :location,
        place_id: place_b.id
      })

      {:ok, service} = Servo.build_access_service(%{})

      {:ok, _card_a} =
        Servo.assign_port(card_a, %{
          assignment: %Assignment{
            assignee_id: service.id,
            operation: :auto_assign,
            alias: :primary
          }
        })

      {:ok, _card_b} =
        Servo.assign_port(card_b, %{
          assignment: %Assignment{
            assignee_id: service.id,
            operation: :auto_assign,
            alias: :secondary
          }
        })

      service = Ash.load!(service, [:primary], domain: Servo)

      assert length(service.primary) == 1
      assert hd(service.primary).id == place_a.id
    end
  end

  describe "inherited_characteristic — typed characteristic via alias traversal (inward)" do
    test "service inherits the assigning card's :card characteristic via :primary alias" do
      {:ok, card} = Servo.build_card(%{})

      updates = [
        card: [family: :ISAM, model: "EBLT48", technology: :adsl2Plus],
        ports: [first: 1, last: 48, assignable_type: "ADSL2+"]
      ]

      {:ok, card} = Servo.define_card(card, %{characteristic_value_updates: updates})
      {:ok, card} = Servo.lifecycle_card(card, %{resource_state: :operating})

      {:ok, service} = Servo.build_access_service(%{})

      {:ok, _card} =
        Servo.assign_port(card, %{
          assignment: %Assignment{
            assignee_id: service.id,
            operation: :auto_assign,
            alias: :primary
          }
        })

      service = Ash.load!(service, [:card], domain: Servo)

      # The :card calc returns the assigning card's typed :card characteristic
      # record. With one source via :primary, we expect a single entry. No
      # %Diffo.Unknown{} — the card concretely declares :card, CardCharacteristic.
      assert is_list(service.card)
      refute Enum.empty?(service.card)
      refute Enum.any?(service.card, &is_struct(&1, Diffo.Unknown))

      assert Enum.any?(service.card, fn entry ->
               is_struct(entry, Diffo.Test.Characteristic.CardCharacteristic) and
                 entry.instance_id == card.id
             end)
    end

    test "service with no assignment yields empty inherited_characteristic" do
      {:ok, service} = Servo.build_access_service(%{})

      service = Ash.load!(service, [:card], domain: Servo)

      assert service.card == []
    end
  end

  describe "reverse_inherited_characteristic — typed characteristic of assignees (outward)" do
    test "shelf surfaces the :card characteristic of every CardInstance assigned via :slot" do
      {:ok, shelf} = Diffo.Test.Parties.build_shelf_with_installer()

      shelf_updates = [
        shelf: [family: :ISAM, model: "EBLT48", technology: :adsl2Plus],
        slots: [first: 1, last: 16, assignable_type: "Slot"]
      ]

      {:ok, shelf} = Servo.define_shelf(shelf, %{characteristic_value_updates: shelf_updates})
      {:ok, shelf} = Servo.lifecycle_shelf(shelf, %{resource_state: :operating})

      updates = [
        card: [family: :ISAM, model: "EBLT48", technology: :adsl2Plus],
        ports: [first: 1, last: 48, assignable_type: "ADSL2+"]
      ]

      {:ok, card_a} = Servo.build_card(%{})
      {:ok, card_a} = Servo.define_card(card_a, %{characteristic_value_updates: updates})
      {:ok, card_a} = Servo.lifecycle_card(card_a, %{resource_state: :operating})

      {:ok, card_b} = Servo.build_card(%{})
      {:ok, card_b} = Servo.define_card(card_b, %{characteristic_value_updates: updates})
      {:ok, card_b} = Servo.lifecycle_card(card_b, %{resource_state: :operating})

      {:ok, _shelf} =
        Servo.assign_slot(shelf, %{
          assignment: %Assignment{
            assignee_id: card_a.id,
            operation: :auto_assign,
            alias: :slot
          }
        })

      {:ok, _shelf} =
        Servo.assign_slot(shelf, %{
          assignment: %Assignment{
            assignee_id: card_b.id,
            operation: :auto_assign,
            alias: :slot
          }
        })

      shelf = Ash.load!(shelf, [:assigned_cards], domain: Servo)

      # Two assignees via :slot → two CardCharacteristic entries.
      assert is_list(shelf.assigned_cards)

      card_chars =
        Enum.filter(
          shelf.assigned_cards,
          &is_struct(&1, Diffo.Test.Characteristic.CardCharacteristic)
        )

      assignee_ids = Enum.map(card_chars, & &1.instance_id) |> Enum.sort()
      assert assignee_ids == Enum.sort([card_a.id, card_b.id])
    end

    test "shelf with no slot assignees yields empty reverse_inherited_characteristic" do
      {:ok, shelf} = Diffo.Test.Parties.build_shelf_with_installer()

      shelf = Ash.load!(shelf, [:assigned_cards], domain: Servo)

      assert shelf.assigned_cards == []
    end
  end
end
