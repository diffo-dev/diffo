# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Extension.InfoTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias Diffo.Provider.Extension.Info

  describe "instance?/1" do
    test "returns true for a BaseInstance-derived resource" do
      assert Info.instance?(Diffo.Test.Instance.ShelfInstance) == true
    end

    test "returns true for the base Instance resource" do
      assert Info.instance?(Diffo.Provider.Instance) == true
    end

    test "returns false for a BaseParty-derived resource" do
      assert Info.instance?(Diffo.Test.Party.Organization) == false
    end

    test "returns false for a BasePlace-derived resource" do
      assert Info.instance?(Diffo.Test.Place.GeographicSite) == false
    end

    test "returns false for a non-existent module" do
      assert Info.instance?(NonExistent.Module) == false
    end
  end

  describe "party?/1" do
    test "returns true for a BaseParty-derived resource" do
      assert Info.party?(Diffo.Test.Party.Organization) == true
    end

    test "returns true for the base Party resource" do
      assert Info.party?(Diffo.Provider.Party) == true
    end

    test "returns false for a BaseInstance-derived resource" do
      assert Info.party?(Diffo.Test.Instance.ShelfInstance) == false
    end

    test "returns false for a BasePlace-derived resource" do
      assert Info.party?(Diffo.Test.Place.GeographicSite) == false
    end

    test "returns false for a non-existent module" do
      assert Info.party?(NonExistent.Module) == false
    end
  end

  describe "place?/1" do
    test "returns true for a BasePlace-derived resource" do
      assert Info.place?(Diffo.Test.Place.GeographicSite) == true
    end

    test "returns true for the base Place resource" do
      assert Info.place?(Diffo.Provider.Place) == true
    end

    test "returns false for a BaseInstance-derived resource" do
      assert Info.place?(Diffo.Test.Instance.ShelfInstance) == false
    end

    test "returns false for a BaseParty-derived resource" do
      assert Info.place?(Diffo.Test.Party.Organization) == false
    end

    test "returns false for a non-existent module" do
      assert Info.place?(NonExistent.Module) == false
    end
  end
end
