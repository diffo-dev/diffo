# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.InstanceExtension.FeatureTest do
  @moduledoc false
  use ExUnit.Case
  alias Diffo.Test.Servo
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
    test "create resource with fails when feature characteristic value type invalid" do
      {:error, error} = Servo.build_invalid_feature_characteristic(%{})
      %Ash.Error.Invalid{errors: errors} = error

      assert hd(errors).message ==
               "couldn't create feature characteristic with value of unknown type Elixir.InvalidValue"
    end

    test "create resource with array feature characteristic - success" do
      {:ok, shelf} = Parties.build_shelf_with_installer()

      spectral = Enum.find(shelf.features, fn f -> f.name == :spectralManagement end)
      deployment_classes = Enum.find(spectral.characteristics, fn c -> c.name == :deploymentClasses end)

      assert deployment_classes.is_array == true
      assert deployment_classes.values == []
      assert Diffo.Unwrap.unwrap(deployment_classes) == []
    end
  end
end
