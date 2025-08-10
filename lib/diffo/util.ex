defmodule Diffo.Util do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference
  Copyright Matt Beanland beanland@live.com.au

  Util - utility methods
  """

  @doc """
  Renames map key, unless old value is empty
  ## Examples
    iex> Diffo.Util.rename_ensure_not_empty(%{characteristic: [%{name: :port, value: 1}]}, :characteristic, :serviceCharacteristic)
    %{serviceCharacteristic: [%{name: :port, value: 1}]}

    iex> Diffo.Util.rename_ensure_not_empty(%{characteristic: []}, :characteristic, :serviceCharacteristic)
    %{}

    iex> Diffo.Util.rename_ensure_not_empty(%{}, :characteristic, :serviceCharacteristic)
    %{}
  """
  def rename_ensure_not_empty(map, key, new_key) when is_map(map) do
    {value, map} = Map.pop(map, key)

    if value != [] and value != nil do
      Map.put(map, new_key, value)
    else
      map
    end
  end

  @doc """
  Deletes map value if empty []
  ## Examples
    iex> Diffo.Util.delete_if_empty(%{serviceCharacteristic: [%{name: :port, value: 1}]}, :serviceCharacteristic)
    %{serviceCharacteristic: [%{name: :port, value: 1}]}

    iex> Diffo.Util.delete_if_empty(%{serviceCharacteristic: []}, :serviceCharacteristic)
    %{}

  """
  def delete_if_empty(map, key) when is_map(map) do
    if key != nil and Map.get(map, key) == [] do
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
    if key != nil and value != [] do
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
    if key == nil do
      map
    else
      if value != nil do
        Map.put(map, key, value)
      else
        Map.delete(map, key)
      end
    end
  end

  @spec compare(any(), any()) :: :eq | :gt | :lt
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
    Regex.replace(~r/\d{4}-\d{2}-\d{2}[T ]\d{2}:\d{2}:\d{2}.\d{3}Z/, payload, fn iso8601 ->
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
    if datetime == nil do
      nil
    else
      DateTime.to_iso8601(DateTime.truncate(datetime, :millisecond))
    end
  end

  @doc """
  Gets a value from a list of tuples, or nil
  ## Examples
    iex> list = [a: 1, b: 2]
    iex> Diffo.Util.get(list, :b)
    2
    iex> Diffo.Util.get(list, :c)
    nil
  """
  def get(list, tuple_key) when is_list(list) do
    case List.keyfind(list, tuple_key, 0) do
      {^tuple_key, value} -> value
      nil -> nil
    end
  end

  @doc """
  Adds a tuple or updates the existing tuple value in a list of tuples
  ## Examples
    iex> list = [a: 1, b: 2]
    iex> Diffo.Util.set(list, :c, 3)
    [a: 1, b: 2, c: 3]
    iex> Diffo.Util.set(list, :b, 3)
    [a: 1, b: 3]
    iex> Diffo.Util.set(list, :c, nil)
    [a: 1, b: 2]
    iex> Diffo.Util.set(list, :b, nil)
    [a: 1]
    iex> Diffo.Util.set(list, :c, [])
    [a: 1, b: 2]
    iex> Diffo.Util.set(list, :b, [])
    [a: 1]
  """
  def set(list, tuple_key, tuple_value) when is_list(list) do
    if tuple_value == nil or tuple_value == [] do
      List.keydelete(list, tuple_key, 0)
    else
      List.keystore(list, tuple_key, 0, {tuple_key, tuple_value})
    end
  end

  @doc """
  Removes a tuple from a list of tuples
    ## Examples
    iex> list = [a: [], b: [1], c: nil]
    iex> Diffo.Util.remove(list, :a)
    [b: [1], c: nil]
    iex> Diffo.Util.remove(list, :b)
    [a: [], c: nil]
    iex> Diffo.Util.remove(list, :c)
    [a: [], b: [1]]
    iex> Diffo.Util.remove(list, :d)
    [a: [], b: [1], c: nil]
  """
  def remove(list, tuple_key) when is_list(list) do
    List.keydelete(list, tuple_key, 0)
  end

  @doc """
  Suppresses a tuple from a list of tuples if nil or empty
    ## Examples
    iex> list = [a: [], b: [1], c: nil]
    iex> Diffo.Util.suppress(list, :a)
    [b: [1], c: nil]
    iex> Diffo.Util.suppress(list, :b)
    [a: [], b: [1], c: nil]
    iex> Diffo.Util.suppress(list, :c)
    [a: [], b: [1]]
    iex> Diffo.Util.suppress(list, :d)
    [a: [], b: [1], c: nil]
  """
  def suppress(list, tuple_key) when is_list(list) do
    value = get(list, tuple_key)

    case value do
      [] -> List.keydelete(list, tuple_key, 0)
      nil -> List.keydelete(list, tuple_key, 0)
      _ -> list
    end
  end

  @doc """
  Renames a tuple in a list, preserving its value and position
    ## Examples
    iex> list = [a: 1, b: 2, d: 3]
    iex> Diffo.Util.rename(list, :b, :c)
    [a: 1, c: 2, d: 3]
    iex> Diffo.Util.rename(list, :c, :e)
    [a: 1, b: 2, d: 3]
    iex> Diffo.Util.rename(list, :b, nil)
    [a: 1, d: 3]

  """
  def rename(list, tuple_key, nil) when is_list(list) do
    list |> List.keydelete(tuple_key, 0)
  end

  def rename(list, tuple_key, new_tuple_key) when is_list(list) do
    value = get(list, tuple_key)
    list |> List.keyreplace(tuple_key, 0, {new_tuple_key, value})
  end

  @doc """
  Suppresses or renames, using suppress |> rename
    ## Examples
    iex> list = [a: [], b: [1], c: nil]
    iex> Diffo.Util.suppress_rename(list, :a, :d)
    [b: [1], c: nil]

    iex> list = [a: [1], b: [1], c: nil]
    iex> Diffo.Util.suppress_rename(list, :a, :d)
    [d: [1], b: [1], c: nil]
    iex> Diffo.Util.suppress_rename(list, :a, nil)
    [b: [1], c: nil]

  """
  def suppress_rename(list, tuple_key, new_tuple_key) when is_list(list) do
    suppress(list, tuple_key) |> rename(tuple_key, new_tuple_key)
  end

  @doc """
  Extracts value from map in list of tuples, and sets if not nil
    ## Examples
    iex> duration = Duration.new!(month: 1)
    iex> list = [duration: duration]
    iex> result = Diffo.Util.extract_suppress(list, :duration, :month, :months)
    iex> List.last(result)
    {:months, 1}
  """
  def extract_suppress(list, tuple_key, map_key, new_tuple_key) when is_list(list) do
    tuple_value = get(list, tuple_key)

    if tuple_value != nil do
      extracted_value = Map.get(tuple_value, map_key, nil)

      if extracted_value != nil do
        List.keystore(list, new_tuple_key, 0, {new_tuple_key, extracted_value})
      else
        list
      end
    else
      list
    end
  end

  defimpl Jason.Encoder, for: Tuple do
    def encode(tuple, _opts) when is_tuple(tuple) do
      tuple
      |> Tuple.to_list()
      |> Jason.encode!()
    end
  end

  defimpl Jason.Encoder, for: Function do
    def encode(fun, _opts) when is_function(fun) do
      fun
      |> inspect
      |> Jason.encode!()
    end
  end
end
