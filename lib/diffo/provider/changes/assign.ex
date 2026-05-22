# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Provider.Changes.Assign do
  @moduledoc """
  After-action change for the standard `:assign_*` pattern.

  Performs an assignment for the named pool via `Assigner.assign/3`, then
  reloads the result via the resource's primary `:read` action.

  ## Usage

      update :assign_port do
        argument :assignment, :struct, constraints: [instance_of: Assignment]
        change {Diffo.Provider.Changes.Assign, pool: :ports}
      end

  ## Options

  - `:pool` (required) — the pool name (atom) declared via `pools do` on the
    consuming instance resource.
  """
  use Ash.Resource.Change

  require Ash.Query

  alias Diffo.Provider.Assigner

  @impl true
  def init(opts) do
    case Keyword.fetch(opts, :pool) do
      {:ok, pool} when is_atom(pool) and not is_nil(pool) ->
        {:ok, opts}

      _ ->
        {:error, "Diffo.Provider.Changes.Assign requires a :pool atom option"}
    end
  end

  @impl true
  def change(changeset, opts, _context) do
    pool = Keyword.fetch!(opts, :pool)

    Ash.Changeset.after_action(changeset, fn changeset, result ->
      with {:ok, result} <- Assigner.assign(result, changeset, pool) do
        id = result.id

        changeset.resource
        |> Ash.Query.for_read(:read)
        |> Ash.Query.filter(id == ^id)
        |> Ash.read_one()
      end
    end)
  end
end
