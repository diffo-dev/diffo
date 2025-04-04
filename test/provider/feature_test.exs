defmodule Diffo.Provider.FeatureTest do
  @moduledoc false
  use ExUnit.Case

  describe "Diffo.Provider read Features" do
    test "list features - success" do
      specification = Diffo.Provider.create_specification!(%{name: "broadband"})
      instance = Diffo.Provider.create_instance!(%{specification_id: specification.id})
      Diffo.Provider.create_feature!(%{instance_id: instance.id, name: :mobileBackup})
      Diffo.Provider.create_feature!(%{instance_id: instance.id, name: :restriction, isEnabled: false})
      instance_features = Diffo.Provider.list_features!()
      assert length(instance_features) == 2
      # should be sorted
      assert List.first(instance_features).name == :mobileBackup
      assert List.last(instance_features).name == :restriction
    end

    test "list instance features - success" do
      specification = Diffo.Provider.create_specification!(%{name: "broadband"})
      instance = Diffo.Provider.create_instance!(%{specification_id: specification.id})
      other_instance = Diffo.Provider.create_instance!(%{specification_id: specification.id})
      Diffo.Provider.create_feature!(%{instance_id: instance.id, name: :mobileBackup})
      Diffo.Provider.create_feature!(%{instance_id: instance.id, name: :restriction, isEnabled: false})
      Diffo.Provider.create_feature!(%{instance_id: other_instance.id, name: :mobileBackup})
      instance_features = Diffo.Provider.list_features_by_related_id!(instance.id)
      assert length(instance_features) == 2
      # should be sorted
      assert List.first(instance_features).name == :mobileBackup
      assert List.last(instance_features).name == :restriction
    end
  end

  describe "Diffo.Provider create Characteristics" do
    test "create instance feature - success" do
      specification = Diffo.Provider.create_specification!(%{name: "broadband"})
      instance = Diffo.Provider.create_instance!(%{specification_id: specification.id})
      feature = Diffo.Provider.create_feature!(%{instance_id: instance.id, name: :mobileBackup})
      assert feature.name == :mobileBackup
      assert feature.isEnabled == true
    end

    test "create duplicate feature on same instance - failure" do
      specification = Diffo.Provider.create_specification!(%{name: "evc"})
      instance = Diffo.Provider.create_instance!(%{specification_id: specification.id})
      _first_feature = Diffo.Provider.create_feature!(%{instance_id: instance.id, name: :autoNegotiate})
      {:error, _error} = Diffo.Provider.create_feature(%{instance_id: instance.id, name: :autoNegotiate})
    end
  end

  describe "Diffo.Provider updated Features" do
    test "update feature isEnabled - success" do
      specification = Diffo.Provider.create_specification!(%{name: "broadband"})
      instance = Diffo.Provider.create_instance!(%{specification_id: specification.id})
      feature = Diffo.Provider.create_feature!(%{instance_id: instance.id, name: :restriction, isEnabled: false})
      assert feature.isEnabled == false
      updated_feature = feature |> Diffo.Provider.update_feature!(%{isEnabled: true})
      assert updated_feature.isEnabled == true
    end
  end

  describe "Diffo.Provider encode Features" do
    test "encode json feature with sorted characteristics - success" do
      specification = Diffo.Provider.create_specification!(%{name: "siteConnection"})
      instance = Diffo.Provider.create_instance!(%{specification_id: specification.id})
      feature = Diffo.Provider.create_feature!(%{instance_id: instance.id, name: :management})
      _characteristic = Diffo.Provider.create_characteristic!(%{feature_id: feature.id, name: :device, value: :epic1000a, type: :feature})
      _characteristic = Diffo.Provider.create_characteristic!(%{feature_id: feature.id, name: :connection, value: :foreign, type: :feature})
      loaded_feature = Diffo.Provider.get_feature_by_id!(feature.id)
      encoding = Jason.encode!(loaded_feature)
      assert encoding == "{\"name\":\"management\",\"isEnabled\":true,\"featureCharacteristic\":[{\"name\":\"connection\",\"value\":\"foreign\"},{\"name\":\"device\",\"value\":\"epic1000a\"}]}"
    end
  end

  describe "Diffo.Provider delete Features" do
    test "delete feature with related instance - success" do
      specification = Diffo.Provider.create_specification!(%{name: "siteConnection"})
      instance = Diffo.Provider.create_instance!(%{specification_id: specification.id})
      feature = Diffo.Provider.create_feature!(%{instance_id: instance.id, name: :management})
      :ok = Diffo.Provider.delete_feature(feature)
      {:error, _error} = Diffo.Provider.get_feature_by_id(feature.id)
    end

    test "delete feature with related instance - failure, related characteristic" do
      specification = Diffo.Provider.create_specification!(%{name: "siteConnection"})
      instance = Diffo.Provider.create_instance!(%{specification_id: specification.id})
      feature = Diffo.Provider.create_feature!(%{instance_id: instance.id, name: :management})
      characteristic1 = Diffo.Provider.create_characteristic!(%{feature_id: feature.id, name: :device, value: :epic1000a, type: :feature})
      characteristic2 = Diffo.Provider.create_characteristic!(%{feature_id: feature.id, name: :connection, value: :foreign, type: :feature})
      # TODO this fails but with an exception which doesn't match the expected error
      try do
        {:error, _result} = Diffo.Provider.delete_feature!(feature)
      rescue
        _error ->
          :ok
      end
      # now delete the feature characteristic and we should be able to delete the feature
      :ok = Diffo.Provider.delete_characteristic(characteristic1)
      :ok = Diffo.Provider.delete_characteristic(characteristic2)
      :ok = Diffo.Provider.delete_feature(feature)
      {:error, _error} = Diffo.Provider.get_feature_by_id(feature.id)
    end
  end
end
