# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.InstanceExtension.TransformerTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias Diffo.Test.Shelf
  alias Diffo.Test.Card
  alias Diffo.Provider.Instance.Characteristic
  alias Diffo.Provider.Instance.Feature
  alias Diffo.Provider.Instance.Info
  alias Diffo.Provider.Instance.Extension.PlaceDeclaration

  describe "PersistSpecification" do
    test "bakes specification/0 onto the resource" do
      spec = Shelf.specification()
      assert spec[:id] == "ef016d85-9dbd-429c-84da-1df56cc7dda5"
      assert spec[:name] == "shelf"
      assert spec[:type] == :resourceSpecification
      assert spec[:description] == "A Shelf Resource Instance which contain cards"
      assert spec[:category] == "Network Resource"
      assert spec[:major_version] == 1
    end

    test "card specification is baked correctly" do
      spec = Card.specification()
      assert spec[:id] == "cd29956f-6c68-44cc-bf54-705eb8d2f754"
      assert spec[:name] == "card"
      assert spec[:type] == :resourceSpecification
    end

    test "specification is also accessible via Info" do
      assert Info.specification(Shelf)[:name] == "shelf"
      assert Info.specification(Card)[:name] == "card"
    end
  end

  describe "PersistCharacteristics" do
    test "bakes characteristics/0 onto the resource" do
      chars = Shelf.characteristics()
      assert is_list(chars)
      assert length(chars) == 3
      names = Enum.map(chars, & &1.name)
      assert :shelf in names
      assert :slots in names
      assert :shelves in names
    end

    test "each characteristic is a Characteristic struct" do
      [first | _] = Shelf.characteristics()
      assert is_struct(first, Characteristic)
    end

    test "characteristics are also accessible via Info" do
      assert length(Info.characteristics(Shelf)) == 3
      assert length(Info.characteristics(Card)) == 2
    end

    test "Info.characteristic/2 returns the named characteristic" do
      char = Info.characteristic(Shelf, :shelves)
      assert char.name == :shelves
    end

    test "Info.characteristic/2 returns nil for unknown name" do
      assert Info.characteristic(Shelf, :nonexistent) == nil
    end
  end

  describe "PersistFeatures" do
    test "bakes features/0 onto the resource" do
      features = Shelf.features()
      assert is_list(features)
      assert length(features) == 1
      [feature] = features
      assert feature.name == :spectralManagement
      assert feature.is_enabled? == true
    end

    test "each feature is a Feature struct" do
      [feature] = Shelf.features()
      assert is_struct(feature, Feature)
    end

    test "feature characteristics are nested in the declaration" do
      [feature] = Shelf.features()
      assert length(feature.characteristics) == 2
      char_names = Enum.map(feature.characteristics, & &1.name)
      assert :deploymentClass in char_names
      assert :deploymentClasses in char_names
    end

    test "features are also accessible via Info" do
      assert length(Info.features(Shelf)) == 1
      assert Info.features(Card) == []
    end

    test "Info.feature/2 returns the named feature" do
      feature = Info.feature(Shelf, :spectralManagement)
      assert feature.name == :spectralManagement
    end

    test "Info.feature/2 returns nil for unknown name" do
      assert Info.feature(Shelf, :nonexistent) == nil
    end

    test "Info.feature_characteristic/3 returns the named characteristic within a feature" do
      char = Info.feature_characteristic(Shelf, :spectralManagement, :deploymentClass)
      assert char.name == :deploymentClass
    end

    test "Info.feature_characteristic/3 returns nil for unknown feature" do
      assert Info.feature_characteristic(Shelf, :nonexistent, :deploymentClass) == nil
    end

    test "Info.feature_characteristic/3 returns nil for unknown characteristic" do
      assert Info.feature_characteristic(Shelf, :spectralManagement, :nonexistent) == nil
    end
  end

  describe "PersistParties" do
    test "bakes parties/0 onto the resource" do
      parties = Shelf.parties()
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
      provider = Enum.find(Shelf.parties(), &(&1.role == :provider))
      assert provider.reference == true
    end

    test "calculate party has calculate set" do
      manager = Enum.find(Shelf.parties(), &(&1.role == :manager))
      assert manager.calculate == :manager_calc
    end

    test "plural party has constraints" do
      installer = Enum.find(Shelf.parties(), &(&1.role == :installer))
      assert installer.multiple == true
      assert installer.constraints == [min: 1, max: 3]
    end

    test "parties are also accessible via Info" do
      assert length(Info.parties(Shelf)) == 5
      assert Info.parties(Card) == []
    end

    test "Info.party/2 returns the named party declaration by role" do
      p = Info.party(Shelf, :facilitator)
      assert p.role == :facilitator
    end

    test "Info.party/2 returns nil for unknown role" do
      assert Info.party(Shelf, :nonexistent) == nil
    end
  end

  describe "PersistPlaces" do
    test "bakes places/0 onto the resource" do
      places = Shelf.places()
      assert is_list(places)
      assert length(places) == 2
      roles = Enum.map(places, & &1.role)
      assert :installation_site in roles
      assert :billing_address in roles
    end

    test "each place is a PlaceDeclaration struct" do
      [first | _] = Shelf.places()
      assert is_struct(first, PlaceDeclaration)
    end

    test "reference place has reference flag set" do
      billing = Enum.find(Shelf.places(), &(&1.role == :billing_address))
      assert billing.reference == true
    end

    test "places are also accessible via Info" do
      assert length(Info.places(Shelf)) == 2
      assert Info.places(Card) == []
    end

    test "Info.place/2 returns the named place declaration by role" do
      p = Info.place(Shelf, :installation_site)
      assert p.role == :installation_site
    end

    test "Info.place/2 returns nil for unknown role" do
      assert Info.place(Shelf, :nonexistent) == nil
    end
  end

  describe "TransformBehaviour" do
    setup do
      Code.ensure_loaded!(Shelf)
      Code.ensure_loaded!(Card)
      :ok
    end

    test "build_before/1 is defined on shelf" do
      assert function_exported?(Shelf, :build_before, 1)
    end

    test "build_after/2 is defined on shelf" do
      assert function_exported?(Shelf, :build_after, 2)
    end

    test "build_before/1 is defined on card" do
      assert function_exported?(Card, :build_before, 1)
    end

    test "build_after/2 is defined on card" do
      assert function_exported?(Card, :build_after, 2)
    end

    test "action_create injects :specified_by argument into :build" do
      action = Ash.Resource.Info.action(Shelf, :build)
      arg_names = Enum.map(action.arguments, & &1.name)
      assert :specified_by in arg_names
      assert :features in arg_names
      assert :characteristics in arg_names
    end

    test "injected arguments are not public" do
      action = Ash.Resource.Info.action(Shelf, :build)
      injected = Enum.filter(action.arguments, &(&1.name in [:specified_by, :features, :characteristics]))
      assert Enum.all?(injected, &(&1.public? == false))
    end

    test "characteristic/1 returns the named characteristic" do
      char = Shelf.characteristic(:shelves)
      assert char.name == :shelves
      assert char.value_type == {:array, Diffo.Test.ShelfValue}
    end

    test "characteristic/1 returns nil for unknown name" do
      assert Shelf.characteristic(:nonexistent) == nil
    end

    test "feature/1 returns the named feature" do
      feature = Shelf.feature(:spectralManagement)
      assert feature.name == :spectralManagement
      assert feature.is_enabled? == true
    end

    test "feature/1 returns nil for unknown name" do
      assert Shelf.feature(:nonexistent) == nil
    end

    test "feature_characteristic/2 returns the named characteristic within a feature" do
      char = Shelf.feature_characteristic(:spectralManagement, :deploymentClass)
      assert char.name == :deploymentClass
    end

    test "feature_characteristic/2 returns nil for unknown feature" do
      assert Shelf.feature_characteristic(:nonexistent, :deploymentClass) == nil
    end

    test "feature_characteristic/2 returns nil for unknown characteristic" do
      assert Shelf.feature_characteristic(:spectralManagement, :nonexistent) == nil
    end

    test "party/1 returns the named party declaration by role" do
      p = Shelf.party(:facilitator)
      assert p.role == :facilitator
      assert p.multiple == false
    end

    test "party/1 returns nil for unknown role" do
      assert Shelf.party(:nonexistent) == nil
    end

    test "place/1 returns the named place declaration by role" do
      p = Shelf.place(:installation_site)
      assert p.role == :installation_site
      assert p.multiple == false
    end

    test "place/1 returns nil for unknown role" do
      assert Shelf.place(:nonexistent) == nil
    end
  end
end
