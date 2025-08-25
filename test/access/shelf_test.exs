defmodule Diffo.Access.ShelfTest do
  @moduledoc false
  use ExUnit.Case
  alias Diffo.Provider
  alias Diffo.Provider.Specification
  alias Diffo.Provider.Characteristic
  alias Diffo.Provider.Instance.Place
  alias Diffo.Provider.Instance.Party
  alias Diffo.Provider.Instance.Relationship
  alias Diffo.Access
  alias Diffo.Access.Shelf
  alias Diffo.Access.Card

  setup_all do
    AshNeo4j.BoltxHelper.start()
  end

  setup do
    on_exit(fn ->
      AshNeo4j.Neo4jHelper.delete_all()
    end)
  end

  describe "build shelf" do
    test "create a shelf" do
      places = [create_esa_place()]
      parties = [create_provider_party()]

      {:ok, shelf} = Access.build_shelf(%{places: places, parties: parties})

      # check the instance is a Shelf
      assert is_struct(shelf, Shelf)

      # check specification resource enrichment and node relationship
      refute is_nil(shelf.specification_id)
      assert is_struct(shelf.specification, Specification)

      assert AshNeo4j.Neo4jHelper.nodes_relate_how?(
               :Instance,
               %{uuid: shelf.id},
               :Specification,
               %{uuid: shelf.specification_id},
               :SPECIFIED_BY,
               :outgoing
             )

      # check characteristic resource enrichment and node relationships
      assert is_list(shelf.characteristics)
      assert length(shelf.characteristics) == 1

      Enum.each(shelf.characteristics, fn characteristic ->
        assert is_struct(characteristic, Characteristic)

        assert AshNeo4j.Neo4jHelper.nodes_relate_how?(
                 :Instance,
                 %{uuid: shelf.id},
                 :Characteristic,
                 %{uuid: characteristic.id},
                 :HAS,
                 :outgoing
               )
      end)

      Diffo.Support.PlacesTest.check_places(places, shelf)
      Diffo.Support.PartiesTest.check_parties(parties, shelf)

      encoding = Jason.encode!(shelf) |> Diffo.Util.summarise_dates()

      assert encoding ==
               ~s({\"id\":\"#{shelf.id}",\"href\":\"resourceInventoryManagement/v4/resource/shelf/#{shelf.id}",\"category\":\"Network Resource\",\"resourceSpecification\":{\"id\":\"ef016d85-9dbd-429c-84da-1df56cc7dda5\",\"href\":\"resourceCatalogManagement/v4/resourceSpecification/ef016d85-9dbd-429c-84da-1df56cc7dda5\",\"name\":\"shelf\",\"version\":\"v1.0.0\"},\"resourceCharacteristic\":[{\"name\":\"shelf\",\"value\":{}}],\"place\":[{\"id\":\"DONC-0001\",\"href\":\"place/telstra/DONC-0001\",\"name\":\"esaId\",\"role\":\"ServingArea\",\"@referredType\":\"GeographicLocation\",\"@type\":\"PlaceRef\"}],\"relatedParty\":[{\"id\":\"Access\",\"name\":\"organizationId\",\"role\":\"Provider\",\"@referredType\":\"Organization\",\"@type\":\"PartyRef\"}]})
    end
  end

  test "relate a line card" do
    places = [create_esa_place()]
    parties = [create_provider_party()]

    {:ok, shelf} = Access.build_shelf(%{places: places, parties: parties})

    cards = [create_card()]
    {:ok, shelf} = Access.relate_cards(%{relationships: cards})
  end

  defp create_card do
    card =
      Access.build_card!(%{name: "dsl line card"})

    %Relationship{id: card.id, direction: :forward, type: :contains, alias: :slot0}
  end

  defp create_esa_place do
    esa =
      Provider.create_place!(%{
        id: "DONC-0001",
        name: :esaId,
        href: "place/telstra/DONC-0001",
        referredType: :GeographicLocation
      })

    %Place{id: esa.id, role: :ServingArea}
  end

  defp create_provider_party do
    provider =
      Provider.create_party!(%{
        id: "Access",
        name: :organizationId,
        referredType: :Organization
      })

    %Party{id: provider.id, role: :Provider}
  end
end
