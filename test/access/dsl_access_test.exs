defmodule Diffo.Access.DslAccessTest do
  @moduledoc false
  use ExUnit.Case
  alias Diffo.Provider
  alias Diffo.Provider.Specification
  alias Diffo.Provider.Feature
  alias Diffo.Provider.Characteristic
  alias Diffo.Provider.Instance.Place
  alias Diffo.Provider.Instance.Party
  alias Diffo.Access
  alias Diffo.Access.DslAccess
  alias Diffo.Support.PartiesTest
  alias Diffo.Support.PlacesTest

  setup_all do
    AshNeo4j.BoltxHelper.start()
  end

  setup do
    on_exit(fn ->
      AshNeo4j.Neo4jHelper.delete_all()
    end)
  end

  describe "service qualification" do
    test "create an initial service for service qualification" do
      parties = create_initial_parties()
      places = [create_initial_place()]

      {:ok, dsl_access} = Access.qualify_dsl(%{parties: parties, places: places})

      # check the instance is a DslAccess
      assert is_struct(dsl_access, DslAccess)

      # check specification resource enrichment and node relationship
      refute is_nil(dsl_access.specification_id)
      assert is_struct(dsl_access.specification, Specification)

      assert AshNeo4j.Neo4jHelper.nodes_relate_how?(
               :Instance,
               %{uuid: dsl_access.id},
               :Specification,
               %{uuid: dsl_access.specification_id},
               :SPECIFIED_BY,
               :outgoing
             )

      # check features resource enrichment and node relationships
      assert is_list(dsl_access.features)
      assert length(dsl_access.features) == 1

      Enum.each(dsl_access.features, fn feature ->
        assert is_struct(feature, Feature)

        assert AshNeo4j.Neo4jHelper.nodes_relate_how?(
                 :Instance,
                 %{uuid: dsl_access.id},
                 :Feature,
                 %{uuid: feature.id},
                 :HAS,
                 :outgoing
               )

        # check feature characteristic resource enrichment and node relationships
        assert is_list(feature.characteristics)
        assert length(feature.characteristics) == 1

        Enum.each(feature.characteristics, fn characteristic ->
          assert is_struct(characteristic, Characteristic)

          assert AshNeo4j.Neo4jHelper.nodes_relate_how?(
                   :Feature,
                   %{uuid: feature.id},
                   :Characteristic,
                   %{uuid: characteristic.id},
                   :HAS,
                   :outgoing
                 )
        end)
      end)

      # check characteristic resource enrichment and node relationships
      assert is_list(dsl_access.characteristics)
      assert length(dsl_access.characteristics) == 4

      Enum.each(dsl_access.characteristics, fn characteristic ->
        assert is_struct(characteristic, Characteristic)

        assert AshNeo4j.Neo4jHelper.nodes_relate_how?(
                 :Instance,
                 %{uuid: dsl_access.id},
                 :Characteristic,
                 %{uuid: characteristic.id},
                 :HAS,
                 :outgoing
               )
      end)

      PartiesTest.check_parties(parties, dsl_access)
      PlacesTest.check_places(places, dsl_access)

      encoding = Jason.encode!(dsl_access) |> Diffo.Util.summarise_dates()

      assert encoding ==
               ~s({\"id\":\"#{dsl_access.id}",\"href\":\"serviceInventoryManagement/v4/service/dslAccess/#{dsl_access.id}\",\"category\":\"Network Service\",\"serviceSpecification\":{\"id\":\"da9b207a-26c3-451d-8abd-0640c6349979\",\"href\":\"serviceCatalogManagement/v4/serviceSpecification/da9b207a-26c3-451d-8abd-0640c6349979\",\"name\":\"dslAccess\",\"version\":\"v1.0.0\"},\"serviceDate\":\"now\",\"state\":\"initial\",\"feature\":[{\"name\":\"dynamic_line_management\",\"isEnabled\":true,\"featureCharacteristic\":[{\"name\":\"constraints\",\"value\":{}}]}],\"serviceCharacteristic\":[{\"name\":\"aggregate_interface\",\"value\":{\"physical_layer\":\"GbE\",\"link_layer\":\"QinQ\",\"svlan_id\":0,\"vpi\":0}},{\"name\":\"circuit\",\"value\":{\"cvlan_id\":0,\"vci\":0,\"encapsulation\":\"IPoE\"}},{\"name\":\"dslam\",\"value\":{\"family\":\"ISAM\",\"technology\":\"eth\"}},{\"name\":\"line\",\"value\":{\"standard\":\"ADSL2plus\"}}],\"place\":[{\"id\":\"1657363\",\"href\":\"place/telstra/1657363\",\"name\":\"addressId\",\"role\":\"CustomerSite\",\"@referredType\":\"GeographicAddress\",\"@type\":\"PlaceRef\"}],\"relatedParty\":[{\"id\":\"IND000000897354\",\"name\":\"individualId\",\"role\":\"Customer\",\"@referredType\":\"Individual\",\"@type\":\"PartyRef\"},{\"id\":\"ORG000000123456\",\"name\":\"organizationId\",\"role\":\"Reseller\",\"@referredType\":\"Organization\",\"@type\":\"PartyRef\"}]})
    end

    test "advance service to feasibilityChecked" do
      initial_parties = create_initial_parties()
      initial_place = create_initial_place()

      {:ok, dsl_access} = Access.qualify_dsl(%{parties: initial_parties, places: [initial_place]})

      esa_place = create_esa_place()

      {:ok, dsl_access} =
        Access.qualify_dsl_result(dsl_access, %{
          service_operating_status: :feasible,
          places: [esa_place]
        })

      # check the instance is a DslAccess
      assert is_struct(dsl_access, DslAccess)

      assert dsl_access.service_state == :feasibilityChecked
      assert dsl_access.service_operating_status == :feasible

      PlacesTest.check_places([initial_place | [esa_place]], dsl_access)

      encoding = Jason.encode!(dsl_access) |> Diffo.Util.summarise_dates()

      assert encoding ==
               ~s({\"id\":\"#{dsl_access.id}",\"href\":\"serviceInventoryManagement/v4/service/dslAccess/#{dsl_access.id}\",\"category\":\"Network Service\",\"serviceSpecification\":{\"id\":\"da9b207a-26c3-451d-8abd-0640c6349979\",\"href\":\"serviceCatalogManagement/v4/serviceSpecification/da9b207a-26c3-451d-8abd-0640c6349979\",\"name\":\"dslAccess\",\"version\":\"v1.0.0\"},\"serviceDate\":\"now\",\"state\":\"feasibilityChecked\",\"operatingStatus\":\"feasible\",\"feature\":[{\"name\":\"dynamic_line_management\",\"isEnabled\":true,\"featureCharacteristic\":[{\"name\":\"constraints\",\"value\":{}}]}],\"serviceCharacteristic\":[{\"name\":\"aggregate_interface\",\"value\":{\"physical_layer\":\"GbE\",\"link_layer\":\"QinQ\",\"svlan_id\":0,\"vpi\":0}},{\"name\":\"circuit\",\"value\":{\"cvlan_id\":0,\"vci\":0,\"encapsulation\":\"IPoE\"}},{\"name\":\"dslam\",\"value\":{\"family\":\"ISAM\",\"technology\":\"eth\"}},{\"name\":\"line\",\"value\":{\"standard\":\"ADSL2plus\"}}],\"place\":[{\"id\":\"1657363\",\"href\":\"place/telstra/1657363\",\"name\":\"addressId\",\"role\":\"CustomerSite\",\"@referredType\":\"GeographicAddress\",\"@type\":\"PlaceRef\"},{\"id\":\"DONC-0001\",\"href\":\"place/telstra/DONC-0001\",\"name\":\"esaId\",\"role\":\"ServingArea\",\"@referredType\":\"GeographicLocation\",\"@type\":\"PlaceRef\"}],\"relatedParty\":[{\"id\":\"IND000000897354\",\"name\":\"individualId\",\"role\":\"Customer\",\"@referredType\":\"Individual\",\"@type\":\"PartyRef\"},{\"id\":\"ORG000000123456\",\"name\":\"organizationId\",\"role\":\"Reseller\",\"@referredType\":\"Organization\",\"@type\":\"PartyRef\"}]})
    end
  end

  describe "service activation" do
    @tag debug: true
    test "design the service" do
      initial_parties = create_initial_parties()
      initial_place = create_initial_place()
      {:ok, dsl_access} = Access.qualify_dsl(%{parties: initial_parties, places: [initial_place]})
      esa_place = create_esa_place()

      {:ok, dsl_access} =
        Access.qualify_dsl_result(dsl_access, %{
          service_operating_status: :feasible,
          places: [esa_place]
        })

      # now we design the circuit, allocating the dslam, slot, port
      # and we allocate the backhaul interface, svlan and cvlan, so can derive the cicuit id

      updates = [
        dslam: [name: QDONC0001, model: ISAM7330],
        aggregate_interface: [name: "eth0", svlan_id: 3108],
        circuit: [cvlan_id: 82],
        line: [slot: 10, port: 5]
      ]

      {:ok, dsl_access} =
        Access.design_dsl_result(dsl_access, %{characteristic_value_updates: updates})

      # check the instance is a DslAccess
      assert is_struct(dsl_access, DslAccess)

      assert dsl_access.service_state == :reserved
      assert dsl_access.service_operating_status == :feasible

      PlacesTest.check_places([initial_place | [esa_place]], dsl_access)

      encoding = Jason.encode!(dsl_access) |> Diffo.Util.summarise_dates()

      assert encoding ==
               ~s({\"id\":\"#{dsl_access.id}",\"href\":\"serviceInventoryManagement/v4/service/dslAccess/#{dsl_access.id}\",\"category\":\"Network Service\",\"serviceSpecification\":{\"id\":\"da9b207a-26c3-451d-8abd-0640c6349979\",\"href\":\"serviceCatalogManagement/v4/serviceSpecification/da9b207a-26c3-451d-8abd-0640c6349979\",\"name\":\"dslAccess\",\"version\":\"v1.0.0\"},\"serviceDate\":\"now\",\"state\":\"reserved\",\"operatingStatus\":\"feasible\",\"feature\":[{\"name\":\"dynamic_line_management\",\"isEnabled\":true,\"featureCharacteristic\":[{\"name\":\"constraints\",\"value\":{}}]}],\"serviceCharacteristic\":[{\"name\":\"aggregate_interface\",\"value\":{\"name\":\"eth0\",\"physical_layer\":\"GbE\",\"link_layer\":\"QinQ\",\"svlan_id\":3108,\"vpi\":0}},{\"name\":\"circuit\",\"value\":{\"cvlan_id\":82,\"vci\":0,\"encapsulation\":\"IPoE\"}},{\"name\":\"dslam\",\"value\":{\"name\":\"QDONC0001\",\"family\":\"ISAM\",\"model\":\"ISAM7330\",\"technology\":\"eth\"}},{\"name\":\"line\",\"value\":{\"port\":5,\"slot\":10,\"standard\":\"ADSL2plus\"}}],\"place\":[{\"id\":\"1657363\",\"href\":\"place/telstra/1657363\",\"name\":\"addressId\",\"role\":\"CustomerSite\",\"@referredType\":\"GeographicAddress\",\"@type\":\"PlaceRef\"},{\"id\":\"DONC-0001\",\"href\":\"place/telstra/DONC-0001\",\"name\":\"esaId\",\"role\":\"ServingArea\",\"@referredType\":\"GeographicLocation\",\"@type\":\"PlaceRef\"}],\"relatedParty\":[{\"id\":\"IND000000897354\",\"name\":\"individualId\",\"role\":\"Customer\",\"@referredType\":\"Individual\",\"@type\":\"PartyRef\"},{\"id\":\"ORG000000123456\",\"name\":\"organizationId\",\"role\":\"Reseller\",\"@referredType\":\"Organization\",\"@type\":\"PartyRef\"}]})
    end
  end

  defp create_initial_place do
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

  defp create_initial_parties do
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

    [%Party{id: individual.id, role: :Customer}, %Party{id: org.id, role: :Reseller}]
  end

end
