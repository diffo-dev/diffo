# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Extension.PartyTransformerTest do
  @moduledoc false
  use ExUnit.Case, async: true, async: true
  @moduletag :domain_extended

  alias Diffo.Test.Party.Enterprise
  alias Diffo.Test.Party.Person
  alias Diffo.Provider.Extension.InstanceRole
  alias Diffo.Provider.Extension.PartyRole
  alias Diffo.Provider.Extension.PlaceRole
  alias Diffo.Provider.Party.Extension.Info

  describe "PersistInstances" do
    test "bakes instances/0 onto the resource" do
      roles = Enterprise.instances()
      assert is_list(roles)
      assert length(roles) == 1
      assert hd(roles).role == :facilitator
    end

    test "each instance role is an InstanceRole struct" do
      assert is_struct(hd(Enterprise.instances()), InstanceRole)
    end

    test "instances are also accessible via Info" do
      assert length(Info.instances(Enterprise)) == 1
      assert length(Info.instances(Person)) == 1
    end

    test "Person instances/0 bakes correctly" do
      roles = Person.instances()
      assert length(roles) == 1
      assert hd(roles).role == :overseer
    end
  end

  describe "PersistParties" do
    test "bakes parties/0 onto the resource" do
      roles = Enterprise.parties()
      assert is_list(roles)
      assert length(roles) == 1
      assert hd(roles).role == :employer
    end

    test "each party role is a PartyRole struct" do
      assert is_struct(hd(Enterprise.parties()), PartyRole)
    end

    test "parties are also accessible via Info" do
      assert length(Info.parties(Enterprise)) == 1
      assert length(Info.parties(Person)) == 1
    end

    test "Person parties/0 bakes correctly" do
      roles = Person.parties()
      assert length(roles) == 1
      assert hd(roles).role == :manager
    end
  end

  describe "PersistPlaces" do
    test "bakes places/0 onto the resource" do
      roles = Enterprise.places()
      assert is_list(roles)
      assert length(roles) == 1
      assert hd(roles).role == :headquarters
    end

    test "each place role is a PlaceRole struct" do
      assert is_struct(hd(Enterprise.places()), PlaceRole)
    end

    test "places are also accessible via Info" do
      assert length(Info.places(Enterprise)) == 1
      assert length(Info.places(Person)) == 1
    end

    test "Person places/0 bakes correctly" do
      roles = Person.places()
      assert length(roles) == 1
      assert hd(roles).role == :residence
    end
  end
end
