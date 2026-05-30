# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.RefDispatcherTest do
  @moduledoc """
  Tests for the polymorphic-source ref dispatcher on `Diffo.Provider`.

  Covers `PlaceRef` and `PartyRef` create + list patterns:

    * Tagged-tuple source forms (`{:instance, id}`, `{:party, id}`, `{:place, id}`)
    * Struct source forms (auto-dispatched via the known struct module)
    * Intent-based reads (`list_*_from`, `list_*_targeting`)
    * Schema unchanged — the underlying FK columns are still set; the dispatcher
      just unpacks the source tag.
  """
  use ExUnit.Case, async: true
  @moduletag :provider_only

  setup do
    AshNeo4j.Sandbox.checkout()
    on_exit(&AshNeo4j.Sandbox.rollback/0)
  end

  describe "create_place_ref!/1 — tagged-tuple source" do
    test "creates with {:instance, id} source" do
      spec = Diffo.Provider.create_specification!(%{name: "testRefDispTagInst"})
      instance = Diffo.Test.create_instance!(%{specified_by: spec.id})

      place =
        Diffo.Provider.create_place!(:GeographicSite, %{
          id: "RDT-INST-PLACE",
          name: "Place"
        })

      ref =
        Diffo.Provider.create_place_ref!(%{
          role: :location,
          source: {:instance, instance.id},
          target: place.id
        })

      assert ref.role == :location
      assert ref.instance_id == instance.id
      assert ref.place_id == place.id
      assert is_nil(ref.party_id)
      assert is_nil(ref.source_place_id)
    end

    test "creates with {:place, id} source" do
      source_place =
        Diffo.Provider.create_place!(:GeographicSite, %{
          id: "RDT-SRC-PLACE",
          name: "Source"
        })

      target_place =
        Diffo.Provider.create_place!(:GeographicAddress, %{
          id: "RDT-TGT-ADDR",
          name: "Target"
        })

      ref =
        Diffo.Provider.create_place_ref!(%{
          role: :address,
          source: {:place, source_place.id},
          target: target_place.id
        })

      assert ref.source_place_id == source_place.id
      assert ref.place_id == target_place.id
      assert is_nil(ref.instance_id)
      assert is_nil(ref.party_id)
    end
  end

  describe "create_place_ref!/1 — struct source" do
    test "creates with an Instance struct source" do
      spec = Diffo.Provider.create_specification!(%{name: "testRefDispStructInst"})
      instance = Diffo.Test.create_instance!(%{specified_by: spec.id})

      place =
        Diffo.Provider.create_place!(:GeographicSite, %{
          id: "RDT-STRUCT-PLACE",
          name: "Place"
        })

      ref =
        Diffo.Provider.create_place_ref!(%{
          role: :location,
          source: instance,
          target: place
        })

      assert ref.instance_id == instance.id
      assert ref.place_id == place.id
    end

    test "creates with a typed Place subtype struct as source (cascade leaf)" do
      source_place =
        Diffo.Provider.create_place!(:GeographicSite, %{
          id: "RDT-CASCADE-SRC",
          name: "Source Site"
        })

      target_place =
        Diffo.Provider.create_place!(:GeographicAddress, %{
          id: "RDT-CASCADE-TGT",
          name: "Target Address"
        })

      ref =
        Diffo.Provider.create_place_ref!(%{
          role: :address,
          source: source_place,
          target: target_place
        })

      assert ref.source_place_id == source_place.id
      assert ref.place_id == target_place.id
    end
  end

  describe "list_place_refs_from/1" do
    test "lists by tagged-tuple instance source" do
      spec = Diffo.Provider.create_specification!(%{name: "testRefDispListFrom"})
      instance = Diffo.Test.create_instance!(%{specified_by: spec.id})

      place_a =
        Diffo.Provider.create_place!(:GeographicSite, %{id: "RDT-LF-A", name: "A"})

      place_b =
        Diffo.Provider.create_place!(:GeographicSite, %{id: "RDT-LF-B", name: "B"})

      Diffo.Provider.create_place_ref!(%{
        role: :loc1,
        source: {:instance, instance.id},
        target: place_a.id
      })

      Diffo.Provider.create_place_ref!(%{
        role: :loc2,
        source: {:instance, instance.id},
        target: place_b.id
      })

      refs = Diffo.Provider.list_place_refs_from({:instance, instance.id})

      target_ids = refs |> Enum.map(& &1.place_id) |> Enum.sort()
      assert target_ids == Enum.sort([place_a.id, place_b.id])
    end

    test "lists by instance struct source" do
      spec = Diffo.Provider.create_specification!(%{name: "testRefDispStructList"})
      instance = Diffo.Test.create_instance!(%{specified_by: spec.id})

      place =
        Diffo.Provider.create_place!(:GeographicSite, %{id: "RDT-SL-P", name: "P"})

      Diffo.Provider.create_place_ref!(%{
        role: :location,
        source: instance,
        target: place
      })

      refs = Diffo.Provider.list_place_refs_from(instance)
      assert length(refs) == 1
      assert hd(refs).place_id == place.id
    end
  end

  describe "list_place_refs_targeting/1" do
    test "lists refs whose target_id matches a string id" do
      spec = Diffo.Provider.create_specification!(%{name: "testRefDispTargeting"})
      instance = Diffo.Test.create_instance!(%{specified_by: spec.id})

      place =
        Diffo.Provider.create_place!(:GeographicSite, %{id: "RDT-TG-P", name: "P"})

      Diffo.Provider.create_place_ref!(%{
        role: :location,
        source: instance,
        target: place.id
      })

      refs = Diffo.Provider.list_place_refs_targeting(place.id)
      assert length(refs) == 1
      assert hd(refs).instance_id == instance.id
    end

    test "lists refs targeting a place struct" do
      spec = Diffo.Provider.create_specification!(%{name: "testRefDispTargetingStruct"})
      instance = Diffo.Test.create_instance!(%{specified_by: spec.id})

      place =
        Diffo.Provider.create_place!(:GeographicSite, %{id: "RDT-TGS-P", name: "P"})

      Diffo.Provider.create_place_ref!(%{
        role: :location,
        source: instance,
        target: place
      })

      refs = Diffo.Provider.list_place_refs_targeting(place)
      assert length(refs) == 1
    end
  end

  describe "create_party_ref!/1 — same patterns symmetric to PlaceRef" do
    test "creates a PartyRef with tagged-tuple instance source" do
      spec = Diffo.Provider.create_specification!(%{name: "testRefDispPrTag"})
      instance = Diffo.Test.create_instance!(%{specified_by: spec.id})
      party = Diffo.Provider.create_party!(:Organization, %{id: "RDT-PR-PARTY", name: "Org"})

      ref =
        Diffo.Provider.create_party_ref!(%{
          role: :facilitator,
          source: {:instance, instance.id},
          target: party.id
        })

      assert ref.instance_id == instance.id
      assert ref.party_id == party.id
      assert is_nil(ref.place_id)
      assert is_nil(ref.source_party_id)
    end

    test "creates a PartyRef with party struct source (party-to-party)" do
      source_party =
        Diffo.Provider.create_party!(:Organization, %{id: "RDT-PR-SRC", name: "Source Party"})

      target_party =
        Diffo.Provider.create_party!(:Organization, %{id: "RDT-PR-TGT", name: "Target Party"})

      ref =
        Diffo.Provider.create_party_ref!(%{
          role: :subsidiary,
          source: source_party,
          target: target_party
        })

      assert ref.source_party_id == source_party.id
      assert ref.party_id == target_party.id
    end
  end

  describe "list_party_refs_from/1 + list_party_refs_targeting/1" do
    test "list_party_refs_from with tagged tuple" do
      spec = Diffo.Provider.create_specification!(%{name: "testRefDispPrlf"})
      instance = Diffo.Test.create_instance!(%{specified_by: spec.id})

      party_a = Diffo.Provider.create_party!(:Organization, %{id: "RDT-PRLF-A", name: "A"})
      party_b = Diffo.Provider.create_party!(:Organization, %{id: "RDT-PRLF-B", name: "B"})

      Diffo.Provider.create_party_ref!(%{
        role: :role1,
        source: {:instance, instance.id},
        target: party_a.id
      })

      Diffo.Provider.create_party_ref!(%{
        role: :role2,
        source: {:instance, instance.id},
        target: party_b.id
      })

      refs = Diffo.Provider.list_party_refs_from({:instance, instance.id})
      target_ids = refs |> Enum.map(& &1.party_id) |> Enum.sort()
      assert target_ids == Enum.sort([party_a.id, party_b.id])
    end

    test "list_party_refs_targeting with party struct" do
      spec = Diffo.Provider.create_specification!(%{name: "testRefDispPrtg"})
      instance = Diffo.Test.create_instance!(%{specified_by: spec.id})

      party = Diffo.Provider.create_party!(:Organization, %{id: "RDT-PRTG-P", name: "P"})

      Diffo.Provider.create_party_ref!(%{
        role: :facilitator,
        source: instance,
        target: party
      })

      refs = Diffo.Provider.list_party_refs_targeting(party)
      assert length(refs) == 1
    end
  end

  describe "unknown struct kinds" do
    test "raises ArgumentError when source struct module isn't recognised" do
      assert_raise ArgumentError, ~r/unknown source kind/, fn ->
        Diffo.Provider.create_place_ref!(%{
          role: :role,
          source: %URI{},
          target: "X"
        })
      end
    end
  end
end
