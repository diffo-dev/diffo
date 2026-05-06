# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.InstanceExtension.FeatureTest do
  @moduledoc false
  use ExUnit.Case
  alias Diffo.Test.Parties

  setup_all do
    AshNeo4j.BoltyHelper.start()
  end

  setup do
    on_exit(fn ->
      AshNeo4j.Neo4jHelper.delete_all()
    end)
  end

  describe "feature" do
    test "create resource with array feature characteristic - success" do
      {:ok, shelf} = Parties.build_shelf_with_installer()

      spectral = Enum.find(shelf.features, fn f -> f.name == :spectralManagement end)

      deployment_classes =
        Enum.find(spectral.characteristics, fn c -> c.name == :deploymentClasses end)

      assert deployment_classes.is_array == true
      assert deployment_classes.values == []
      assert Diffo.Unwrap.unwrap(deployment_classes) == []
    end
  end
end
