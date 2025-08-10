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
  doctest Diffo.Provider.Place
  doctest Diffo.Provider.PlaceRef
  doctest Diffo.Provider.Party
  doctest Diffo.Provider.PartyRef
  doctest Diffo.Provider.ExternalIdentifier
  doctest Diffo.Provider.ProcessStatus
  doctest Diffo.Provider.Note
  doctest Diffo.Provider.EntityRef
  doctest Diffo.Provider.Entity
  doctest Diffo.Provider.Outstanding
end
