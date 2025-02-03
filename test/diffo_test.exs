defmodule DiffoTest do
  @moduledoc false
  use ExUnit.Case
  doctest Diffo
  doctest Diffo.Uuid
  doctest Diffo.Util
  doctest Diffo.Provider.Reference
  doctest Diffo.Provider.Service
  doctest Diffo.Provider.Specification
  doctest Diffo.Provider.Instance
  doctest Diffo.Provider.Relationship
  doctest Diffo.Provider.Characteristic
  doctest Diffo.Provider.Feature
end
