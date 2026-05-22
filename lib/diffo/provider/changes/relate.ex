# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Changes.Relate do
  @moduledoc """
  After-action change for the standard `:relate` pattern.

  Creates relationships from the `:relationships` argument on the changeset via
  `Relationship.relate_instance/2`, then reloads the result via the resource's
  primary `:read` action.

  ## Usage

      update :relate do
        argument :relationships, {:array, :struct}
        change Diffo.Provider.Changes.Relate
      end
  """
  use Ash.Resource.Change

  require Ash.Query

  alias Diffo.Provider.Instance.Relationship

  @impl true
  def change(changeset, _opts, _context) do
    Ash.Changeset.after_action(changeset, fn changeset, result ->
      with {:ok, result} <- Relationship.relate_instance(result, changeset) do
        id = result.id

        changeset.resource
        |> Ash.Query.for_read(:read)
        |> Ash.Query.filter(id == ^id)
        |> Ash.read_one()
      end
    end)
  end
end
