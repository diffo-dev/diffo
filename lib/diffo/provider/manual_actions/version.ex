defmodule Diffo.Provider.Version do
  def recalculate(resource) when is_map(resource) do
    major_version = Map.get(resource, :major_version)
    minor_version = Map.get(resource, :minor_version)
    patch_version = Map.get(resource, :patch_version)
    version = "v#{major_version}.#{minor_version}.#{patch_version}"
    Map.put(resource, :version, version)
  end
end
