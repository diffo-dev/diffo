# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Changes.Define do
  @moduledoc """
  After-action change for the standard `:define` pattern.

  Applies `characteristic_value_updates` to the instance's declared typed and
  dynamic characteristics (`Characteristic.update_all/3`) and to its declared
  pools (`Pool.update_pools/3`), then reloads the result via the resource's
  primary `:read` action.

  ## Usage

      update :define do
        argument :characteristic_value_updates, {:array, :term}
        change Diffo.Provider.Changes.Define
      end

  This replaces the hand-written `after_action` block that threads
  `characteristics()`, `pools()`, `Characteristic.update_all/3` and
  `Pool.update_pools/3` together on every consumer.
  """
  use Ash.Resource.Change

  require Ash.Query

  alias Diffo.Provider.Extension.Characteristic
  alias Diffo.Provider.Extension.Pool

  @impl true
  def change(changeset, _opts, _context) do
    Ash.Changeset.after_action(changeset, fn changeset, result ->
      module = changeset.resource

      with {:ok, result} <- Ash.load(result, [:characteristics]),
           {:ok, result} <- Characteristic.update_all(result, changeset, module.characteristics()),
           {:ok, result} <- Pool.update_pools(result, changeset, module.pools()) do
        id = result.id

        module
        |> Ash.Query.for_read(:read)
        |> Ash.Query.filter(id == ^id)
        |> Ash.read_one()
      end
    end)
  end
end
