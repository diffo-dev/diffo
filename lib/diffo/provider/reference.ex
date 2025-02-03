defmodule Diffo.Provider.Reference do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference
  Copyright Matt Beanland beanland@live.com.au

  Reference - utilities relating to reference
  """

  @doc """
  Creates a reference ordered object from an instance
    ## Examples
    iex> instance = %{id: "8bcfbf9a-34a5-427a-8eae-5c3812466432", href: "serviceInventoryManagement/v4/service/siteConnection/8bcfbf9a-34a5-427a-8eae-5c3812466432"}
    iex> Diffo.Provider.Reference.reference(instance)
    %Jason.OrderedObject{values: [id: "8bcfbf9a-34a5-427a-8eae-5c3812466432", href: "serviceInventoryManagement/v4/service/siteConnection/8bcfbf9a-34a5-427a-8eae-5c3812466432"]}

  """
    def reference(instance) do
      Jason.OrderedObject.new([id: instance.id, href: instance.href])
    end
end
