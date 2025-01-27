defmodule DiffoTest do
  @moduledoc false
  use ExUnit.Case
  doctest Diffo
  doctest Diffo.Uuid
  doctest Diffo.Provider.Specification
  doctest Diffo.Provider.Instance
  doctest Diffo.Provider.Service

  test "greets the world" do
    assert Diffo.hello() == :world
  end
end
