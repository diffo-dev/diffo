defmodule Diffo.Provider.FeatureTest do
  @moduledoc false
  use ExUnit.Case

  setup_all do
    AshNeo4j.BoltxHelper.start()
  end

  setup do
    on_exit(fn ->
      AshNeo4j.Neo4jHelper.delete_all()
    end)
  end

  describe "Diffo.Provider read Features" do
    test "list features - success" do
      Diffo.Provider.create_feature!(%{name: :mobileBackup})

      Diffo.Provider.create_feature!(%{
        name: :restriction,
        isEnabled: false
      })

      instance_features = Diffo.Provider.list_features!()
      assert length(instance_features) == 2
      # should be sorted
      assert List.first(instance_features).name == :mobileBackup
      assert List.last(instance_features).name == :restriction
    end
  end

  describe "Diffo.Provider create Features" do
    test "create instance feature - success" do
      feature = Diffo.Provider.create_feature!(%{name: :mobileBackup})
      assert feature.name == :mobileBackup
      assert feature.isEnabled == true
    end

    test "create feature with different characteristic - success" do
      first_characteristic =
        Diffo.Provider.create_characteristic!(%{
          name: :encapsulation,
          value: :qinq,
          type: :feature
        })

      second_characteristic =
        Diffo.Provider.create_characteristic!(%{
          name: :type,
          value: :evpl,
          type: :feature
        })

      Diffo.Provider.create_feature!(%{
        name: :restriction,
        characteristics: [first_characteristic.id, second_characteristic.id]
      })
    end

    test "create feature with duplicate characteristic - failure" do
      first_characteristic =
        Diffo.Provider.create_characteristic!(%{
          name: :type,
          value: :fraudHeavy,
          type: :feature
        })

      second_characteristic =
        Diffo.Provider.create_characteristic!(%{
          name: :type,
          value: :fraudLight,
          type: :feature
        })

      {:error, _} =
        Diffo.Provider.create_feature(%{
          name: :restriction,
          characteristics: [first_characteristic.id, second_characteristic.id]
        })
    end
  end

  describe "Diffo.Provider updated Features" do
    test "update feature isEnabled - success" do
      feature =
        Diffo.Provider.create_feature!(%{
          name: :restriction,
          isEnabled: false
        })

      assert feature.isEnabled == false
      updated_feature = feature |> Diffo.Provider.update_feature!(%{isEnabled: true})
      assert updated_feature.isEnabled == true
    end

    test "update feature add characteristic - success" do
      device_characteristic =
        Diffo.Provider.create_characteristic!(%{
          name: :device,
          value: :epic1000a,
          type: :feature
        })

      connection_characteristic =
        Diffo.Provider.create_characteristic!(%{
          name: :connection,
          value: :foreign,
          type: :feature
        })

      feature =
        Diffo.Provider.create_feature!(%{
          name: :management,
          characteristics: [device_characteristic.id]
        })

      _updated_feature =
        feature
        |> Diffo.Provider.relate_feature_characteristics!(%{
          characteristics: [connection_characteristic.id]
        })
    end

    test "update feature with duplicate characteristic - failure" do
      first_characteristic =
        Diffo.Provider.create_characteristic!(%{
          name: :type,
          value: :fraudHeavy,
          type: :feature
        })

      second_characteristic =
        Diffo.Provider.create_characteristic!(%{
          name: :type,
          value: :fraudLight,
          type: :feature
        })

      feature =
        Diffo.Provider.create_feature!(%{
          name: :restriction,
          characteristics: [first_characteristic.id]
        })

      {:error, _updated_feature} =
        feature
        |> Diffo.Provider.relate_feature_characteristics(%{
          characteristics: [second_characteristic.id]
        })
    end
  end

  describe "Diffo.Provider encode Features" do
    test "encode json feature with sorted characteristics - success" do
      device_characteristic =
        Diffo.Provider.create_characteristic!(%{
          name: :device,
          value: :epic1000a,
          type: :feature
        })

      connection_characteristic =
        Diffo.Provider.create_characteristic!(%{
          name: :connection,
          value: :foreign,
          type: :feature
        })

      feature =
        Diffo.Provider.create_feature!(%{
          name: :management,
          characteristics: [connection_characteristic.id, device_characteristic.id]
        })

      encoding = Jason.encode!(feature)

      assert encoding ==
               "{\"name\":\"management\",\"isEnabled\":true,\"featureCharacteristic\":[{\"name\":\"connection\",\"value\":\"foreign\"},{\"name\":\"device\",\"value\":\"epic1000a\"}]}"
    end
  end

  describe "Diffo.Provider delete Features" do
    test "delete feature with related characteristic - success" do
      characteristic =
        Diffo.Provider.create_characteristic!(%{
          name: :device,
          value: :epic1000a,
          type: :feature
        })

      feature =
        Diffo.Provider.create_feature!(%{name: :management, characteristics: [characteristic.id]})

      :ok = Diffo.Provider.delete_feature(feature)
      {:error, _error} = Diffo.Provider.get_feature_by_id(feature.id)
      Diffo.Provider.get_characteristic_by_id!(characteristic.id)
    end

    @tag debug: true
    test "delete feature with related instance - failure, related instance" do
      feature = Diffo.Provider.create_feature!(%{name: :management})

      specification = Diffo.Provider.create_specification!(%{name: "siteConnection"})

      instance =
        Diffo.Provider.create_instance!(%{specified_by: specification.id, features: [feature.id]})

      {:error, error} = Diffo.Provider.delete_feature(feature)
      assert is_struct(error, Ash.Error.Invalid)

      # now unrelate the feature from the instance
      Diffo.Provider.unrelate_instance_features!(instance, %{
        features: [feature.id]
      })

      :ok = Diffo.Provider.delete_feature!(feature)
      {:error, _error} = Diffo.Provider.get_feature_by_id(feature.id)
    end
  end
end
