defmodule Diffo.Provider.Reference do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference
  Copyright Matt Beanland beanland@live.com.au

  Reference - utilities relating to reference
  """

  @doc """
  Creates a reference ordered object from an instance with id and href
    ## Examples
    iex> instance = %{id: "8bcfbf9a-34a5-427a-8eae-5c3812466432", href: "serviceInventoryManagement/v4/service/siteConnection/8bcfbf9a-34a5-427a-8eae-5c3812466432"}
    iex> Diffo.Provider.Reference.reference(instance)
    %Jason.OrderedObject{values: [id: "8bcfbf9a-34a5-427a-8eae-5c3812466432", href: "serviceInventoryManagement/v4/service/siteConnection/8bcfbf9a-34a5-427a-8eae-5c3812466432"]}
  """
  def reference(instance) when is_map(instance) do
    Jason.OrderedObject.new([id: instance.id, href: instance.href])
  end

  @doc """
  Creates a reference ordered object from an instance attribute containing a href
    ## Examples
    iex> instance = %{target_href: "serviceInventoryManagement/v4/service/siteConnection/8bcfbf9a-34a5-427a-8eae-5c3812466432"}
    iex> Diffo.Provider.Reference.reference(instance, :target_href)
    %Jason.OrderedObject{values: [id: "8bcfbf9a-34a5-427a-8eae-5c3812466432", href: "serviceInventoryManagement/v4/service/siteConnection/8bcfbf9a-34a5-427a-8eae-5c3812466432"]}
  """
  def reference(instance, attribute) when is_map(instance) and is_atom(attribute) do
    href = Map.get(instance, attribute)
    Jason.OrderedObject.new([id: Diffo.Uuid.trailing_uuid4(href), href: href])
  end
end
