defmodule DiffoTest do
  @moduledoc false
  use ExUnit.Case
  doctest Diffo
  doctest Diffo.Uuid
  doctest Diffo.Provider.Service
  doctest Diffo.Provider.Specification
  doctest Diffo.Provider.Instance
  doctest Diffo.Provider.Relationship
end
