defmodule Diffo.Provider.IncrementMinorVersion do
  use Ash.Resource.ManualUpdate

  def update(changeset, _, _) do
    {_current, record} =
      changeset.data
      |> Map.put(:patch_version, 0)
      |> Map.get_and_update(:minor_version, fn value -> {value, value + 1} end)

    {:ok, Diffo.Provider.Version.recalculate(record)}
  end
end
