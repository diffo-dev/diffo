defmodule Diffo.Util do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference
  Copyright Matt Beanland beanland@live.com.au

  Util - utility methods
  """

  @doc """
  Deletes value to map if empty []
  ## Examples
    iex> Diffo.Util.delete_if_empty(%{serviceCharacteristic: [%{name: :port, value: 1}]}, :serviceCharacteristic)
    %{serviceCharacteristic: [%{name: :port, value: 1}]}

    iex> Diffo.Util.delete_if_empty(%{serviceCharacteristic: []}, :serviceCharacteristic)
    %{}

  """
  def delete_if_empty(map, key) when is_map(map) do
    if (key != nil) and Map.get(map, key) == [] do
      Map.delete(map, key)
    else
      map
    end
  end

  @doc """
  Adds value to map if not empty []
  ## Examples
    iex> Diffo.Util.put_not_empty(%{}, :serviceCharacteristic, [%{name: :port, value: 1}])
    %{serviceCharacteristic: [%{name: :port, value: 1}]}

    iex> Diffo.Util.put_not_empty(%{}, :key, [])
    %{}

    iex> Diffo.Util.put_not_empty(%{}, nil, [%{name: :port, value: 1}])
    %{}

  """
  def put_not_empty(map, key, value) when is_map(map) do
    if (key != nil) and (value != []) do
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

    iex> Diffo.Util.ensure_not_nil(%{category: :connectivity}, nil, :physical)
    %{category: :connectivity}

    iex> Diffo.Util.ensure_not_nil(%{category: :connectivity}, :category, nil)
    %{}

  """
  def ensure_not_nil(map, key, value) when is_map(map) do
    if (key == nil) do
      map
    else
      if (value != nil) do
        Map.put(map, key, value)
      else
        Map.delete(map, key)
      end
    end
  end

  @doc """
  Compares two terms
  ## Examples
    iex> Diffo.Util.compare("a", "a")
    :eq
    iex> Diffo.Util.compare("b", "a")
    :gt
    iex> Diffo.Util.compare("a", "b")
    :lt
  """
  def compare(a, b) do
    cond do
      a < b -> :lt
      a > b -> :gt
      true -> :eq
    end
  end

  @doc """
  true if the datetime is close to (+/- 5 mins) from now
  ## Examples
    iex> Diffo.Util.close_to_now?(DateTime.utc_now() |> DateTime.shift(minute: 4))
    true

    iex> Diffo.Util.close_to_now?(DateTime.utc_now() |> DateTime.shift(minute: -4))
    true

    iex> Diffo.Util.close_to_now?(DateTime.utc_now() |> DateTime.shift(minute: 6))
    false

    iex> Diffo.Util.close_to_now?(DateTime.utc_now() |> DateTime.shift(minute: -6))
    false

  """
  def close_to_now?(datetime) do
    now = DateTime.utc_now()
    future = DateTime.shift(now, minute: 5)
    past = DateTime.shift(now, minute: -5)
    DateTime.after?(datetime, past) and DateTime.before?(datetime, future)
  end

  @doc """
  true if the datetime is past, more than 5 mins before now
    ## Examples
    iex> Diffo.Util.past?(DateTime.utc_now() |> DateTime.shift(minute: -6))
    true

    iex> Diffo.Util.past?(DateTime.utc_now() |> DateTime.shift(minute: -4))
    false
  """

  def past?(datetime) do
    now = DateTime.utc_now()
    past = DateTime.shift(now, minute: -5)
    DateTime.before?(datetime, past)
  end

  @doc """
  true if the datetime is future, more than 5 mins after now
  ## Examples
    iex> Diffo.Util.future?(DateTime.utc_now() |> DateTime.shift(minute: 6))
    true

    iex> Diffo.Util.future?(DateTime.utc_now() |> DateTime.shift(minute: 4))
    false
  """

  def future?(datetime) do
    now = DateTime.utc_now()
    future = DateTime.shift(now, minute: 5)
    DateTime.after?(datetime, future)
  end

  @doc """
  realises a datetime from now conforming to the summary
  ## Examples
    iex> datetime = Diffo.Util.datetime(:now)
    iex> Diffo.Util.summarise(datetime)
    :now

    iex> datetime = Diffo.Util.datetime(:future)
    iex> Diffo.Util.summarise(datetime)
    :future

    iex> datetime = Diffo.Util.datetime(:past)
    iex> Diffo.Util.summarise(datetime)
    :past

  """
  def datetime(summary) do
    now = DateTime.utc_now(:millisecond)
    case summary do
      :now -> now
      :future -> DateTime.shift(now, day: 1)
      :past -> DateTime.shift(now, day: -1)
      _ -> :error
    end
  end

  @doc """
  summarize datetimes in relation to now
  ## Examples
    iex> Diffo.Util.summarise(DateTime.utc_now() |> DateTime.shift(minute: 4))
    :now

    iex> Diffo.Util.summarise(DateTime.utc_now() |> DateTime.shift(minute: -4))
    :now

    iex> Diffo.Util.summarise(DateTime.utc_now() |> DateTime.shift(minute: 6))
    :future

    iex> Diffo.Util.summarise(DateTime.utc_now() |> DateTime.shift(minute: -6))
    :past

  """

  def summarise(datetime) do
    cond do
      close_to_now?(datetime) -> :now
      future?(datetime) -> :future
      past?(datetime) -> :past
    end
  end

  @doc """
  Summarise ISO8601 dates, by comparing them with now, in a payload
  ## Examples
    iex> now = DateTime.utc_now()
    iex> future = DateTime.shift(now, minute: 6)
    iex> past = DateTime.shift(now, minute: -6)
    iex> payload = Diffo.Util.to_iso8601(past) <> "," <> Diffo.Util.to_iso8601(now) <> "," <> Diffo.Util.to_iso8601(future)
    iex> Diffo.Util.summarise_dates(payload)
    "past,now,future"

  """

  def summarise_dates(payload) do
   Regex.replace(~r/\d{4}-\d{2}-\d{2}[T ]\d{2}:\d{2}:\d{2}.\d{3}Z/, payload,
      fn iso8601 ->
        case DateTime.from_iso8601(iso8601) do
          {:ok, datetime, 0} -> Diffo.Util.summarise(datetime)
          {:error, error} -> error
        end
        |> Atom.to_string()
      end)
  end

  @doc """
  Convert a dateime to iso8601, with millisecond resolution
  """
  def to_iso8601(datetime) do
    if (datetime == nil) do
      nil
    else
      DateTime.to_iso8601(DateTime.truncate(datetime, :millisecond))
    end
  end
end
