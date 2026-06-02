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
        Diffo.Provider.create_place!(:GeographicSite, %{
          id: "LOC-TEST-INHERITED-001",
          name: "Test Exchange"
        })

      {:ok, card} = Servo.build_card(%{})

      updates = [
        card: [family: :ISAM, model: "EBLT48", technology: :adsl2Plus],
        ports: [first: 1, last: 48, assignable_type: "ADSL2+"]
      ]

      {:ok, card} = Servo.define_card(card, %{characteristic_value_updates: updates})
      {:ok, card} = Servo.lifecycle_card(card, %{lifecycle_state: :installed})

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
        Diffo.Provider.create_place!(:GeographicSite, %{
          id: "LOC-TEST-INHERITED-002",
          name: "Exchange A"
        })

      place_b =
        Diffo.Provider.create_place!(:GeographicSite, %{
          id: "LOC-TEST-INHERITED-003",
          name: "Exchange B"
        })

      {:ok, card_a} = Servo.build_card(%{})
      {:ok, card_b} = Servo.build_card(%{})

      updates = [
        card: [family: :ISAM, model: "EBLT48", technology: :adsl2Plus],
        ports: [first: 1, last: 48, assignable_type: "ADSL2+"]
      ]

      {:ok, card_a} = Servo.define_card(card_a, %{characteristic_value_updates: updates})
      {:ok, card_a} = Servo.lifecycle_card(card_a, %{lifecycle_state: :installed})
      {:ok, card_b} = Servo.define_card(card_b, %{characteristic_value_updates: updates})
      {:ok, card_b} = Servo.lifecycle_card(card_b, %{lifecycle_state: :installed})

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

  describe "inherited_place — Diffo.Unknown emission" do
    test "emits %Diffo.Unknown{reason: :role_not_declared} when reached source has no PlaceRef at the source_role" do
      # Card created + assigned to the service via :primary, but the card has
      # NO PlaceRef at `:location`. The source IS reached by the traversal —
      # so this isn't "no assignment" (which would return []) — but the role
      # isn't declared. Expect Unknown with the source_id and role in context.
      {:ok, card} = Servo.build_card(%{})

      updates = [
        card: [family: :ISAM, model: "EBLT48", technology: :adsl2Plus],
        ports: [first: 1, last: 48, assignable_type: "ADSL2+"]
      ]

      {:ok, card} = Servo.define_card(card, %{characteristic_value_updates: updates})
      {:ok, card} = Servo.lifecycle_card(card, %{lifecycle_state: :installed})

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

      assert [
               %Diffo.Unknown{
                 world: Diffo.Test.Instance.AccessService,
                 reason: :role_not_declared,
                 context: %{source_id: source_id, role: :location}
               }
             ] = service.primary

      assert source_id == card.id
    end
  end

  describe "inherited_party — Diffo.Unknown emission" do
    test "emits %Diffo.Unknown{reason: :role_not_declared} when reached source has no PartyRef at the source_role" do
      # Symmetric to the inherited_place case: source is reached via :primary
      # but carries no PartyRef at `:provider` (the source_role declared on
      # AccessService's inherited_party :owner declaration).
      {:ok, card} = Servo.build_card(%{})

      updates = [
        card: [family: :ISAM, model: "EBLT48", technology: :adsl2Plus],
        ports: [first: 1, last: 48, assignable_type: "ADSL2+"]
      ]

      {:ok, card} = Servo.define_card(card, %{characteristic_value_updates: updates})
      {:ok, card} = Servo.lifecycle_card(card, %{lifecycle_state: :installed})

      {:ok, service} = Servo.build_access_service(%{})

      {:ok, _card} =
        Servo.assign_port(card, %{
          assignment: %Assignment{
            assignee_id: service.id,
            operation: :auto_assign,
            alias: :primary
          }
        })

      service = Ash.load!(service, [:owner], domain: Servo)

      assert [
               %Diffo.Unknown{
                 world: Diffo.Test.Instance.AccessService,
                 reason: :role_not_declared,
                 context: %{source_id: source_id, role: :provider}
               }
             ] = service.owner

      assert source_id == card.id
    end

    test "no assignment still returns empty list for inherited_party (Unknown reserved for 'tried and couldn't')" do
      {:ok, service} = Servo.build_access_service(%{})

      service = Ash.load!(service, [:owner], domain: Servo)

      assert service.owner == []
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
      {:ok, card} = Servo.lifecycle_card(card, %{lifecycle_state: :installed})

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

  describe "inherited_characteristic — forward assignment to assignees (read rename)" do
    test "shelf surfaces the :card characteristic of every CardInstance assigned via :slot" do
      {:ok, shelf} = Diffo.Test.Parties.build_shelf_with_installer()

      shelf_updates = [
        shelf: [family: :ISAM, model: "EBLT48", technology: :adsl2Plus],
        slots: [first: 1, last: 16, assignable_type: "Slot"]
      ]

      {:ok, shelf} = Servo.define_shelf(shelf, %{characteristic_value_updates: shelf_updates})
      {:ok, shelf} = Servo.lifecycle_shelf(shelf, %{lifecycle_state: :installed})

      updates = [
        card: [family: :ISAM, model: "EBLT48", technology: :adsl2Plus],
        ports: [first: 1, last: 48, assignable_type: "ADSL2+"]
      ]

      {:ok, card_a} = Servo.build_card(%{})
      {:ok, card_a} = Servo.define_card(card_a, %{characteristic_value_updates: updates})
      {:ok, card_a} = Servo.lifecycle_card(card_a, %{lifecycle_state: :installed})

      {:ok, card_b} = Servo.build_card(%{})
      {:ok, card_b} = Servo.define_card(card_b, %{characteristic_value_updates: updates})
      {:ok, card_b} = Servo.lifecycle_card(card_b, %{lifecycle_state: :installed})

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

    test "shelf with no slot assignees yields empty forward-assignment inheritance" do
      {:ok, shelf} = Diffo.Test.Parties.build_shelf_with_installer()

      shelf = Ash.load!(shelf, [:assigned_cards], domain: Servo)

      assert shelf.assigned_cards == []
    end
  end

  describe "JSON surfacing (#173) — inherited values appear in TMF arrays" do
    test "inherited_place surfaces into the place array on encode" do
      place =
        Diffo.Provider.create_place!(:GeographicSite, %{
          id: "LOC-TEST-JSON-001",
          name: "Test Exchange"
        })

      {:ok, card} = Servo.build_card(%{})

      updates = [
        card: [family: :ISAM, model: "EBLT48", technology: :adsl2Plus],
        ports: [first: 1, last: 48, assignable_type: "ADSL2+"]
      ]

      {:ok, card} = Servo.define_card(card, %{characteristic_value_updates: updates})
      {:ok, card} = Servo.lifecycle_card(card, %{lifecycle_state: :installed})

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

      encoded =
        service.id
        |> reload_with([:primary])
        |> Jason.encode!()
        |> Jason.decode!()

      # Surfaced as a simulated PlaceRef: carries the declaration role ("primary")
      # and the inherited place's flattened identity, with no backing ref node.
      assert [
               %{
                 "id" => "LOC-TEST-JSON-001",
                 "role" => "primary",
                 "@type" => "GeographicSite"
               }
             ] = encoded["place"]
    end

    test "inherited_party surfaces into the relatedParty array as a simulated PartyRef" do
      party =
        Diffo.Provider.create_party!(:Organization, %{id: "ORG-TEST-JSON-1", name: "Test Org"})

      {:ok, card} = Servo.build_card(%{})

      updates = [
        card: [family: :ISAM, model: "EBLT48", technology: :adsl2Plus],
        ports: [first: 1, last: 48, assignable_type: "ADSL2+"]
      ]

      {:ok, card} = Servo.define_card(card, %{characteristic_value_updates: updates})
      {:ok, card} = Servo.lifecycle_card(card, %{lifecycle_state: :installed})

      Diffo.Provider.create_party_ref!(%{
        instance_id: card.id,
        role: :provider,
        party_id: party.id
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

      encoded =
        service.id
        |> reload_with([:owner])
        |> Jason.encode!()
        |> Jason.decode!()

      assert [
               %{"id" => "ORG-TEST-JSON-1", "role" => "owner", "@type" => "Organization"}
             ] = encoded["relatedParty"]
    end

    test "inherited_characteristic surfaces into the serviceCharacteristic array on encode" do
      {:ok, card} = Servo.build_card(%{})

      updates = [
        card: [family: :ISAM, model: "EBLT48", technology: :adsl2Plus],
        ports: [first: 1, last: 48, assignable_type: "ADSL2+"]
      ]

      {:ok, card} = Servo.define_card(card, %{characteristic_value_updates: updates})
      {:ok, card} = Servo.lifecycle_card(card, %{lifecycle_state: :installed})

      {:ok, service} = Servo.build_access_service(%{})

      {:ok, _card} =
        Servo.assign_port(card, %{
          assignment: %Assignment{
            assignee_id: service.id,
            operation: :auto_assign,
            alias: :primary
          }
        })

      encoded =
        service.id
        |> reload_with([:card])
        |> Jason.encode!()
        |> Jason.decode!()

      # The inherited :card characteristic must actually surface — asserting the
      # concrete value, not merely "some entry with a name" (AccessService declares no
      # typed characteristic, so a lax check would pass even if nothing surfaced).
      assert [%{"name" => "card", "value" => value}] = encoded["serviceCharacteristic"]
      assert value["family"] == "ISAM"
      assert value["model"] == "EBLT48"
    end

    test "Diffo.Unknown sentinels are filtered off the wire" do
      # Card assigned via :primary but with no PlaceRef at :location — the
      # inherited_place calc yields a %Diffo.Unknown{}, which must not surface.
      {:ok, card} = Servo.build_card(%{})

      updates = [
        card: [family: :ISAM, model: "EBLT48", technology: :adsl2Plus],
        ports: [first: 1, last: 48, assignable_type: "ADSL2+"]
      ]

      {:ok, card} = Servo.define_card(card, %{characteristic_value_updates: updates})
      {:ok, card} = Servo.lifecycle_card(card, %{lifecycle_state: :installed})

      {:ok, service} = Servo.build_access_service(%{})

      {:ok, _card} =
        Servo.assign_port(card, %{
          assignment: %Assignment{
            assignee_id: service.id,
            operation: :auto_assign,
            alias: :primary
          }
        })

      encoded =
        service.id
        |> reload_with([:primary])
        |> Jason.encode!()
        |> Jason.decode!()

      refute Map.has_key?(encoded, "place")
    end

    test "not loading the inherited calc leaves the array untouched" do
      {:ok, service} = Servo.build_access_service(%{})

      encoded =
        service.id
        |> reload_with([])
        |> Jason.encode!()
        |> Jason.decode!()

      refute Map.has_key?(encoded, "place")
    end
  end

  # Regression for #202. The earlier surfacing test above uses AccessService, which
  # declares *no* typed characteristic — so the base fragment never rebuilds the
  # array and nothing could clobber the surfaced value, masking the bug. The clobber
  # only bites when typed and inherited characteristics share one array: the surfacing
  # step (prepended, pre-fix) ran *before* the fragment built the array from the typed
  # characteristics, and the fragment then overwrote it. ShelfInstance is the real
  # shape — typed :shelf plus inherited_characteristic :assigned_cards (forward :slot).
  describe "JSON surfacing (#202) — typed and inherited characteristics coexist in one array" do
    test "resourceCharacteristic carries both the typed shelf characteristic and the surfaced assignee cards" do
      {:ok, shelf} = Diffo.Test.Parties.build_shelf_with_installer()

      shelf_updates = [
        shelf: [family: :ISAM, model: "EBLT48", technology: :adsl2Plus],
        slots: [first: 1, last: 16, assignable_type: "Slot"]
      ]

      {:ok, shelf} = Servo.define_shelf(shelf, %{characteristic_value_updates: shelf_updates})
      {:ok, shelf} = Servo.lifecycle_shelf(shelf, %{lifecycle_state: :installed})

      card_updates = [
        card: [family: :ISAM, model: "EBLT48", technology: :adsl2Plus],
        ports: [first: 1, last: 48, assignable_type: "ADSL2+"]
      ]

      {:ok, card_a} = Servo.build_card(%{})
      {:ok, card_a} = Servo.define_card(card_a, %{characteristic_value_updates: card_updates})
      {:ok, card_a} = Servo.lifecycle_card(card_a, %{lifecycle_state: :installed})

      {:ok, card_b} = Servo.build_card(%{})
      {:ok, card_b} = Servo.define_card(card_b, %{characteristic_value_updates: card_updates})
      {:ok, card_b} = Servo.lifecycle_card(card_b, %{lifecycle_state: :installed})

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

      encoded =
        shelf
        |> Ash.load!([:assigned_cards], domain: Servo)
        |> Jason.encode!()
        |> Jason.decode!()

      chars = encoded["resourceCharacteristic"] || []

      # The shelf's own typed characteristic survives — the fragment still builds it.
      assert Enum.any?(chars, &(&1["name"] == "shelf"))

      # And the reverse-inherited :assigned_cards surfaced *alongside* it, one entry
      # per slot assignee. Pre-fix (#202) the prepended surfacing step ran before the
      # fragment built the array, and the fragment then clobbered these to nothing.
      card_chars = Enum.filter(chars, &(&1["name"] == "card"))
      assert length(card_chars) == 2

      assert Enum.all?(card_chars, fn c ->
               c["value"]["family"] == "ISAM" and c["value"]["model"] == "EBLT48"
             end)
    end
  end

  defp reload_with(id, loads) do
    Diffo.Test.Instance.AccessService
    |> Ash.get!(id, domain: Servo)
    |> Ash.load!(loads, domain: Servo)
  end
end
