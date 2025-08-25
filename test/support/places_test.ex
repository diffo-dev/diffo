defmodule Diffo.Support.PlacesTest do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  PlacesTest - Test support for Places
  """

  import ExUnit.Assertions

  def check_places(expected_places, instance)
       when is_list(expected_places) and is_struct(instance) do
    Enum.zip_reduce(expected_places, instance.places, [], fn _expected_place,
                                                             actual_place_ref,
                                                             _acc ->
      assert is_struct(actual_place_ref, Diffo.Provider.PlaceRef)
      refute is_nil(actual_place_ref.place_id)
      assert is_struct(actual_place_ref.place, Diffo.Provider.Place)

      assert AshNeo4j.Neo4jHelper.nodes_relate_how?(
               :Instance,
               %{uuid: instance.id},
               :PlaceRef,
               %{uuid: actual_place_ref.id},
               :LOCATED_BY,
               :outgoing
             )

      assert AshNeo4j.Neo4jHelper.nodes_relate_how?(
               :PlaceRef,
               %{uuid: actual_place_ref.id},
               :Place,
               %{key: actual_place_ref.place_id},
               :LOCATED_BY,
               :outgoing
             )
    end)
  end
end
