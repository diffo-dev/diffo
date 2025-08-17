defmodule Diffo.Provider.Reference do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference
  Copyright Matt Beanland beanland@live.com.au

  Reference - utilities relating to reference
  """

  defstruct id: nil, href: nil

  @doc """
  Creates a reference struct from an instance with id and href
    ## Examples
    iex> instance = %{id: "8bcfbf9a-34a5-427a-8eae-5c3812466432", href: "serviceInventoryManagement/v4/service/siteConnection/8bcfbf9a-34a5-427a-8eae-5c3812466432"}
    iex> Diffo.Provider.Reference.reference(instance)
    %Diffo.Provider.Reference{id: "8bcfbf9a-34a5-427a-8eae-5c3812466432", href: "serviceInventoryManagement/v4/service/siteConnection/8bcfbf9a-34a5-427a-8eae-5c3812466432"}
  """
  def reference(instance) when is_map(instance) do
    %Diffo.Provider.Reference{id: instance.id, href: instance.href}
  end

  def reference(instance) when is_nil(instance), do: nil

  @doc """
  Creates a reference struct from an instance attribute containing a href
    ## Examples
    iex> instance = %{target_href: "serviceInventoryManagement/v4/service/siteConnection/8bcfbf9a-34a5-427a-8eae-5c3812466432"}
    iex> Diffo.Provider.Reference.reference(instance, :target_href)
    %Diffo.Provider.Reference{id: "8bcfbf9a-34a5-427a-8eae-5c3812466432", href: "serviceInventoryManagement/v4/service/siteConnection/8bcfbf9a-34a5-427a-8eae-5c3812466432"}
  """
  def reference(instance, attribute) when is_map(instance) and is_atom(attribute) do
    href = Map.get(instance, attribute)
    %Diffo.Provider.Reference{id: Diffo.Uuid.trailing_uuid4(href), href: href}
  end

  defimpl Jason.Encoder do
    def encode(reference, _opts) do
      Jason.OrderedObject.new(id: reference.id, href: reference.href)
      |> Jason.encode!()
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
