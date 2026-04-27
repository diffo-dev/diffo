# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Reference do
  @moduledoc false
  defstruct id: nil, href: nil

  @doc false
  def reference(instance) when is_map(instance) do
    %Diffo.Provider.Reference{id: instance.id, href: instance.href}
  end

  def reference(instance) when is_nil(instance), do: nil

  @doc false
  def reference(instance, attribute) when is_map(instance) and is_atom(attribute) do
    href = Map.get(instance, attribute)
    %Diffo.Provider.Reference{id: Diffo.Uuid.trailing_uuid4(href), href: href}
  end

  defimpl Jason.Encoder do
    def encode(reference, _opts) do
      case reference.href do
        nil ->
          Jason.encode!(%{id: reference.id})

        _ ->
          Jason.OrderedObject.new(id: reference.id, href: reference.href)
          |> Jason.encode!()
      end
    end
  end

  defimpl String.Chars do
    def to_string(struct) do
      inspect(struct)
    end
  end

  use Outstand

  defoutstanding expected :: Diffo.Provider.Reference, actual :: Any do
    expected_map = Map.take(expected, [:id, :href])

    case {expected, actual} do
      {%name{}, %_{}} ->
        Outstanding.outstanding(expected_map, Map.from_struct(actual))
        |> Outstand.map_to_struct(name)

      {%name{}, _} ->
        expected_map
        |> Outstand.map_to_struct(name)
    end
  end
end
