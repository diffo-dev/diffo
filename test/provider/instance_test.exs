defmodule Diffo.Provider.InstanceTest do
  @moduledoc false
  use ExUnit.Case
  use Diffo.DataCase, async: true

  describe "Diffo.Provider read Instances!" do

    test "list instances" do
      specification = Diffo.Provider.create_specification!(%{name: "firewall"})
      Diffo.Provider.create_instance!(%{specification_id: specification.id})
      Diffo.Provider.create_instance!(%{specification_id: specification.id})
      Diffo.Provider.create_instance!(%{specification_id: specification.id})
      instances = Diffo.Provider.list_instances!()
      assert length(instances) == 3
      # TODO check sorted by href
    end

    test "find instances by specification id" do
      specification = Diffo.Provider.create_specification!(%{name: "firewall"})
      other_specification = Diffo.Provider.create_specification!(%{name: "gateway"})
      Diffo.Provider.create_instance!(%{specification_id: specification.id})
      Diffo.Provider.create_instance!(%{specification_id: specification.id})
      Diffo.Provider.create_instance!(%{specification_id: other_specification.id})
      instances = Diffo.Provider.find_instances_by_specification_id!(specification.id)
      assert length(instances) == 2
      # TODO check sorted by href
    end

    test "find instances by name" do
      specification = Diffo.Provider.create_specification!(%{name: "intrusionMonitor"})
      Diffo.Provider.create_instance!(%{specification_id: specification.id, name: "Westfield Doncaster L1.M1"})
      Diffo.Provider.create_instance!(%{specification_id: specification.id, name: "Westfield Doncaster L2.M3"})
      Diffo.Provider.create_instance!(%{specification_id: specification.id, name: "Westfield Doncaster L2.M4"})
      instances = Diffo.Provider.find_instances_by_name!("Westfield Doncaster L2.M")
      assert length(instances) == 2
      # TODO check sorted by href
    end
  end

  describe "Diffo.Provider create Instances" do

    test "create a service instance - success" do
      specification = Diffo.Provider.create_specification!(%{name: "fibreAccess", description: "Fibre Access Service", category: "connectivity"})
      instance = Diffo.Provider.create_instance!(%{specification_id: specification.id})
      assert Diffo.Uuid.uuid4?(instance.id) == true
      assert instance.type == :service
      assert instance.service_state == :initial
      assert instance.service_operating_status == :unknown
      loaded_instance = Diffo.Provider.get_instance_by_id!(instance.id, load: [:href, :category, :description, :specification])
      assert loaded_instance.category == "connectivity"
      assert loaded_instance.description == "Fibre Access Service"
      assert loaded_instance.href == "serviceInventoryManagement/v4/service/fibreAccess/#{instance.id}"
      assert loaded_instance.specification.id == specification.id
    end

    #TODO fix this test, it is failing as specified_instance_type calculation is not loaded when create validation occurs
    #test "create a resource instance - success" do
    # {:ok, specification} = Diffo.Provider.create_specification(%{name: "copperPath", description: "Copper Path Resource", category: "physical", type: :resourceSpecification})
    #  {:ok, instance} = Diffo.Provider.create_instance(%{specification_id: specification.id, type: :resource})
    #  assert Diffo.Uuid.uuid4?(instance.id) == true
    #  assert instance.type == :resource
    #  {:ok, loaded_instance} = Diffo.Provider.get_instance_by_id(instance.id, load: [:href, :category, :description])
    #  assert loaded_instance.category == "physical"
    #  assert loaded_instance.description == "Copper Path Resource"
    #  assert loaded_instance.href == "resourceInventoryManagement/v4/resource/copperPath/#{instance.id}"
    #  assert loaded_instance.specified_instance.type == :resource
    #end

    test "create a service instance - failure - specification_id invalid" do
      {:error, _specification} = Diffo.Provider.create_instance(%{specification_id: UUID.uuid4()})
    end

    test "create a service instance - failure - type not correct" do
      specification = Diffo.Provider.create_specification!(%{name: "hfcAccess", description: "HFC Access Service", category: "connectivity"})
      {:error, _specification} = Diffo.Provider.create_instance(%{specification_id: specification.id, type: :serviceSpecification})
    end

    # TODO this test is failing
    # test "create a service instance - failure - type mismatch with specification" do
    #   {:ok, specification} = Diffo.Provider.create_specification(%{name: "radioAccess", description: "Radio Access Service", category: "connectivity"})
    #   {:error, _specification} = Diffo.Provider.create_instance(%{specification_id: specification.id, type: :service})
    # end

  end

  describe "Diffo.Provider update Instances" do
    test "cancel an initial service instance - success" do
      specification = Diffo.Provider.create_specification!(%{name: "initialCancel"})
      instance = Diffo.Provider.create_instance!(%{specification_id: specification.id})
      updated_instance = instance |> Diffo.Provider.cancel_service!()
      assert updated_instance.service_state == :cancelled
      assert updated_instance.service_operating_status == :unknown
      assert updated_instance.started_at == nil
      assert updated_instance.stopped_at != nil
    end

    test "activate an initial service instance - success" do
      specification = Diffo.Provider.create_specification!(%{name: "initialActive"})
      updated_instance = Diffo.Provider.create_instance!(%{specification_id: specification.id})
        |> Diffo.Provider.activate_service!()
      assert updated_instance.service_state == :active
      assert updated_instance.service_operating_status == :starting
      assert updated_instance.started_at != nil
      assert updated_instance.stopped_at == nil
    end

    test "terminate an active service instance - success" do
      specification = Diffo.Provider.create_specification!(%{name: "activeTerminate"})
      updated_instance = Diffo.Provider.create_instance!(%{specification_id: specification.id})
        |> Diffo.Provider.activate_service!() |> Diffo.Provider.terminate_service!()
      assert updated_instance.service_state == :terminated
      assert updated_instance.service_operating_status == :stopping
      assert updated_instance.started_at != nil
      assert updated_instance.stopped_at != nil
    end

    test "transition an active service instance running - success" do
      specification = Diffo.Provider.create_specification!(%{name: "activeRunning"})
      updated_instance = Diffo.Provider.create_instance!(%{specification_id: specification.id})
        |> Diffo.Provider.activate_service!()
        |> Diffo.Provider.status_instance!(%{service_operating_status: :running})
      assert updated_instance.service_state == :active
      assert updated_instance.service_operating_status == :running
      assert updated_instance.started_at != nil
      assert updated_instance.stopped_at == nil
    end

    test "transition an active service instance suspended - success" do
      specification = Diffo.Provider.create_specification!(%{name: "activeSuspended"})
      updated_instance = Diffo.Provider.create_instance!(%{specification_id: specification.id})
        |> Diffo.Provider.activate_service!() |> Diffo.Provider.suspend_service!()
      assert updated_instance.service_state == :suspended
      assert updated_instance.service_operating_status == :limited
      assert updated_instance.started_at != nil
      assert updated_instance.stopped_at == nil
    end

    test "transition an initial service terminated - failure" do
      specification = Diffo.Provider.create_specification!(%{name: "initialTerminated"})
      instance = Diffo.Provider.create_instance!(%{specification_id: specification.id})
      assert instance.service_state == :initial
      {:error, _error} = instance |> Diffo.Provider.terminate_service()
    end

    test "update a service instance name - success" do
      specification = Diffo.Provider.create_specification!(%{name: "wifiAccess"})
      updated_instance = Diffo.Provider.create_instance!(%{specification_id: specification.id})
        |> Diffo.Provider.name_instance!(%{name: "Westfield Doncaster L2.E16"})
      assert updated_instance.name == "Westfield Doncaster L2.E16"
    end

    test "update a service instance specification - success" do
      specification = Diffo.Provider.create_specification!(%{name: "wifiAccess"})
      instance = Diffo.Provider.create_instance!(%{specification_id: specification.id})
      new_specification = Diffo.Provider.create_specification!(%{name: "wifiAccess", major_version: 2})
      updated_instance = instance |> Diffo.Provider.specify_instance!(%{specification_id: new_specification.id})
      assert updated_instance.specification_id == new_specification.id
    end

    test "update a service instance specification - failure - does not exist" do
      specification = Diffo.Provider.create_specification!(%{name: "wifiAccess"})
      instance = Diffo.Provider.create_instance!(%{specification_id: specification.id})
      {:error, _error} = instance |> Diffo.Provider.specify_instance(%{specification_id: UUID.uuid4()})
    end

    test "update a service instance specification - failure - not a uuid" do
      specification = Diffo.Provider.create_specification!(%{name: "wifiAccess"})
      instance = Diffo.Provider.create_instance!(%{specification_id: specification.id})
      {:error, _error} = instance |> Diffo.Provider.specify_instance(%{specification_id: "not a uuid"})
    end
  end

  describe "Diffo.Provider encode Instances" do
    test "encode service with service child instance json - success" do
      parent_specification = Diffo.Provider.create_specification!(%{name: "siteConnection", category: "connectivity", description: "Site Connection Service"})
      child_specification = Diffo.Provider.create_specification!(%{name: "device", category: "connectivity", description: "Device Service"})
      parent_instance = Diffo.Provider.create_instance!(%{specification_id: parent_specification.id})
      child_instance = Diffo.Provider.create_instance!(%{specification_id: child_specification.id})
      feature = Diffo.Provider.create_feature!(%{instance_id: parent_instance.id, name: :management})
      _feature_characteristic = Diffo.Provider.create_characteristic!(%{feature_id: feature.id, name: :device, value: :epic1000a, type: :feature})
      _characteristic = Diffo.Provider.create_characteristic!(%{instance_id: parent_instance.id, name: :device, value: :managed, type: :instance})
      forward_relationship = Diffo.Provider.create_relationship!(%{type: :bestows, source_id: parent_instance.id, target_id: child_instance.id})
      _forward_relationship_characteristic = Diffo.Provider.create_characteristic!(%{relationship_id: forward_relationship.id, name: :role, value: :gateway, type: :relationship})
      _reverse_relationship = Diffo.Provider.create_relationship!(%{type: :providedTo, source_id: child_instance.id, target_id: parent_instance.id})
      place = Diffo.Provider.create_place!(%{id: "LOC000000897353", name: :locationId, href: "place/nbnco/LOC000000897353", referredType: :GeographicAddress})
      Diffo.Provider.create_place_ref!(%{instance_id: parent_instance.id, role: :CustomerSite, place_id: place.id})
      Diffo.Provider.create_place_ref!(%{instance_id: child_instance.id, role: :CustomerSite, place_id: place.id})
      t3_party = Diffo.Provider.create_party!(%{id: "T3_CONNECTIVITY", name: :entityId, href: "entity/internal/T3_CONNECTIVITY", referredType: :Entity})
      t4_party = Diffo.Provider.create_party!(%{id: "T4_CPE", name: :entityId, href: "entity/internal/T4_CPE", referredType: :Entity})
      _partyRef = Diffo.Provider.create_party_ref!(%{instance_id: parent_instance.id, role: :Provider, party_id: t3_party.id})
      _partyRef = Diffo.Provider.create_party_ref!(%{instance_id: child_instance.id, role: :Consumer, party_id: t3_party.id})
      _partyRef = Diffo.Provider.create_party_ref!(%{instance_id: child_instance.id, role: :Provider, party_id: t4_party.id})
      parent_encoding = Jason.encode!(parent_instance) |> Diffo.Util.summarise_dates()
      assert parent_encoding == ~s({\"id\":\"#{parent_instance.id}\",\"href\":\"serviceInventoryManagement/v4/service/siteConnection/#{parent_instance.id}\",\"category\":\"connectivity\",\"description\":\"Site Connection Service\","serviceDate\":\"now\",\"state\":\"initial\",\"operatingStatus\":\"unknown\",\"serviceSpecification\":{\"id\":\"#{parent_specification.id}\",\"href\":\"serviceCatalogManagement/v4/serviceSpecification/#{parent_specification.id}\",\"name\":\"siteConnection\",\"version\":\"v1.0.0\"},\"serviceRelationship\":[{\"type\":\"bestows\",\"service\":{\"id\":\"#{child_instance.id}\",\"href\":\"serviceInventoryManagement/v4/service/device/#{child_instance.id}\"},\"serviceRelationshipCharacteristic\":[{\"name\":\"role\",\"value\":\"gateway\"}]}],\"feature\":[{\"name\":\"management\",\"isEnabled\":true,\"featureCharacteristic\":[{\"name\":\"device\",\"value\":\"epic1000a\"}]}],\"serviceCharacteristic\":[{\"name\":\"device\",\"value\":\"managed\"}],\"place\":[{\"id\":\"LOC000000897353\",\"href\":\"place/nbnco/LOC000000897353\",\"name\":\"locationId\",\"role\":\"CustomerSite\",\"@referredType\":\"GeographicAddress\",\"@type\":\"PlaceRef\"}],\"relatedParty\":[{\"id\":\"T3_CONNECTIVITY\",\"href\":\"entity/internal/T3_CONNECTIVITY\",\"name\":\"entityId\",\"role\":\"Provider\",\"@referredType\":\"Entity\",\"@type\":\"PartyRef\"}]})
      child_encoding = Jason.encode!(child_instance) |> Diffo.Util.summarise_dates()
      assert child_encoding == ~s({\"id\":\"#{child_instance.id}\",\"href\":\"serviceInventoryManagement/v4/service/device/#{child_instance.id}\",\"category\":\"connectivity\",\"description\":\"Device Service\","serviceDate\":\"now\",\"state\":\"initial\",\"operatingStatus\":\"unknown\",\"serviceSpecification\":{\"id\":\"#{child_specification.id}\",\"href\":\"serviceCatalogManagement/v4/serviceSpecification/#{child_specification.id}\",\"name\":\"device\",\"version\":\"v1.0.0\"},\"serviceRelationship\":[{\"type\":\"providedTo\",\"service\":{\"id\":\"#{parent_instance.id}\",\"href\":\"serviceInventoryManagement/v4/service/siteConnection/#{parent_instance.id}\"}}],\"place\":[{\"id\":\"LOC000000897353\",\"href\":\"place/nbnco/LOC000000897353\",\"name\":\"locationId\",\"role\":\"CustomerSite\",\"@referredType\":\"GeographicAddress\",\"@type\":\"PlaceRef\"}],\"relatedParty\":[{\"id\":\"T3_CONNECTIVITY\",\"href\":\"entity/internal/T3_CONNECTIVITY\",\"name\":\"entityId\",\"role\":\"Consumer\",\"@referredType\":\"Entity\",\"@type\":\"PartyRef\"},{\"id\":\"T4_CPE\",\"href\":\"entity/internal/T4_CPE\",\"name\":\"entityId\",\"role\":\"Provider\",\"@referredType\":\"Entity\",\"@type\":\"PartyRef\"}]})
    end

    test "encode service with supporting service child instance json - success" do
      parent_specification = Diffo.Provider.create_specification!(%{name: "siteConnection", category: "connectivity", description: "Site Connection Service"})
      child_specification = Diffo.Provider.create_specification!(%{name: "device", category: "connectivity", description: "Device Service"})
      parent_instance = Diffo.Provider.create_instance!(%{specification_id: parent_specification.id})
      child_instance = Diffo.Provider.create_instance!(%{specification_id: child_specification.id})
      feature = Diffo.Provider.create_feature!(%{instance_id: parent_instance.id, name: :management})
      _feature_characteristic = Diffo.Provider.create_characteristic!(%{feature_id: feature.id, name: :device, value: :epic1000a, type: :feature})
      _characteristic = Diffo.Provider.create_characteristic!(%{instance_id: parent_instance.id, name: :device, value: :managed, type: :instance})
      forward_relationship = Diffo.Provider.create_relationship!(%{type: :bestows, source_id: parent_instance.id, target_id: child_instance.id, alias: :primary})
      _forward_relationship_characteristic = Diffo.Provider.create_characteristic!(%{relationship_id: forward_relationship.id, name: :role, value: :gateway, type: :relationship})
      _reverse_relationship = Diffo.Provider.create_relationship!(%{type: :providedTo, source_id: child_instance.id, target_id: parent_instance.id})
      parent_encoding = Jason.encode!(parent_instance) |> Diffo.Util.summarise_dates()
      assert parent_encoding == ~s({\"id\":\"#{parent_instance.id}\",\"href\":\"serviceInventoryManagement/v4/service/siteConnection/#{parent_instance.id}\",\"category\":\"connectivity\",\"description\":\"Site Connection Service\","serviceDate\":\"now\",\"state\":\"initial\",\"operatingStatus\":\"unknown\",\"serviceSpecification\":{\"id\":\"#{parent_specification.id}\",\"href\":\"serviceCatalogManagement/v4/serviceSpecification/#{parent_specification.id}\",\"name\":\"siteConnection\",\"version\":\"v1.0.0\"},\"serviceRelationship\":[{\"type\":\"bestows\",\"service\":{\"id\":\"#{child_instance.id}\",\"href\":\"serviceInventoryManagement/v4/service/device/#{child_instance.id}\"},\"serviceRelationshipCharacteristic\":[{\"name\":\"role\",\"value\":\"gateway\"}]}],\"supportingService\":[{\"id\":\"#{child_instance.id}\",\"href\":\"serviceInventoryManagement/v4/service/device/#{child_instance.id}\"}],\"feature\":[{\"name\":\"management\",\"isEnabled\":true,\"featureCharacteristic\":[{\"name\":\"device\",\"value\":\"epic1000a\"}]}],\"serviceCharacteristic\":[{\"name\":\"device\",\"value\":\"managed\"}]})
      child_encoding = Jason.encode!(child_instance) |> Diffo.Util.summarise_dates()
      assert child_encoding == ~s({\"id\":\"#{child_instance.id}\",\"href\":\"serviceInventoryManagement/v4/service/device/#{child_instance.id}\",\"category\":\"connectivity\",\"description\":\"Device Service\","serviceDate\":\"now\",\"state\":\"initial\",\"operatingStatus\":\"unknown\",\"serviceSpecification\":{\"id\":\"#{child_specification.id}\",\"href\":\"serviceCatalogManagement/v4/serviceSpecification/#{child_specification.id}\",\"name\":\"device\",\"version\":\"v1.0.0\"},\"serviceRelationship\":[{\"type\":\"providedTo\",\"service\":{\"id\":\"#{parent_instance.id}\",\"href\":\"serviceInventoryManagement/v4/service/siteConnection/#{parent_instance.id}\"}}]})
    end

    test "encode service with resource child instance json - success" do
      parent_specification = Diffo.Provider.create_specification!(%{name: "adslAccess", category: "connectivity", description: "ADSL Access Service"})
      child_specification = Diffo.Provider.create_specification!(%{name: "can", category: "physical", description: "Customer Access Network Resource", type: :resourceSpecification})
      parent_instance = Diffo.Provider.create_instance!(%{specification_id: parent_specification.id})
      child_instance = Diffo.Provider.create_instance!(%{specification_id: child_specification.id, type: :resource})
      feature = Diffo.Provider.create_feature!(%{instance_id: parent_instance.id, name: :dynamicLineManagement})
      _feature_characteristic = Diffo.Provider.create_characteristic!(%{feature_id: feature.id, name: :goal, value: :stability, type: :feature})
      _characteristic = Diffo.Provider.create_characteristic!(%{instance_id: parent_instance.id, name: :dslam, value: "QDONC1001", type: :instance})
      _reverse_relationship = Diffo.Provider.create_relationship!(%{type: :assignedTo, source_id: child_instance.id, target_id: parent_instance.id})
      _forward_relationship = Diffo.Provider.create_relationship!(%{type: :isAssigned, source_id: parent_instance.id, target_id: child_instance.id})
      parent_encoding = Jason.encode!(parent_instance) |> Diffo.Util.summarise_dates()
      assert parent_encoding == ~s({\"id\":\"#{parent_instance.id}\",\"href\":\"serviceInventoryManagement/v4/service/adslAccess/#{parent_instance.id}\",\"category\":\"connectivity\",\"description\":\"ADSL Access Service\","serviceDate\":\"now\",\"state\":\"initial\",\"operatingStatus\":\"unknown\",\"serviceSpecification\":{\"id\":\"#{parent_specification.id}\",\"href\":\"serviceCatalogManagement/v4/serviceSpecification/#{parent_specification.id}\",\"name\":\"adslAccess\",\"version\":\"v1.0.0\"},\"resourceRelationship\":[{\"type\":\"isAssigned\",\"resource\":{\"id\":\"#{child_instance.id}\",\"href\":\"resourceInventoryManagement/v4/resource/can/#{child_instance.id}\"}}],\"feature\":[{\"name\":\"dynamicLineManagement\",\"isEnabled\":true,\"featureCharacteristic\":[{\"name\":\"goal\",\"value\":\"stability\"}]}],\"serviceCharacteristic\":[{\"name\":\"dslam",\"value\":\"QDONC1001\"}]})
      child_encoding = Jason.encode!(child_instance)|> Diffo.Util.summarise_dates()
      assert child_encoding == ~s({\"id\":\"#{child_instance.id}\",\"href\":\"resourceInventoryManagement/v4/resource/can/#{child_instance.id}\",\"category\":\"physical\",\"description\":\"Customer Access Network Resource\",\"resourceSpecification\":{\"id\":\"#{child_specification.id}\",\"href\":\"resourceCatalogManagement/v4/resourceSpecification/#{child_specification.id}\",\"name\":\"can\",\"version\":\"v1.0.0\"},\"serviceRelationship\":[{\"type\":\"assignedTo\",\"service\":{\"id\":\"#{parent_instance.id}\",\"href\":\"serviceInventoryManagement/v4/service/adslAccess/#{parent_instance.id}\"}}]})
    end

    test "encode service with supporting resource child instance json - success" do
      parent_specification = Diffo.Provider.create_specification!(%{name: "adslAccess", category: "connectivity", description: "ADSL Access Service"})
      child_specification = Diffo.Provider.create_specification!(%{name: "can", category: "physical", description: "Customer Access Network Resource", type: :resourceSpecification})
      parent_instance = Diffo.Provider.create_instance!(%{specification_id: parent_specification.id})
      child_instance = Diffo.Provider.create_instance!(%{specification_id: child_specification.id, type: :resource})
      feature = Diffo.Provider.create_feature!(%{instance_id: parent_instance.id, name: :dynamicLineManagement})
      _feature_characteristic = Diffo.Provider.create_characteristic!(%{feature_id: feature.id, name: :goal, value: :stability, type: :feature})
      _characteristic = Diffo.Provider.create_characteristic!(%{instance_id: parent_instance.id, name: :dslam, value: "QDONC1001", type: :instance})
      _reverse_relationship = Diffo.Provider.create_relationship!(%{type: :assignedTo, source_id: child_instance.id, target_id: parent_instance.id})
      _forward_relationship = Diffo.Provider.create_relationship!(%{type: :isAssigned, source_id: parent_instance.id, target_id: child_instance.id, alias: :can})
      parent_encoding = Jason.encode!(parent_instance) |> Diffo.Util.summarise_dates()
      assert parent_encoding == ~s({\"id\":\"#{parent_instance.id}\","href\":\"serviceInventoryManagement/v4/service/adslAccess/#{parent_instance.id}\",\"category\":\"connectivity\",\"description\":\"ADSL Access Service\","serviceDate\":\"now\",\"state\":\"initial\",\"operatingStatus\":\"unknown\",\"serviceSpecification\":{\"id\":\"#{parent_specification.id}\",\"href\":\"serviceCatalogManagement/v4/serviceSpecification/#{parent_specification.id}\",\"name\":\"adslAccess\",\"version\":\"v1.0.0\"},\"resourceRelationship\":[{\"type\":\"isAssigned\",\"resource\":{\"id\":\"#{child_instance.id}\",\"href\":\"resourceInventoryManagement/v4/resource/can/#{child_instance.id}\"}}],\"supportingResource\":[{\"id\":\"#{child_instance.id}\",\"href\":\"resourceInventoryManagement/v4/resource/can/#{child_instance.id}\"}],\"feature\":[{\"name\":\"dynamicLineManagement\",\"isEnabled\":true,\"featureCharacteristic\":[{\"name\":\"goal\",\"value\":\"stability\"}]}],\"serviceCharacteristic\":[{\"name\":\"dslam",\"value\":\"QDONC1001\"}]})
      child_encoding = Jason.encode!(child_instance) |> Diffo.Util.summarise_dates()
      assert child_encoding == ~s({\"id\":\"#{child_instance.id}\",\"href\":\"resourceInventoryManagement/v4/resource/can/#{child_instance.id}\",\"category\":\"physical\",\"description\":\"Customer Access Network Resource\",\"resourceSpecification\":{\"id\":\"#{child_specification.id}\",\"href\":\"resourceCatalogManagement/v4/resourceSpecification/#{child_specification.id}\",\"name\":\"can\",\"version\":\"v1.0.0\"},\"serviceRelationship\":[{\"type\":\"assignedTo\",\"service\":{\"id\":\"#{parent_instance.id}\",\"href\":\"serviceInventoryManagement/v4/service/adslAccess/#{parent_instance.id}\"}}]})
    end

    test "encode sorts relationships - success" do
      specification = Diffo.Provider.create_specification!(%{name: "broadband"})
      access_specification = Diffo.Provider.create_specification!(%{name: "fibreAccess"})
      aggregation_specification = Diffo.Provider.create_specification!(%{name: "aggregation"})
      edge_specification = Diffo.Provider.create_specification!(%{name: "edge"})
      instance = Diffo.Provider.create_instance!(%{specification_id: specification.id})
      access_instance = Diffo.Provider.create_instance!(%{specification_id: access_specification.id})
      aggregation_instance = Diffo.Provider.create_instance!(%{specification_id: aggregation_specification.id})
      edge_instance = Diffo.Provider.create_instance!(%{specification_id: edge_specification.id})
      _forward_relationship = Diffo.Provider.create_relationship!(%{type: :bestows, source_id: instance.id, target_id: access_instance.id, alias: :access})
      _forward_relationship = Diffo.Provider.create_relationship!(%{type: :bestows, source_id: instance.id, target_id: aggregation_instance.id, alias: :aggregation})
      _forward_relationship = Diffo.Provider.create_relationship!(%{type: :bestows, source_id: instance.id, target_id: edge_instance.id, alias: :edge})
      encoding = Jason.encode!(instance) |> Diffo.Util.summarise_dates()
      assert encoding == ~s({\"id\":\"#{instance.id}\",\"href\":\"serviceInventoryManagement/v4/service/broadband/#{instance.id}\",\"serviceDate\":\"now\",\"state\":\"initial\",\"operatingStatus\":\"unknown\",\"serviceSpecification\":{\"id\":\"#{specification.id}\",\"href\":\"serviceCatalogManagement/v4/serviceSpecification/#{specification.id}\",\"name\":\"broadband\",\"version\":\"v1.0.0\"},\"serviceRelationship\":[{\"type\":\"bestows\",\"service\":{\"id\":\"#{aggregation_instance.id}\",\"href\":\"serviceInventoryManagement/v4/service/aggregation/#{aggregation_instance.id}\"}},{\"type\":\"bestows\",\"service\":{\"id\":\"#{edge_instance.id}\",\"href\":\"serviceInventoryManagement/v4/service/edge/#{edge_instance.id}\"}},{\"type\":\"bestows\",\"service\":{\"id\":\"#{access_instance.id}\",\"href\":\"serviceInventoryManagement/v4/service/fibreAccess/#{access_instance.id}\"}}],\"supportingService\":[{\"id\":\"#{aggregation_instance.id}\",\"href\":\"serviceInventoryManagement/v4/service/aggregation/#{aggregation_instance.id}\"},{\"id\":\"#{edge_instance.id}\",\"href\":\"serviceInventoryManagement/v4/service/edge/#{edge_instance.id}\"},{\"id\":\"#{access_instance.id}\",\"href\":\"serviceInventoryManagement/v4/service/fibreAccess/#{access_instance.id}\"}]})
    end

    test "encode sorts features - success" do
      specification = Diffo.Provider.create_specification!(%{name: "siteConnection"})
      instance = Diffo.Provider.create_instance!(%{specification_id: specification.id})
      _feature = Diffo.Provider.create_feature!(%{instance_id: instance.id, name: :optimisation})
      _feature = Diffo.Provider.create_feature!(%{instance_id: instance.id, name: :management})
      _feature = Diffo.Provider.create_feature!(%{instance_id: instance.id, name: :security})
      encoding = Jason.encode!(instance) |> Diffo.Util.summarise_dates()
      assert encoding == ~s({\"id\":\"#{instance.id}\",\"href\":\"serviceInventoryManagement/v4/service/siteConnection/#{instance.id}\",\"serviceDate\":\"now\",\"state\":\"initial\",\"operatingStatus\":\"unknown\",\"serviceSpecification\":{\"id\":\"#{specification.id}\",\"href\":\"serviceCatalogManagement/v4/serviceSpecification/#{specification.id}\",\"name\":\"siteConnection\",\"version\":\"v1.0.0\"},\"feature\":[{\"name\":\"management\",\"isEnabled\":true},{\"name\":\"optimisation\",\"isEnabled\":true},{\"name\":\"security\",\"isEnabled\":true}]})
    end

    test "encode sorts characteristics within features - success" do
      specification = Diffo.Provider.create_specification!(%{name: "siteConnection"})
      instance = Diffo.Provider.create_instance!(%{specification_id: specification.id})
      feature = Diffo.Provider.create_feature!(%{instance_id: instance.id, name: :automations})
      _characteristic = Diffo.Provider.create_characteristic!(%{feature_id: feature.id, name: :optimisation, value: true, type: :feature})
      _characteristic = Diffo.Provider.create_characteristic!(%{feature_id: feature.id, name: :management, value: true, type: :feature})
      _characteristic = Diffo.Provider.create_characteristic!(%{feature_id: feature.id, name: :security, value: true, type: :feature})
      encoding = Jason.encode!(instance) |> Diffo.Util.summarise_dates()
      assert encoding == ~s({\"id\":\"#{instance.id}\",\"href\":\"serviceInventoryManagement/v4/service/siteConnection/#{instance.id}\",\"serviceDate\":\"now\",\"state\":\"initial\",\"operatingStatus\":\"unknown\",\"serviceSpecification\":{\"id\":\"#{specification.id}\",\"href\":\"serviceCatalogManagement/v4/serviceSpecification/#{specification.id}\",\"name\":\"siteConnection\",\"version\":\"v1.0.0\"},\"feature\":[{\"name\":\"automations\",\"isEnabled\":true,\"featureCharacteristic\":[{\"name\":\"management\",\"value\":true},{\"name\":\"optimisation\",\"value\":true},{\"name\":\"security\",\"value\":true}]}]})
    end

    test "encode sorts characteristics - success" do
      specification = Diffo.Provider.create_specification!(%{name: "siteConnection"})
      instance = Diffo.Provider.create_instance!(%{specification_id: specification.id})
      _characteristic = Diffo.Provider.create_characteristic!(%{instance_id: instance.id, name: :optimisation, value: true, type: :instance})
      _characteristic = Diffo.Provider.create_characteristic!(%{instance_id: instance.id, name: :management, value: true, type: :instance})
      _characteristic = Diffo.Provider.create_characteristic!(%{instance_id: instance.id, name: :security, value: true, type: :instance})
      encoding = Jason.encode!(instance) |> Diffo.Util.summarise_dates()
      assert encoding == ~s({\"id\":\"#{instance.id}\",\"href\":\"serviceInventoryManagement/v4/service/siteConnection/#{instance.id}\",\"serviceDate\":\"now\",\"state\":\"initial\",\"operatingStatus\":\"unknown\",\"serviceSpecification\":{\"id\":\"#{specification.id}\",\"href\":\"serviceCatalogManagement/v4/serviceSpecification/#{specification.id}\",\"name\":\"siteConnection\",\"version\":\"v1.0.0\"},\"serviceCharacteristic\":[{\"name\":\"management\",\"value\":true},{\"name\":\"optimisation\",\"value\":true},{\"name\":\"security\",\"value\":true}]})
    end


    test "encode cancelled service - success" do
      specification = Diffo.Provider.create_specification!(%{name: "siteConnection"})
      instance = Diffo.Provider.create_instance!(%{specification_id: specification.id})
      cancelled_instance = Diffo.Provider.cancel_service!(instance)
      encoding = Jason.encode!(cancelled_instance) |> Diffo.Util.summarise_dates()
      assert encoding == ~s({\"id\":\"#{instance.id}\",\"href\":\"serviceInventoryManagement/v4/service/siteConnection/#{instance.id}\",\"serviceDate\":\"now\",\"endDate\":\"now\",\"state\":\"cancelled\",\"operatingStatus\":\"unknown\",\"serviceSpecification\":{\"id\":\"#{specification.id}\",\"href\":\"serviceCatalogManagement/v4/serviceSpecification/#{specification.id}\",\"name\":\"siteConnection\",\"version\":\"v1.0.0\"}})
    end

    test "encode active service - success" do
      specification = Diffo.Provider.create_specification!(%{name: "siteConnection"})
      instance = Diffo.Provider.create_instance!(%{specification_id: specification.id})
      activated_instance = Diffo.Provider.activate_service!(instance)
      encoding = Jason.encode!(activated_instance) |> Diffo.Util.summarise_dates()
      assert encoding == ~s({\"id\":\"#{instance.id}\",\"href\":\"serviceInventoryManagement/v4/service/siteConnection/#{instance.id}\",\"serviceDate\":\"now\",\"startDate\":\"now\",\"state\":\"active\",\"operatingStatus\":\"starting\",\"serviceSpecification\":{\"id\":\"#{specification.id}\",\"href\":\"serviceCatalogManagement/v4/serviceSpecification/#{specification.id}\",\"name\":\"siteConnection\",\"version\":\"v1.0.0\"}})
    end

    test "encode suspended service - success" do
      specification = Diffo.Provider.create_specification!(%{name: "siteConnection"})
      instance = Diffo.Provider.create_instance!(%{specification_id: specification.id})
      activated_instance = Diffo.Provider.activate_service!(instance) |> Diffo.Provider.suspend_service!()
      encoding = Jason.encode!(activated_instance) |> Diffo.Util.summarise_dates()
      assert encoding == ~s({\"id\":\"#{instance.id}\",\"href\":\"serviceInventoryManagement/v4/service/siteConnection/#{instance.id}\",\"serviceDate\":\"now\",\"startDate\":\"now\",\"state\":\"suspended\",\"operatingStatus\":\"limited\",\"serviceSpecification\":{\"id\":\"#{specification.id}\",\"href\":\"serviceCatalogManagement/v4/serviceSpecification/#{specification.id}\",\"name\":\"siteConnection\",\"version\":\"v1.0.0\"}})
    end

    test "encode terminated service - success" do
      specification = Diffo.Provider.create_specification!(%{name: "siteConnection"})
      instance = Diffo.Provider.create_instance!(%{specification_id: specification.id})
      terminated_instance = Diffo.Provider.activate_service!(instance) |> Diffo.Provider.terminate_service!()
      encoding = Jason.encode!(terminated_instance) |> Diffo.Util.summarise_dates()
      assert encoding == ~s({\"id\":\"#{instance.id}\",\"href\":\"serviceInventoryManagement/v4/service/siteConnection/#{instance.id}\",\"serviceDate\":\"now\",\"startDate\":\"now\",\"endDate\":\"now\",\"state\":\"terminated\",\"operatingStatus\":\"stopping\",\"serviceSpecification\":{\"id\":\"#{specification.id}\",\"href\":\"serviceCatalogManagement/v4/serviceSpecification/#{specification.id}\",\"name\":\"siteConnection\",\"version\":\"v1.0.0\"}})
    end
  end

  describe "Diffo.Provider delete Instances" do
    test "bulk delete" do
      Diffo.Provider.delete_instance!(Diffo.Provider.list_instances!())
    end
  end
end
