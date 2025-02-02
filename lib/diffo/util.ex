defmodule Diffo.Util do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference
  Copyright Matt Beanland beanland@live.com.au

  Util - utility methods
  """

  @doc """
  Adds value to map if not empty []
  ## Examples
    iex> Diffo.Util.put_not_empty(%{}, :serviceCharacteristic, [%{name: :port, value: 1}])
    %{serviceCharacteristic: [%{name: :port, value: 1}]}

    iex> Diffo.Util.put_not_empty(%{}, :key, [])
    %{}

  """
  def put_not_empty(map, key, value) when is_map(map) do
    if (value != []) do
      Map.put(map, key, value)
    else
      map
    end
  end
end
