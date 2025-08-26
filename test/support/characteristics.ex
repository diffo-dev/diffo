defmodule Diffo.Test.Characteristics do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  Characteristics - Test support for Characteristics
  """
  import Outstand
  import ExUnit.Assertions

  def check_values(expected_values, instance)
      when is_list(expected_values) and is_struct(instance) do
    Enum.each(
      expected_values,
      fn {name, expected} ->
        characteristic = Enum.find(instance.characteristics, &(Map.get(&1, :name) == name))
        assert characteristic
        assert characteristic.value

        cond do
          is_list(expected) ->
            Enum.each(expected,
              fn {field, expected_value} ->
                assert expected_value --- Map.get(characteristic.value, field) == nil
              end)
          true ->
            assert expected --- characteristic.value == nil
        end
      end
    )
  end
end
