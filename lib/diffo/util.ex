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

  @doc """
  Ensures value in map is not nil. If existing and replacement value both nil removes key
  ## Examples
    iex> Diffo.Util.ensure_not_nil(%{}, :category, :connectivity)
    %{category: :connectivity}

    iex> Diffo.Util.ensure_not_nil(%{category: :connectivity}, :category, :physical)
    %{category: :physical}

    iex> Diffo.Util.ensure_not_nil(%{}, :category, nil)
    %{}

  """
  def ensure_not_nil(map, key, value) when is_map(map) do
    if (value != nil) do
      Map.put(map, key, value)
    else
      Map.delete(map,key)
    end
  end

  def compare(a, b) do
    cond do
      a < b -> :lt
      a > b -> :gt
      true -> :eq
    end
  end
end
