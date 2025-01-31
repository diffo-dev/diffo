defmodule Diffo.Provider.Feature_Test do
  @moduledoc false
  use ExUnit.Case
  use Diffo.DataCase, async: true


  describe "Diffo.Provider prepare Features" do
    test "check there are no features" do
      assert Diffo.Provider.list_features!() == []
    end
  end

  describe "Diffo.Provider read Features" do
    test "list instance features - success" do
      specification = Diffo.Provider.create_specification!(%{name: "broadband"})
      instance = Diffo.Provider.create_instance!(%{specification_id: specification.id})
      Diffo.Provider.create_feature!(%{instance_id: instance.id, name: :mobileBackup})
      Diffo.Provider.create_feature!(%{instance_id: instance.id, name: :restriction, isEnabled: false})
      instance_features = Diffo.Provider.list_features_by_related_id!(instance.id)
      assert length(instance_features) == 2
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

  describe "Diffo.Provider cleanup Features" do
    test "ensure there are no features" do
      for features <- Diffo.Provider.list_features!() do
        Diffo.Provider.delete_feature!(%{id: features.id})
      end
      assert Diffo.Provider.list_features!() == []
    end

    test "ensure there are no instances" do
      for instance <- Diffo.Provider.list_instances!() do
        Diffo.Provider.delete_instance!(%{id: instance.id})
      end
      assert Diffo.Provider.list_instances!() == []
    end

    test "ensure there are no specifications" do
      for specification <- Diffo.Provider.list_specifications!() do
        Diffo.Provider.delete_specification!(%{id: specification.id})
      end
      assert Diffo.Provider.list_specifications!() == []
    end
  end
end
