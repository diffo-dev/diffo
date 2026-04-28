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

  describe "TransformSpecification" do
    test "bakes specification options into __diffo_specification__/0" do
      spec = Shelf.__diffo_specification__()
      assert spec[:id] == "ef016d85-9dbd-429c-84da-1df56cc7dda5"
      assert spec[:name] == "shelf"
      assert spec[:type] == :resourceSpecification
      assert spec[:description] == "A Shelf Resource Instance which contain cards"
      assert spec[:category] == "Network Resource"
    end

    test "card specification is also baked correctly" do
      spec = Card.__diffo_specification__()
      assert spec[:id] == "cd29956f-6c68-44cc-bf54-705eb8d2f754"
      assert spec[:name] == "card"
      assert spec[:type] == :resourceSpecification
    end
  end

  describe "TransformCharacteristics" do
    test "bakes characteristic declarations into __diffo_characteristics__/0" do
      chars = Shelf.__diffo_characteristics__()
      assert is_list(chars)
      assert length(chars) == 3
      names = Enum.map(chars, & &1.name)
      assert :shelf in names
      assert :slots in names
      assert :shelves in names
    end

    test "each characteristic is a Characteristic struct" do
      [first | _] = Shelf.__diffo_characteristics__()
      assert is_struct(first, Characteristic)
    end

    test "card characteristics are baked" do
      chars = Card.__diffo_characteristics__()
      assert length(chars) == 2
      names = Enum.map(chars, & &1.name)
      assert :card in names
      assert :ports in names
    end
  end

  describe "TransformFeatures" do
    test "bakes feature declarations into __diffo_features__/0" do
      features = Shelf.__diffo_features__()
      assert is_list(features)
      assert length(features) == 1
      [feature] = features
      assert feature.name == :spectralManagement
      assert feature.is_enabled? == true
    end

    test "each feature is a Feature struct" do
      [feature] = Shelf.__diffo_features__()
      assert is_struct(feature, Feature)
    end

    test "feature characteristics are nested in the feature declaration" do
      [feature] = Shelf.__diffo_features__()
      assert length(feature.characteristics) == 2
      char_names = Enum.map(feature.characteristics, & &1.name)
      assert :deploymentClass in char_names
      assert :deploymentClasses in char_names
    end

    test "card has no features" do
      assert Card.__diffo_features__() == []
    end
  end

  describe "TransformParties" do
    test "bakes party declarations into __diffo_party_declarations__/0" do
      parties = Shelf.__diffo_party_declarations__()
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
      parties = Shelf.__diffo_party_declarations__()
      provider = Enum.find(parties, &(&1.role == :provider))
      assert provider.reference == true
    end

    test "calculate party has calculate set" do
      parties = Shelf.__diffo_party_declarations__()
      manager = Enum.find(parties, &(&1.role == :manager))
      assert manager.calculate == :manager_calc
    end

    test "plural party has constraints" do
      parties = Shelf.__diffo_party_declarations__()
      installer = Enum.find(parties, &(&1.role == :installer))
      assert installer.multiple == true
      assert installer.constraints == [min: 1, max: 3]
    end

    test "card has no parties" do
      assert Card.__diffo_party_declarations__() == []
    end
  end

  describe "TransformBuildActions" do
    test "__diffo_build_before__/1 is defined on shelf" do
      assert function_exported?(Shelf, :__diffo_build_before__, 1)
    end

    test "__diffo_build_after__/2 is defined on shelf" do
      assert function_exported?(Shelf, :__diffo_build_after__, 2)
    end

    test "__diffo_build_before__/1 is defined on card" do
      assert function_exported?(Card, :__diffo_build_before__, 1)
    end

    test "__diffo_build_after__/2 is defined on card" do
      assert function_exported?(Card, :__diffo_build_after__, 2)
    end
  end
end
