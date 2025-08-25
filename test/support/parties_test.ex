defmodule Diffo.Support.PartiesTest do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  PartiesTest - Test support for Parties
  """

  import ExUnit.Assertions

  def check_parties(expected_parties, instance)
       when is_list(expected_parties) and is_struct(instance) do
    Enum.zip_reduce(expected_parties, instance.parties, [], fn _expected_party,
                                                               actual_party_ref,
                                                               _acc ->
      assert is_struct(actual_party_ref, Diffo.Provider.PartyRef)
      refute is_nil(actual_party_ref.party_id)
      assert is_struct(actual_party_ref.party, Diffo.Provider.Party)

      assert AshNeo4j.Neo4jHelper.nodes_relate_how?(
               :Instance,
               %{uuid: instance.id},
               :PartyRef,
               %{uuid: actual_party_ref.id},
               :INVOLVED_WITH,
               :outgoing
             )

      assert AshNeo4j.Neo4jHelper.nodes_relate_how?(
               :PartyRef,
               %{uuid: actual_party_ref.id},
               :Party,
               %{key: actual_party_ref.party_id},
               :INVOLVED_WITH,
               :outgoing
             )
    end)
  end
end
