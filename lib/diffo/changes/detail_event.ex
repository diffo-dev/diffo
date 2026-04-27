# SPDX-FileCopyrightText: 2025 diffo contributors <https://github.com/diffo-dev/diffo/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule Diffo.Changes.DetailEvent do
  @moduledoc false
  use Ash.Resource.Change

  def change(changeset, _opts, _context) do
    instance_id = Ash.Changeset.get_data(changeset, :id)

    case Diffo.Provider.get_instance_by_id(instance_id, load: [:event]) do
      {:ok, instance} ->
        event =
          Ash.Changeset.get_argument(changeset, :event)
          |> Map.put(:firing_type, instance.type)
          |> Map.put(:firing_snapshot, Jason.encode!(instance))

        earlier_event = Map.get(instance, :event)

        event =
          if earlier_event do
            Map.put(event, :earlier_id, earlier_event.id)
          else
            event
          end

        Ash.Changeset.force_set_argument(changeset, :event, event)

      {:error, _error} ->
        changeset
    end
  end

  # this can be used as follows, where it will set the Event's firing_type, firing_snapshot and earlier_id from the refreshed Instance
  # change Diffo.Changes.DetailEvent
end
