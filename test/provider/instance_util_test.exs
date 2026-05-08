# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Instance.UtilTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias Diffo.Provider.Instance.Util

  describe "derive_type/1" do
    test "service specification" do
      assert Util.derive_type(:serviceSpecification) == :service
    end

    test "resource specification" do
      assert Util.derive_type(:resourceSpecification) == :resource
    end

    test "unknown returns nil" do
      assert Util.derive_type(:other) == nil
    end
  end

  describe "derive_feature_list_name/1" do
    test "service" do
      assert Util.derive_feature_list_name(:service) == :feature
    end

    test "resource" do
      assert Util.derive_feature_list_name(:resource) == :activationFeature
    end
  end

  describe "derive_characteristic_list_name/1" do
    test "service" do
      assert Util.derive_characteristic_list_name(:service) == :serviceCharacteristic
    end

    test "resource" do
      assert Util.derive_characteristic_list_name(:resource) == :resourceCharacteristic
    end
  end

  describe "derive_create_date_name/1" do
    test "service" do
      assert Util.derive_create_date_name(:service) == :serviceDate
    end

    test "resource" do
      assert Util.derive_create_date_name(:resource) == nil
    end
  end

  describe "derive_start_date_name/1" do
    test "service" do
      assert Util.derive_start_date_name(:service) == :startDate
    end

    test "resource" do
      assert Util.derive_start_date_name(:resource) == :startOperatingDate
    end
  end

  describe "derive_end_date_name/1" do
    test "service" do
      assert Util.derive_end_date_name(:service) == :endDate
    end

    test "resource" do
      assert Util.derive_end_date_name(:resource) == :endOperatingDate
    end
  end

  describe "other/1" do
    test "actual returns expected" do
      assert Util.other(:actual) == :expected
    end

    test "expected returns actual" do
      assert Util.other(:expected) == :actual
    end

    test "unknown returns nil" do
      assert Util.other(:unknown) == nil
    end
  end
end
