# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Extension.InstanceTransformerTest do
  @moduledoc false
  use ExUnit.Case, async: true, async: true

  alias Diffo.Test.Instance.ShelfInstance
  alias Diffo.Test.Instance.CardInstance
  alias Diffo.Provider.Extension.Characteristic
  alias Diffo.Provider.Extension.Feature
  alias Diffo.Provider.Extension.PlaceDeclaration
  alias Diffo.Provider.Instance.Info

  describe "PersistSpecification" do
    test "bakes specification/0 onto the resource" do
      spec = ShelfInstance.specification()
      assert spec[:id] == "ef016d85-9dbd-429c-84da-1df56cc7dda5"
      assert spec[:name] == "shelf"
      assert spec[:type] == :resourceSpecification
      assert spec[:description] == "A Shelf Resource Instance which contain cards"
      assert spec[:category] == "Network Resource"
      assert spec[:major_version] == 1
    end

    test "card specification is baked correctly" do
      spec = CardInstance.specification()
      assert spec[:id] == "cd29956f-6c68-44cc-bf54-705eb8d2f754"
      assert spec[:name] == "card"
      assert spec[:type] == :resourceSpecification
    end

    test "specification is also accessible via Info" do
      assert Info.specification(ShelfInstance)[:name] == "shelf"
      assert Info.specification(CardInstance)[:name] == "card"
    end
  end

  describe "PersistCharacteristics" do
    test "bakes characteristics/0 onto the resource" do
      chars = ShelfInstance.characteristics()
      assert is_list(chars)
      assert length(chars) == 2
      names = Enum.map(chars, & &1.name)
      assert :shelf in names
      assert :shelves in names
    end

    test "each characteristic is a Characteristic struct" do
      [first | _] = ShelfInstance.characteristics()
      assert is_struct(first, Characteristic)
    end

    test "characteristics are also accessible via Info" do
      assert length(Info.characteristics(ShelfInstance)) == 2
      # Card has :card characteristic; :ports moved to pools do
      assert length(Info.characteristics(CardInstance)) == 1
    end

    test "Info.characteristic/2 returns the named characteristic" do
      char = Info.characteristic(ShelfInstance, :shelves)
      assert char.name == :shelves
    end

    test "Info.characteristic/2 returns nil for unknown name" do
      assert Info.characteristic(ShelfInstance, :nonexistent) == nil
    end
  end

  describe "PersistFeatures" do
    test "bakes features/0 onto the resource" do
      features = ShelfInstance.features()
      assert is_list(features)
      assert length(features) == 1
      [feature] = features
      assert feature.name == :spectralManagement
      assert feature.is_enabled? == true
    end

    test "each feature is a Feature struct" do
      [feature] = ShelfInstance.features()
      assert is_struct(feature, Feature)
    end

    test "feature characteristics are nested in the declaration" do
      [feature] = ShelfInstance.features()
      assert length(feature.characteristics) == 2
      char_names = Enum.map(feature.characteristics, & &1.name)
      assert :deploymentClass in char_names
      assert :deploymentClasses in char_names
    end

    test "features are also accessible via Info" do
      assert length(Info.features(ShelfInstance)) == 1
      assert Info.features(CardInstance) == []
    end

    test "Info.feature/2 returns the named feature" do
      feature = Info.feature(ShelfInstance, :spectralManagement)
      assert feature.name == :spectralManagement
    end

    test "Info.feature/2 returns nil for unknown name" do
      assert Info.feature(ShelfInstance, :nonexistent) == nil
    end

    test "Info.feature_characteristic/3 returns the named characteristic within a feature" do
      char = Info.feature_characteristic(ShelfInstance, :spectralManagement, :deploymentClass)
      assert char.name == :deploymentClass
    end

    test "Info.feature_characteristic/3 returns nil for unknown feature" do
      assert Info.feature_characteristic(ShelfInstance, :nonexistent, :deploymentClass) == nil
    end

    test "Info.feature_characteristic/3 returns nil for unknown characteristic" do
      assert Info.feature_characteristic(ShelfInstance, :spectralManagement, :nonexistent) == nil
    end
  end

  describe "PersistParties" do
    test "bakes parties/0 onto the resource" do
      parties = ShelfInstance.parties()
      assert is_list(parties)
      assert length(parties) == 5
      roles = Enum.map(parties, & &1.role)
      assert :facilitator in roles
      assert :overseer in roles
      assert :provider in roles
      assert :manager in roles
      assert :installer in roles
    end

    test "reference party has reference flag set" do
      provider = Enum.find(ShelfInstance.parties(), &(&1.role == :provider))
      assert provider.reference == true
    end

    test "calculate party has calculate set" do
      manager = Enum.find(ShelfInstance.parties(), &(&1.role == :manager))
      assert manager.calculate == :manager_calc
    end

    test "plural party has constraints" do
      installer = Enum.find(ShelfInstance.parties(), &(&1.role == :installer))
      assert installer.multiple == true
      assert installer.constraints == [min: 1, max: 3]
    end

    test "parties are also accessible via Info" do
      assert length(Info.parties(ShelfInstance)) == 5
      assert Info.parties(CardInstance) == []
    end

    test "Info.party/2 returns the named party declaration by role" do
      p = Info.party(ShelfInstance, :facilitator)
      assert p.role == :facilitator
    end

    test "Info.party/2 returns nil for unknown role" do
      assert Info.party(ShelfInstance, :nonexistent) == nil
    end
  end

  describe "PersistPlaces" do
    test "bakes places/0 onto the resource" do
      places = ShelfInstance.places()
      assert is_list(places)
      assert length(places) == 2
      roles = Enum.map(places, & &1.role)
      assert :installation_site in roles
      assert :billing_address in roles
    end

    test "each place is a PlaceDeclaration struct" do
      [first | _] = ShelfInstance.places()
      assert is_struct(first, PlaceDeclaration)
    end

    test "reference place has reference flag set" do
      billing = Enum.find(ShelfInstance.places(), &(&1.role == :billing_address))
      assert billing.reference == true
    end

    test "places are also accessible via Info" do
      assert length(Info.places(ShelfInstance)) == 2
      assert Info.places(CardInstance) == []
    end

    test "Info.place/2 returns the named place declaration by role" do
      p = Info.place(ShelfInstance, :installation_site)
      assert p.role == :installation_site
    end

    test "Info.place/2 returns nil for unknown role" do
      assert Info.place(ShelfInstance, :nonexistent) == nil
    end
  end

  describe "TransformBehaviour" do
    setup do
      Code.ensure_loaded!(ShelfInstance)
      Code.ensure_loaded!(CardInstance)
      :ok
    end

    test "build_before/1 is defined on shelf" do
      assert function_exported?(ShelfInstance, :build_before, 1)
    end

    test "build_after/2 is defined on shelf" do
      assert function_exported?(ShelfInstance, :build_after, 2)
    end

    test "build_before/1 is defined on card" do
      assert function_exported?(CardInstance, :build_before, 1)
    end

    test "build_after/2 is defined on card" do
      assert function_exported?(CardInstance, :build_after, 2)
    end

    test "action_create injects :specified_by argument into :build" do
      action = Ash.Resource.Info.action(ShelfInstance, :build)
      arg_names = Enum.map(action.arguments, & &1.name)
      assert :specified_by in arg_names
      assert :features in arg_names
      assert :characteristics in arg_names
    end

    test "injected arguments are not public" do
      action = Ash.Resource.Info.action(ShelfInstance, :build)

      injected =
        Enum.filter(action.arguments, &(&1.name in [:specified_by, :features, :characteristics]))

      assert Enum.all?(injected, &(&1.public? == false))
    end

    test "characteristic/1 returns the named characteristic" do
      char = ShelfInstance.characteristic(:shelves)
      assert char.name == :shelves
      assert char.value_type == {:array, Diffo.Test.Characteristic.ShelfCharacteristic}
    end

    test "characteristic/1 returns nil for unknown name" do
      assert ShelfInstance.characteristic(:nonexistent) == nil
    end

    test "feature/1 returns the named feature" do
      feature = ShelfInstance.feature(:spectralManagement)
      assert feature.name == :spectralManagement
      assert feature.is_enabled? == true
    end

    test "feature/1 returns nil for unknown name" do
      assert ShelfInstance.feature(:nonexistent) == nil
    end

    test "feature_characteristic/2 returns the named characteristic within a feature" do
      char = ShelfInstance.feature_characteristic(:spectralManagement, :deploymentClass)
      assert char.name == :deploymentClass
    end

    test "feature_characteristic/2 returns nil for unknown feature" do
      assert ShelfInstance.feature_characteristic(:nonexistent, :deploymentClass) == nil
    end

    test "feature_characteristic/2 returns nil for unknown characteristic" do
      assert ShelfInstance.feature_characteristic(:spectralManagement, :nonexistent) == nil
    end

    test "party/1 returns the named party declaration by role" do
      p = ShelfInstance.party(:facilitator)
      assert p.role == :facilitator
      assert p.multiple == false
    end

    test "party/1 returns nil for unknown role" do
      assert ShelfInstance.party(:nonexistent) == nil
    end

    test "place/1 returns the named place declaration by role" do
      p = ShelfInstance.place(:installation_site)
      assert p.role == :installation_site
      assert p.multiple == false
    end

    test "place/1 returns nil for unknown role" do
      assert ShelfInstance.place(:nonexistent) == nil
    end
  end
end
