defmodule Diffo.Access.PathTest do
  @moduledoc false
  use ExUnit.Case
  alias Diffo.Provider
  alias Diffo.Provider.Specification
  alias Diffo.Provider.Characteristic
  alias Diffo.Provider.Instance.Place
  alias Diffo.Provider.Instance.Party
  alias Diffo.Provider.Instance.Relationship
  alias Diffo.Access
  alias Diffo.Access.Path
  alias Diffo.Access.Assignment

  setup_all do
    AshNeo4j.BoltxHelper.start()
  end

  setup do
    on_exit(fn ->
      AshNeo4j.Neo4jHelper.delete_all()
    end)
  end

  describe "build path" do
    test "create a path" do
      places = [create_customer_place(), create_exchange_place(), create_esa_place()]
      parties = [create_provider_party()]

      {:ok, path} =
        Access.build_path(%{name: "82 Rathmullen - DONC", places: places, parties: parties})

      # check the instance is a Path
      assert is_struct(path, Path)

      # check specification resource enrichment and node relationship
      refute is_nil(path.specification_id)
      assert is_struct(path.specification, Specification)

      assert AshNeo4j.Neo4jHelper.nodes_relate_how?(
               :Instance,
               %{uuid: path.id},
               :Specification,
               %{uuid: path.specification_id},
               :SPECIFIED_BY,
               :outgoing
             )

      # check characteristic resource enrichment and node relationships
      assert is_list(path.characteristics)
      assert length(path.characteristics) == 1

      Enum.each(path.characteristics, fn characteristic ->
        assert is_struct(characteristic, Characteristic)

        assert AshNeo4j.Neo4jHelper.nodes_relate_how?(
                 :Instance,
                 %{uuid: path.id},
                 :Characteristic,
                 %{uuid: characteristic.id},
                 :HAS,
                 :outgoing
               )
      end)

      Diffo.Test.Places.check_places(places, path)
      Diffo.Test.Parties.check_parties(parties, path)

      encoding = Jason.encode!(path) |> Diffo.Util.summarise_dates()

      assert encoding ==
               ~s({\"id\":\"#{path.id}",\"href\":\"resourceInventoryManagement/v4/resource/path/#{path.id}",\"category\":\"Network Resource\",\"name\":\"82 Rathmullen - DONC\",\"resourceSpecification\":{\"id\":\"1d507914-8f76-48cb-aa0e-3a8f92951ab0\",\"href\":\"resourceCatalogManagement/v4/resourceSpecification/1d507914-8f76-48cb-aa0e-3a8f92951ab0\",\"name\":\"path\",\"version\":\"v1.0.0\"},\"resourceCharacteristic\":[{\"name\":\"path\",\"value\":{\"sections\":0}}],\"place\":[{\"id\":\"1657363\",\"href\":\"place/telstra/1657363\",\"name\":\"addressId\",\"role\":\"CustomerSite\",\"@referredType\":\"GeographicAddress\",\"@type\":\"PlaceRef\"},{\"id\":\"DONC\",\"href\":\"place/telstra/DONC\",\"name\":\"exchangeId\",\"role\":\"NetworkSite\",\"@referredType\":\"GeographicSite\",\"@type\":\"PlaceRef\"},{\"id\":\"DONC-0001\",\"href\":\"place/telstra/DONC-0001\",\"name\":\"esaId\",\"role\":\"ServingArea\",\"@referredType\":\"GeographicLocation\",\"@type\":\"PlaceRef\"}],\"relatedParty\":[{\"id\":\"Access\",\"name\":\"organizationId\",\"role\":\"Provider\",\"@referredType\":\"Organization\",\"@type\":\"PartyRef\"}]})
    end
  end

  test "define path" do
    places = [create_customer_place(), create_exchange_place(), create_esa_place()]
    parties = [create_provider_party()]

    {:ok, path} =
      Access.build_path(%{name: "82 Rathmullen - DONC", places: places, parties: parties})

    updates = [
      path: [name: "82 Rathmullen - DONC", technology: :copper]
    ]

    {:ok, path} = Access.define_path(path, %{characteristic_value_updates: updates})

    encoding = Jason.encode!(path) |> Diffo.Util.summarise_dates()

    assert encoding ==
             ~s({\"id\":\"#{path.id}",\"href\":\"resourceInventoryManagement/v4/resource/path/#{path.id}",\"category\":\"Network Resource\",\"name\":\"82 Rathmullen - DONC\",\"resourceSpecification\":{\"id\":\"1d507914-8f76-48cb-aa0e-3a8f92951ab0\",\"href\":\"resourceCatalogManagement/v4/resourceSpecification/1d507914-8f76-48cb-aa0e-3a8f92951ab0\",\"name\":\"path\",\"version\":\"v1.0.0\"},\"resourceCharacteristic\":[{\"name\":\"path\",\"value\":{\"name\":\"82 Rathmullen - DONC\",\"sections\":0,\"technology\":\"copper\"}}],\"place\":[{\"id\":\"1657363\",\"href\":\"place/telstra/1657363\",\"name\":\"addressId\",\"role\":\"CustomerSite\",\"@referredType\":\"GeographicAddress\",\"@type\":\"PlaceRef\"},{\"id\":\"DONC\",\"href\":\"place/telstra/DONC\",\"name\":\"exchangeId\",\"role\":\"NetworkSite\",\"@referredType\":\"GeographicSite\",\"@type\":\"PlaceRef\"},{\"id\":\"DONC-0001\",\"href\":\"place/telstra/DONC-0001\",\"name\":\"esaId\",\"role\":\"ServingArea\",\"@referredType\":\"GeographicLocation\",\"@type\":\"PlaceRef\"}],\"relatedParty\":[{\"id\":\"Access\",\"name\":\"organizationId\",\"role\":\"Provider\",\"@referredType\":\"Organization\",\"@type\":\"PartyRef\"}]})
  end

  @tag debug: true
  test "relate cables and dslam" do
    places = [create_customer_place(), create_exchange_place(), create_esa_place()]
    parties = [create_provider_party()]

    {:ok, path} =
      Access.build_path(%{name: "82 Rathmullen - DONC", places: places, parties: parties})

    updates = [
      path: [name: "82 Rathmullen - DONC", technology: :copper]
    ]

    {:ok, path} = Access.define_path(path, %{characteristic_value_updates: updates})

    cables = create_cables(places)

    # now assign a pair from each cable
    _cables =
      Enum.into(cables, [], fn cable ->
        Access.assign_pair!(cable, %{
          assignment: %Assignment{assignee_id: path.id, operation: :auto_assign}
        })
      end)

    # now assign a port from a line card
    [_dslam, line_card] = create_dslam_with_line_card("QDONC-0001", tl(places), parties)

    Access.assign_port!(line_card, %{
      assignment: %Assignment{assignee_id: path.id, operation: :auto_assign}
    })

    # refresh the path loading the reverse relationships explicitly, which should include
    # relationships with cables assigning pairs
    # relationship with line card assigning port

    {:ok, path} = Access.get_path_by_id(path.id, load: [:reverse_relationships])
    assert length(path.reverse_relationships) == 6

    encoding = Jason.encode!(path) |> Diffo.Util.summarise_dates()

    # the reverse relationships are not encoded to json
    assert encoding ==
             ~s({\"id\":\"#{path.id}",\"href\":\"resourceInventoryManagement/v4/resource/path/#{path.id}",\"category\":\"Network Resource\",\"name\":\"82 Rathmullen - DONC\",\"resourceSpecification\":{\"id\":\"1d507914-8f76-48cb-aa0e-3a8f92951ab0\",\"href\":\"resourceCatalogManagement/v4/resourceSpecification/1d507914-8f76-48cb-aa0e-3a8f92951ab0\",\"name\":\"path\",\"version\":\"v1.0.0\"},\"resourceCharacteristic\":[{\"name\":\"path\",\"value\":{\"name\":\"82 Rathmullen - DONC\",\"sections\":0,\"technology\":\"copper\"}}],\"place\":[{\"id\":\"1657363\",\"href\":\"place/telstra/1657363\",\"name\":\"addressId\",\"role\":\"CustomerSite\",\"@referredType\":\"GeographicAddress\",\"@type\":\"PlaceRef\"},{\"id\":\"DONC\",\"href\":\"place/telstra/DONC\",\"name\":\"exchangeId\",\"role\":\"NetworkSite\",\"@referredType\":\"GeographicSite\",\"@type\":\"PlaceRef\"},{\"id\":\"DONC-0001\",\"href\":\"place/telstra/DONC-0001\",\"name\":\"esaId\",\"role\":\"ServingArea\",\"@referredType\":\"GeographicLocation\",\"@type\":\"PlaceRef\"}],\"relatedParty\":[{\"id\":\"Access\",\"name\":\"organizationId\",\"role\":\"Provider\",\"@referredType\":\"Organization\",\"@type\":\"PartyRef\"}]})
  end

  defp create_customer_place do
    z_end =
      Provider.create_place!(%{
        id: "1657363",
        name: :addressId,
        href: "place/telstra/1657363",
        referredType: :GeographicAddress
      })

    %Place{id: z_end.id, role: :CustomerSite}
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

  defp create_exchange_place do
    exchange =
      Provider.create_place!(%{
        id: "DONC",
        name: :exchangeId,
        href: "place/telstra/DONC",
        referredType: :GeographicSite
      })

    %Place{id: exchange.id, role: :NetworkSite}
  end

  defp create_cables(places) do
    [z_end, exchange, _esa] = places
    tie = create_cable("QDONC-0001 line card 1 tie cable", [], [])

    main =
      create_cable(
        "DONC-0001-001 Lawford St main cable",
        [%Relationship{id: tie.id, direction: :forward, type: :connectedTo}],
        [z_end]
      )

    secondary =
      create_cable(
        "DONC-0001-005 North Rathmullen Quad cable",
        [%Relationship{id: main.id, direction: :forward, type: :connectedTo}],
        []
      )

    tertiary =
      create_cable(
        "DONC-0001-013 Rathmullen Quad East cable",
        [%Relationship{id: secondary.id, direction: :forward, type: :connectedTo}],
        []
      )

    lead_in =
      create_cable(
        "82 Rathmullen lead in",
        [%Relationship{id: tertiary.id, direction: :forward, type: :connectedTo}],
        [exchange]
      )

    [tie, main, secondary, tertiary, lead_in]
  end

  defp create_cable(name, relationships, places)
       when is_bitstring(name) and is_list(relationships) and is_list(places) do
    Access.build_cable!(%{name: "#{name}", places: places, relationships: relationships})
  end

  defp create_dslam_with_line_card(name, places, parties) when is_bitstring(name) do
    shelf = Access.build_shelf!(%{name: "#{name}", places: places, parties: parties})
    card = Access.build_card!(%{name: "#{name}"})

    Access.assign_slot!(shelf, %{
      assignment: %Assignment{assignee_id: card.id, operation: :auto_assign}
    })

    [shelf, card]
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
