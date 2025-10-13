defmodule Diffo.Changes.DetailRelationship do
  @moduledoc """
  Diffo - TMF Service and Resource Management with a difference


  DetailRelationship - Ash Resource Change for populating relationship detail

  """
  use Ash.Resource.Change

  def change(changeset, _opts, _context) do
    target_id = Ash.Changeset.get_argument_or_attribute(changeset, :target_id)

    case Diffo.Provider.get_instance_by_id(target_id) do
      {:ok, target} ->
        Ash.Changeset.force_change_attributes(changeset,
          target_href: Map.get(target, :href),
          target_type: Map.get(target, :type)
        )

      {:error, _error} ->
        changeset
    end
  end

  # this can be used as follows, where it will set the target_href and target_type from that target instance
  # change Diffo.Changes.DetailRelationship
end
