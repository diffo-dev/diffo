defmodule Diffo.Access.SharedShelfCharacteristic do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference

  SharedShelfCharacteristic - Calculation to return a shared Shelf Characteristic
  """
  use Ash.Resource.Calculation

  @impl true
  # A callback to tell Ash what keys must be loaded/selected when running this calculation
  # you can include related data here, but be sure to include the attributes you need from said related data
  # i.e `posts: [:title, :body]`.
  def load(_query, _opts, _context) do
    [
      reverse_relationships: [
        :alias,
        :type,
        source: [reverse_relationships: [:alias, :type, source: [:characteristics]]]
      ]
    ]
  end

  @impl true
  def calculate(records, _opts, _arguments) do
    Enum.map(records, fn record ->
      characteristics =
        Map.get(record, :reverse_relationships)
        |> Enum.reduce([], fn reverse_relationship, acc ->
          if reverse_relationship.type == :assignedTo do
            IO.inspect(reverse_relationship.source, label: :reverse_relationship_source)
            [hd(reverse_relationship.characteristics) | acc]
          else
            acc
          end
        end)

      if characteristics == [] do
        []
      else
        hd(characteristics)
      end
    end)
  end

  # You can implement this callback to make this calculation possible in the data layer
  # *and* in elixir. Ash expressions are already executable in Elixir or in the data layer, but this gives you fine grain control over how it is done
  # See the expressions guide for more.
  # @impl true
  # def expression(opts, context) do
  #   expr(your_expression_here)
  # end
end
