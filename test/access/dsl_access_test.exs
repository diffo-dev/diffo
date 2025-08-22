defmodule Diffo.Access.DslAccessTest do
  @moduledoc false
  use ExUnit.Case
  alias Diffo.Provider
  alias Diffo.Provider.Instance.Place
  alias Diffo.Provider.Instance.Party
  alias Diffo.Access
  #alias Diffo.Access.AggregateInterface
  #alias Diffo.Access.Circuit
  #alias Diffo.Access.Dslam
  #alias Diffo.Access.Line
  #alias Diffo.Access.BandwidthProfile
  #alias Diffo.Access.DslAccess.Instance, as: DslAccess


  setup_all do
    AshNeo4j.BoltxHelper.start()
  end

  setup do
    on_exit(fn ->
      :ok #AshNeo4j.Neo4jHelper.delete_all()
    end)
  end

  describe "service qualification" do
    @tag debug: true
    test "create an initial service for service qualification" do
      z_end = Provider.create_place!(%{id: "1657363", name: :addressId, href: "place/telstra/1657363", referredType: :GeographicAddress})
      places = [%Place{id: z_end.id, role: :CustomerSite}]
      individual =
        Provider.create_party!(%{
          id: "IND000000897354",
          name: :individualId,
          referredType: :Individual
        })
      org =
        Provider.create_party!(%{
          id: "ORG000000123456",
          name: :organizationId,
          referredType: :Organization
        })
      parties = [%Party{id: individual.id, role: :Customer}, %Party{id: org.id, role: :Reseller}]

      {:ok, dsl_access} = Access.qualify_dsl(%{parties: parties, places: places})

      # check specification resource enrichment and node relationship
      refute is_nil(dsl_access.specification_id)
      assert is_struct(dsl_access.specification, Diffo.Provider.Specification)
      assert AshNeo4j.Neo4jHelper.nodes_relate_how?(:Instance, %{uuid: dsl_access.id}, :Specification, %{uuid: dsl_access.specification_id}, :SPECIFIES, :incoming)

      # todo check features resource enrichment and node relationships

      # check characteristic resource enrichment and node relationships
      assert is_list(dsl_access.characteristics)
      assert length(dsl_access.characteristics) == 4
      Enum.each(dsl_access.characteristics, fn characteristic ->
        assert is_struct(characteristic, Diffo.Provider.Characteristic)
        assert AshNeo4j.Neo4jHelper.nodes_relate_how?(:Instance, %{uuid: dsl_access.id}, :Characteristic, %{uuid: characteristic.id}, :DEFINES, :incoming)
      end)

      # check parties resource enrichment and node relationships
      assert is_list(dsl_access.parties)
      assert length(dsl_access.parties) == 2
      Enum.each(dsl_access.parties, fn party_ref ->
        assert is_struct(party_ref, Diffo.Provider.PartyRef)
        refute is_nil(party_ref.party_id)
        assert is_struct(party_ref.party, Diffo.Provider.Party)
        assert AshNeo4j.Neo4jHelper.nodes_relate_how?(:Instance, %{uuid: dsl_access.id}, :PartyRef, %{uuid: party_ref.id}, :INVOLVES, :outgoing)
        assert AshNeo4j.Neo4jHelper.nodes_relate_how?(:PartyRef, %{uuid: party_ref.id}, :Party, %{key: party_ref.party_id}, :INVOLVES, :outgoing)
      end)

      # check places resource enrichment and node relationships
      assert is_list(dsl_access.places)
      assert length(dsl_access.places) == 1
      Enum.each(dsl_access.places, fn place_ref ->
        assert is_struct(place_ref, Diffo.Provider.PlaceRef)
        refute is_nil(place_ref.place_id)
        assert is_struct(place_ref.place, Diffo.Provider.Place)
        assert AshNeo4j.Neo4jHelper.nodes_relate_how?(:Instance, %{uuid: dsl_access.id}, :PlaceRef, %{uuid: place_ref.id}, :LOCATES, :incoming)
        assert AshNeo4j.Neo4jHelper.nodes_relate_how?(:PlaceRef, %{uuid: place_ref.id}, :Place, %{key: place_ref.place_id}, :LOCATES, :incoming)
      end)
    end
  end
end
