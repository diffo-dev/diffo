defmodule Diffo.Provider.IncrementPatchVersion do
  use Ash.Resource.ManualUpdate

  def update(changeset, _, _) do
    {_current, record} =
      changeset.data
      |>  Map.get_and_update(:patch_version, fn value -> {value, value + 1} end)
    {:ok, Diffo.Provider.Version.recalculate(record)}
  end
end
