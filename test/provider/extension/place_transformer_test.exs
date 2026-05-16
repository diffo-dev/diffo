# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Extension.PlaceTransformerTest do
  @moduledoc false
  use ExUnit.Case, async: true, async: true

  alias Diffo.Test.GeographicSite
  alias Diffo.Provider.Extension.InstanceRole
  alias Diffo.Provider.Extension.PartyRole
  alias Diffo.Provider.Extension.PlaceRole
  alias Diffo.Provider.Place.Extension.Info

  describe "PersistInstances" do
    test "bakes instances/0 onto the resource" do
      roles = GeographicSite.instances()
      assert is_list(roles)
      assert length(roles) == 1
      assert hd(roles).role == :installed_at
    end

    test "each instance role is an InstanceRole struct" do
      assert is_struct(hd(GeographicSite.instances()), InstanceRole)
    end

    test "instances are also accessible via Info" do
      assert length(Info.instances(GeographicSite)) == 1
    end
  end

  describe "PersistParties" do
    test "bakes parties/0 onto the resource" do
      roles = GeographicSite.parties()
      assert is_list(roles)
      assert length(roles) == 1
      assert hd(roles).role == :managed_by
    end

    test "each party role is a PartyRole struct" do
      assert is_struct(hd(GeographicSite.parties()), PartyRole)
    end

    test "parties are also accessible via Info" do
      assert length(Info.parties(GeographicSite)) == 1
    end
  end

  describe "PersistPlaces" do
    test "bakes places/0 onto the resource" do
      roles = GeographicSite.places()
      assert is_list(roles)
      assert length(roles) == 1
      assert hd(roles).role == :contained_in
    end

    test "each place role is a PlaceRole struct" do
      assert is_struct(hd(GeographicSite.places()), PlaceRole)
    end

    test "places are also accessible via Info" do
      assert length(Info.places(GeographicSite)) == 1
    end
  end
end
