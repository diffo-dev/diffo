# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.InstanceExtension.FeatureTest do
  @moduledoc false
  use ExUnit.Case, async: true
  alias Diffo.Test.Parties

  setup do
    AshNeo4j.Sandbox.checkout()
    on_exit(&AshNeo4j.Sandbox.rollback/0)
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
