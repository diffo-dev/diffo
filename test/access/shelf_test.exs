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
  alias Diffo.Access.Assignment
  alias Diffo.Test.Characteristics

  setup_all do
    AshNeo4j.BoltxHelper.start()
  end

  setup do
    on_exit(fn ->
      :ok #AshNeo4j.Neo4jHelper.delete_all()
    end)
  end

  describe "build shelf" do
    test "create a shelf" do
      places = [create_esa_place()]
      parties = [create_provider_party()]

      {:ok, shelf} = Access.build_shelf(%{name: "QDONC-0001", places: places, parties: parties})

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
      assert length(shelf.characteristics) == 2

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

      Diffo.Test.Places.check_places(places, shelf)
      Diffo.Test.Parties.check_parties(parties, shelf)

      encoding = Jason.encode!(shelf) |> Diffo.Util.summarise_dates()

      assert encoding ==
               ~s({\"id\":\"#{shelf.id}",\"href\":\"resourceInventoryManagement/v4/resource/shelf/#{shelf.id}",\"category\":\"Network Resource\",\"name\":\"QDONC-0001\",\"resourceSpecification\":{\"id\":\"ef016d85-9dbd-429c-84da-1df56cc7dda5\",\"href\":\"resourceCatalogManagement/v4/resourceSpecification/ef016d85-9dbd-429c-84da-1df56cc7dda5\",\"name\":\"shelf\",\"version\":\"v1.0.0\"},\"resourceCharacteristic\":[{\"name\":\"shelf\",\"value\":{}},{\"name\":\"slots\",\"value\":{\"first\":0,\"last\":0,\"free\":0,\"algorithm\":\"lowest\"}}],\"place\":[{\"id\":\"DONC-0001\",\"href\":\"place/telstra/DONC-0001\",\"name\":\"esaId\",\"role\":\"ServingArea\",\"@referredType\":\"GeographicLocation\",\"@type\":\"PlaceRef\"}],\"relatedParty\":[{\"id\":\"Access\",\"name\":\"organizationId\",\"role\":\"Provider\",\"@referredType\":\"Organization\",\"@type\":\"PartyRef\"}]})
    end
  end

  test "define shelf" do
    places = [create_esa_place()]
    parties = [create_provider_party()]
    {:ok, shelf} = Access.build_shelf(%{name: "QDONC-0001", places: places, parties: parties})

    updates = [
      shelf: [name: "QDONC-1001", family: :ISAM, model: "ISAM7330", technology: :DSLAM],
      slots: [first: 1, last: 10, free: 10, type: "LineCard"]
    ]

    {:ok, shelf} = Access.define_shelf(shelf, %{characteristic_value_updates: updates})

    encoding = Jason.encode!(shelf) |> Diffo.Util.summarise_dates()

    assert encoding ==
              ~s({\"id\":\"#{shelf.id}",\"href\":\"resourceInventoryManagement/v4/resource/shelf/#{shelf.id}",\"category\":\"Network Resource\",\"name\":\"QDONC-0001\",\"resourceSpecification\":{\"id\":\"ef016d85-9dbd-429c-84da-1df56cc7dda5\",\"href\":\"resourceCatalogManagement/v4/resourceSpecification/ef016d85-9dbd-429c-84da-1df56cc7dda5\",\"name\":\"shelf\",\"version\":\"v1.0.0\"},\"resourceCharacteristic\":[{\"name\":\"shelf\",\"value\":{\"name\":\"QDONC-1001\",\"family\":\"ISAM\",\"model\":\"ISAM7330\",\"technology\":\"DSLAM\"}},{\"name\":\"slots\",\"value\":{\"first\":1,\"last\":10,\"free\":10,\"type\":\"LineCard\",\"algorithm\":\"lowest\"}}],\"place\":[{\"id\":\"DONC-0001\",\"href\":\"place/telstra/DONC-0001\",\"name\":\"esaId\",\"role\":\"ServingArea\",\"@referredType\":\"GeographicLocation\",\"@type\":\"PlaceRef\"}],\"relatedParty\":[{\"id\":\"Access\",\"name\":\"organizationId\",\"role\":\"Provider\",\"@referredType\":\"Organization\",\"@type\":\"PartyRef\"}]})
  end

  test "relate common cards" do
    places = [create_esa_place()]
    parties = [create_provider_party()]

    {:ok, shelf} = Access.build_shelf(%{places: places, parties: parties})

    cards = create_common_cards()


    {:ok, shelf} = Access.relate_cards(shelf, %{relationships: cards})

    encoding = Jason.encode!(shelf) |> Diffo.Util.summarise_dates()

    [card0, card1, card2, card3] = cards

    assert encoding ==
             ~s({\"id\":\"#{shelf.id}",\"href\":\"resourceInventoryManagement/v4/resource/shelf/#{shelf.id}",\"category\":\"Network Resource\",\"resourceSpecification\":{\"id\":\"ef016d85-9dbd-429c-84da-1df56cc7dda5\",\"href\":\"resourceCatalogManagement/v4/resourceSpecification/ef016d85-9dbd-429c-84da-1df56cc7dda5\",\"name\":\"shelf\",\"version\":\"v1.0.0\"},\"resourceRelationship\":[{\"type\":\"contains\",\"resource\":{\"id\":\"#{card0.id}\",\"href\":null}},{\"type\":\"contains\",\"resource\":{\"id\":\"#{card1.id}\",\"href\":null}},{\"type\":\"contains\",\"resource\":{\"id\":\"#{card2.id}\",\"href\":null}},{\"type\":\"contains\",\"resource\":{\"id\":\"#{card3.id}\",\"href\":null}}],\"resourceCharacteristic\":[{\"name\":\"shelf\",\"value\":{}},{\"name\":\"slots\",\"value\":{\"first\":0,\"last\":0,\"free\":0,\"algorithm\":\"lowest\"}}],\"place\":[{\"id\":\"DONC-0001\",\"href\":\"place/telstra/DONC-0001\",\"name\":\"esaId\",\"role\":\"ServingArea\",\"@referredType\":\"GeographicLocation\",\"@type\":\"PlaceRef\"}],\"relatedParty\":[{\"id\":\"Access\",\"name\":\"organizationId\",\"role\":\"Provider\",\"@referredType\":\"Organization\",\"@type\":\"PartyRef\"}]})
  end

  test "auto assign line cards" do
    places = [create_esa_place()]
    parties = [create_provider_party()]

    {:ok, shelf} = Access.build_shelf(%{name: "QDONC-0001", places: places, parties: parties})

    updates = [
      shelf: [name: "QDONC-1001", family: :ISAM, model: "ISAM7330", technology: :DSLAM],
      slots: [first: 1, last: 10, free: 10, type: "LineCard"]
    ]

    {:ok, shelf} = Access.define_shelf(shelf, %{characteristic_value_updates: updates})

    line_card1 = create_line_card("lc1")
    {:ok, shelf} = Access.assign_slot(shelf, %{assignment: line_card1})
    line_card2 = create_line_card("lc2")
    {:ok, shelf} = Access.assign_slot(shelf, %{assignment: line_card2})

    Characteristics.check_values([slots: [free: 8]], shelf)

    encoding = Jason.encode!(shelf) |> Diffo.Util.summarise_dates()

    lc1 = line_card1.assignee_id
    lc2 = line_card2.assignee_id

    assert encoding ==
             ~s({\"id\":\"#{shelf.id}",\"href\":\"resourceInventoryManagement/v4/resource/shelf/#{shelf.id}",\"category\":\"Network Resource\",\"name\":\"QDONC-0001\",\"resourceSpecification\":{\"id\":\"ef016d85-9dbd-429c-84da-1df56cc7dda5\",\"href\":\"resourceCatalogManagement/v4/resourceSpecification/ef016d85-9dbd-429c-84da-1df56cc7dda5\",\"name\":\"shelf\",\"version\":\"v1.0.0\"},\"resourceRelationship\":[{\"type\":\"assignedTo\",\"resource\":{\"id\":\"#{lc1}\",\"href\":null},\"resourceRelationshipCharacteristic\":[{\"name\":\"slot\",\"value\":1}]},{\"type\":\"assignedTo\",\"resource\":{\"id\":\"#{lc2}\",\"href\":null},\"resourceRelationshipCharacteristic\":[{\"name\":\"slot\",\"value\":2}]}],\"resourceCharacteristic\":[{\"name\":\"shelf\",\"value\":{\"name\":\"QDONC-1001\",\"family\":\"ISAM\",\"model\":\"ISAM7330\",\"technology\":\"DSLAM\"}},{\"name\":\"slots\",\"value\":{\"first\":1,\"last\":10,\"free\":8,\"type\":\"LineCard\",\"algorithm\":\"lowest\"}}],\"place\":[{\"id\":\"DONC-0001\",\"href\":\"place/telstra/DONC-0001\",\"name\":\"esaId\",\"role\":\"ServingArea\",\"@referredType\":\"GeographicLocation\",\"@type\":\"PlaceRef\"}],\"relatedParty\":[{\"id\":\"Access\",\"name\":\"organizationId\",\"role\":\"Provider\",\"@referredType\":\"Organization\",\"@type\":\"PartyRef\"}]})
  end

  defp create_common_cards() do
    psu1 = create_common_card("psu1")
    psu2 = create_common_card("psu2")
    transport1 = create_common_card("transport1")
    transport2 = create_common_card("transport2")
    [psu1, psu2, transport1, transport2]
  end

  defp create_line_card(name) do
    card =
      Access.build_card!(%{name: "#{name}"})

    %Assignment{assignee_id: card.id, operation: :auto_assign}
  end

  defp create_common_card(name) do
    card =
      Access.build_card!(%{name: "#{name}"})

    %Relationship{id: card.id, direction: :forward, type: :contains}
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
