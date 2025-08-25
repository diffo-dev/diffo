defmodule Diffo.Access.PortsValue do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  PortsValue - AshTyped Struct for Ports Characteristic Value
  """
  use Ash.TypedStruct, extensions: [AshJason.TypedStruct]

  alias Diffo.Access.Assignment

  jason do
    pick [:first, :last, :free, :type, :algorithm]
    customize fn result, record ->
      result
      |> Diffo.Util.set(:assignments, assignments(record))
    end
  end

  typed_struct do
    field :first, :integer,
      description: "the first port number",
      default: 0,
      constraints: [min: 0]
    field :last, :integer,
      description: "the last port number",
      default: 0,
      constraints: [min: 0]
    field :free, :integer,
      description: "the number of free ports",
      default: 0,
      constraints: [min: 0]
    field :type, :string, description: "the type of the port"
    field :algorithm, :atom,
      description: "the assignment algorithm",
      default: :lowest,
      constraints: [one_of: [:lowest, :highest, :random]]
  end

  defimpl String.Chars do
    def to_string(struct) do
      inspect(struct)
    end
  end

  def assignments(instance) when is_struct(instance) do
    Enum.reduce(instance.forward_relationships, [],
      fn %{type: type, characteristics: characteristics, target_id: target_id}, acc ->
        case type do
          :assigned_to ->
            characteristic = Enum.find(characteristics, fn %{name: n} -> n == :port end)
            if characteristic do
              assignment = struct(Assignment, %{id: characteristic.value, instance_id: target_id})
              [assignment | acc]
            else
              acc
            end
          _ ->
            acc
        end
      end)
    |> Enum.sort(Assignment)
    |> IO.inspect(label: :assignments)
  end

  def next(instance) when is_struct(instance) do
    ports_characteristic = Enum.find(instance.characteristics, fn %{name: n} -> n == :ports end)
    algorithm = Map.get(ports_characteristic.value, :algorithm)
    case free = free(instance, ports_characteristic.value) do
      [] ->
        {:error, "all ports are assigned"}
      _ ->
      case algorithm do
        :lowest ->
          {:ok, hd(free)}
        :random ->
          {:ok, Enum.random(free)}
        :highest ->
          {:ok, List.last(free)}
      end
    end
    |> IO.inspect(label: :next)
  end

  def assignable?(instance, value) when is_struct(instance) and is_integer(value) do
    ports_characteristic = Enum.find(instance.characteristics, fn %{name: n} -> n == :ports end)
    free = free(instance, ports_characteristic.value)
    value in free
    |> IO.inspect(label: :assignable?)
  end

  defp free(instance, ports_value) when is_struct(instance) and is_struct(ports_value, __MODULE__) do
    assignments = assignments(instance)
    assigned = Enum.into(assignments, &Map.get(&1, :id))
    min = Map.get(ports_value, :min)
    max = Map.get(ports_value, :max)
    Enum.to_list(min..max) -- assigned
    |> IO.inspect(label: :free)
  end
end
