defmodule Diffo.Provider.Outstanding do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference
  Copyright Matt Beanland beanland@live.com.au

  Outstanding - utilities relating to Outstanding
  """

  @doc """
  Accumulates outstanding instance with list by key
  Outstanding, expected and actual are Diffo.Provider.Instance structs
    ## Examples
    iex> expected_instance = %Diffo.Provider.Instance{parties: [%Diffo.Provider.PartyRef{party_id: nil, name: nil, role: :Consumer, type: "PartyRef", referredType: "Entity"}]}
    iex> actual_instance = %Diffo.Provider.Instance{parties: [%Diffo.Provider.PartyRef{party_id: "T5_CONNECTIVITY", name: nil, role: :Consumer, type: "PartyRef", referredType: "Entity"}]}
    iex> Diffo.Provider.Outstanding.instance_list_by_key(nil, expected_instance, actual_instance, :parties, :role)
    nil
  """
  def instance_list_by_key(outstanding, expected, actual, list, key) do
    # assemble keyword lists of expected and actual parties
    expected_keywords = Keyword.new(Map.get(expected, list), fn element -> {Map.get(element, key), element} end)
    actual_keywords = Keyword.new(Map.get(actual, list), fn element -> {Map.get(element, key), element} end)
    outstanding_keywords = Outstanding.outstanding(expected_keywords, actual_keywords)
    |> IO.inspect(label: "outstanding_keywords")
    if (outstanding_keywords == nil) do
      outstanding
    else
      # accumulate outstanding, with outstanding result back as a list
      if (outstanding == nil) do
        Map.put(%Diffo.Provider.Instance{}, :parties, Keyword.values(outstanding_keywords))
      else
        outstanding |> Map.put(:parties, Keyword.values(outstanding_keywords))
      end
    end
  end
end
